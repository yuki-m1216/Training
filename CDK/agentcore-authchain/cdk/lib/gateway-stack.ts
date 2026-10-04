import * as path from 'path';
import * as cdk from 'aws-cdk-lib';
import * as agentcore from 'aws-cdk-lib/aws-bedrockagentcore';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as logs from 'aws-cdk-lib/aws-logs';
import { Construct } from 'constructs';

export interface AuthChainGatewayStackProps extends cdk.StackProps {
  /** JWT オーソライザの discoveryUrl の元(AuthChainIdentityStack のプール。Runtime と同じ信頼元) */
  readonly userPool: cognito.IUserPool;
  /** allowedClients。Runtime と同じクライアント = エージェントが透過する同一 Bearer をそのまま受ける(仮決め #16) */
  readonly userPoolClient: cognito.IUserPoolClient;
}

// ^([0-9a-zA-Z][-]?){1,100}$。ロールの trust(aws:SourceArn)でも使うため定数にする
const GATEWAY_NAME = 'authchain-gateway';

/**
 * Gateway スタック(V3)。Runtime 上のエージェントが透過する同一 Bearer を Gateway の JWT オーソライザで検証し、
 * Lambda ターゲット VerifyTarget___echo_profile を実行する(計画_追加要件 §3-4)。Policy は V4 で紐付ける(V3 は未接続)。
 */
export class AuthChainGatewayStack extends cdk.Stack {
  public readonly gateway: agentcore.Gateway;

  constructor(scope: Construct, id: string, props: AuthChainGatewayStackProps) {
    super(scope, id, props);

    // ---------------------------------------------------------------- ツール実体(観測用 Lambda)
    const echoLogs = new logs.LogGroup(this, 'EchoProfileLogs', {
      retention: logs.RetentionDays.ONE_WEEK,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });
    const echoFn = new lambda.Function(this, 'EchoProfileFn', {
      runtime: lambda.Runtime.PYTHON_3_13,
      handler: 'handler.lambda_handler',
      code: lambda.Code.fromAsset(path.join(__dirname, '../../lambda/echo_profile')),
      timeout: cdk.Duration.seconds(5),
      logGroup: echoLogs,
    });

    // ---------------------------------------------------------------- Gateway の実行ロール(自前)
    // L2 既定のロールは「条件なしの Allow」+「SourceAccount/SourceArn 条件付きの Allow」の 2 文になり、
    // Allow は OR 評価のため条件(confused deputy 対策)が実質無効になる(2026-10-04 合成結果で確認)。
    // 条件付きの 1 文だけの trust にしたロールを渡す(公式: サービスロールの trust に aws:SourceAccount / aws:SourceArn)
    const gatewayRole = new iam.Role(this, 'GatewayRole', {
      assumedBy: new iam.ServicePrincipal('bedrock-agentcore.amazonaws.com').withConditions({
        StringEquals: { 'aws:SourceAccount': this.account },
        // Gateway ID は "<gatewayName>-<ランダム>" なので名前の前方一致で絞る(L2 既定と同じパターン)
        ArnLike: {
          'aws:SourceArn': this.formatArn({ service: 'bedrock-agentcore', resource: 'gateway', resourceName: `${GATEWAY_NAME}*` }),
        },
      }),
      description: `Service role for Bedrock AgentCore Gateway ${GATEWAY_NAME} (conditioned trust only)`,
    });

    // ---------------------------------------------------------------- Gateway
    this.gateway = new agentcore.Gateway(this, 'Gateway', {
      gatewayName: GATEWAY_NAME,
      // usingCognito は discoveryUrl = <iss>/.well-known/openid-configuration、allowedClients = [clientId] を描画する。
      // customClaims は付けない: 粗い検証(agents CONTAINS)は Runtime 入口、細かい認可は V4 の Cedar(二層を見せる。計画 §3-4)
      authorizerConfiguration: agentcore.GatewayAuthorizer.usingCognito({
        userPool: props.userPool,
        allowedClients: [props.userPoolClient],
      }),
      // L2 既定(SEMANTIC 検索 + 2025-03-26)を使わず明示する。検索を有効にすると tools/list に
      // x_amz_bedrock_agentcore_search が混ざり、V4 の「tools/list は呼べるツールだけ」の観測が濁るため付けない。
      // 版はクライアント(mcp 1.29.1: 2025-11-25 まで対応)と交渉できる範囲で L2 が列挙する 2 版
      protocolConfiguration: new agentcore.McpProtocolConfiguration({
        supportedVersions: [agentcore.MCPProtocolVersion.MCP_2025_06_18, agentcore.MCPProtocolVersion.MCP_2025_03_26],
      }),
      // [簡略化] 壊す実験で拒否文言を見るため詳細なエラーを返す。本番は既定(サニタイズ)
      exceptionLevel: agentcore.GatewayExceptionLevel.DEBUG,
      role: gatewayRole,
    });

    // ツール名は "VerifyTarget___echo_profile"(仮決め #6)。L2 が gatewayRole に lambda:InvokeFunction を付与する
    this.gateway.addLambdaTarget('VerifyTarget', {
      gatewayTargetName: 'VerifyTarget',
      lambdaFunction: echoFn,
      toolSchema: agentcore.ToolSchema.fromInline([
        {
          name: 'echo_profile',
          description: 'Echoes what the gateway passed to the Lambda target (arguments and client context)',
          inputSchema: {
            type: agentcore.SchemaDefinitionType.OBJECT,
            properties: {
              // V4 の P2(context.input.note like "*delete*")で使う。任意項目(has で存在確認する)
              note: { type: agentcore.SchemaDefinitionType.STRING, description: 'Free text echoed back' },
            },
          },
        },
      ]),
    });

    // ---------------------------------------------------------------- Observability(vended logs + traces)
    // Gateway はログ配信先を自動作成しない(Runtime と違う)。traces も TRACES 配信を作らないと aws/spans に出ない(公式 observability-configure)。
    // Gateway L2 に設定項目が無いため、Runtime 用に公開されている配信ヘルパー(送信元 ARN を取る汎用関数)を Gateway ARN で使う。
    // ヘルパーは CloudWatch Logs と X-Ray のリソースポリシー(アカウント単位の枠を 1 つずつ消費、送信元 ARN の条件付き)も作る
    const gatewayLogs = new logs.LogGroup(this, 'GatewayAppLogs', {
      // コンソールで設定したときの既定名と同じ形
      logGroupName: `/aws/vendedlogs/bedrock-agentcore/gateway/APPLICATION_LOGS/${this.gateway.gatewayId}`,
      retention: logs.RetentionDays.ONE_WEEK,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });
    agentcore.configureLoggingDelivery(this, this.gateway.gatewayArn, [
      { logType: agentcore.LogType.APPLICATION_LOGS, destination: agentcore.LoggingDestination.cloudWatchLogs(gatewayLogs) },
    ]);
    agentcore.configureTracingDelivery(this, this.gateway.gatewayArn);

    // gatewayUrl が optional なのは import 用の型を共有しているため。新規作成で undefined なら synth 時点で止める(兄弟と同じ)
    if (!this.gateway.gatewayUrl) {
      throw new Error('gateway.gatewayUrl が未定義です。新規作成した Gateway では取得できるはずのため構成を確認してください');
    }
    new cdk.CfnOutput(this, 'GatewayUrl', { value: this.gateway.gatewayUrl });
    new cdk.CfnOutput(this, 'GatewayId', { value: this.gateway.gatewayId });
    new cdk.CfnOutput(this, 'GatewayArn', { value: this.gateway.gatewayArn });
    new cdk.CfnOutput(this, 'EchoFunctionName', { value: echoFn.functionName });
    new cdk.CfnOutput(this, 'GatewayLogGroupName', { value: gatewayLogs.logGroupName });
  }
}
