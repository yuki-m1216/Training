import * as path from 'path';
import * as agentcoreAlpha from '@aws-cdk/aws-bedrock-agentcore-alpha';
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
// V4: エンジン単位の mode。V4a は LOG_ONLY(評価とトレースのみ、拒否しない)→ V4b で ENFORCE に変える(公式の typical lifecycle)。
// alpha の PolicyEngineMode は deprecated な alpha Gateway モジュールに属し、安定版に同等品が無い(L1 の mode は string)ため、
// CFN の列挙値(GatewayPolicyEngineMode)を文字列リテラル型で持つ
const POLICY_ENGINE_MODE: 'LOG_ONLY' | 'ENFORCE' = 'ENFORCE';

/**
 * Gateway スタック(V3)。Runtime 上のエージェントが透過する同一 Bearer を Gateway の JWT オーソライザで検証し、
 * Lambda ターゲット VerifyTarget___echo_profile を実行する(計画_追加要件 §3-4)。V4 で PolicyEngine(Cedar)を紐付ける。
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
    const verifyTarget = this.gateway.addLambdaTarget('VerifyTarget', {
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

    // ---------------------------------------------------------------- Policy(V4。Cedar)
    // Policy だけ alpha に残る。安定版 Gateway L2 に policyEngineConfiguration が無いため、
    // alpha README「Using Policy with Stable Gateway」の L1 エスケープハッチ + role grant で紐付ける(仮決め #10)
    const policyEngine = new agentcoreAlpha.PolicyEngine(this, 'PolicyEngine', {
      policyEngineName: 'authchain_engine',
      description: 'Cedar policies for authchain-gateway (V4)',
    });
    // V4 壊す実験(既定は無効): -c break=noGetPolicyEngine → Gateway ロールから GetPolicyEngine を外す /
    //   -c break=noP1 → P1 を削除する。フラグ無しで deploy すれば元に戻る
    const breakExperiment: string | undefined = this.node.tryGetContext('break');
    const cfnGateway = this.gateway.node.defaultChild as agentcore.CfnGateway;
    cfnGateway.policyEngineConfiguration = {
      arn: policyEngine.policyEngineArn,
      mode: POLICY_ENGINE_MODE,
    };
    // 欠けると InternalServerException で全拒否(公式 policy-permissions)。alpha の grantEvaluateForGateway は alpha の IGateway しか受けない。
    // UpdateGateway(紐付け)の時点で、AgentCore が Gateway ロールを引き受けて(セッション名 GenesisPolicyEngineCheck)
    // GetPolicyEngine と AuthorizeAction を事前検査する(V4a-1 実測)。README どおり DefaultPolicy に入れると Gateway の ARN 参照で
    // 「Gateway 更新 → 権限付与」の順になり失敗するため、Gateway の ARN を参照しない別ポリシーにして Gateway をその後に更新する。
    // AuthorizeAction 系の gateway 側の ARN は名前の前方一致で書く(alpha の grantEvaluateForGateway と同じ。Gateway ID は "<名前>-<ランダム>")
    const engineAccess = new iam.Policy(this, 'GatewayPolicyEngineAccess', {
      roles: [gatewayRole],
      statements: [
        ...(breakExperiment === 'noGetPolicyEngine' ? [] : [new iam.PolicyStatement({
          actions: ['bedrock-agentcore:GetPolicyEngine'],
          resources: [policyEngine.policyEngineArn],
        })]),
        new iam.PolicyStatement({
          actions: ['bedrock-agentcore:AuthorizeAction', 'bedrock-agentcore:PartiallyAuthorizeActions'],
          resources: [
            policyEngine.policyEngineArn,
            this.formatArn({ service: 'bedrock-agentcore', resource: 'gateway', resourceName: `${GATEWAY_NAME}-*` }),
          ],
        }),
      ],
    });
    cfnGateway.node.addDependency(engineAccess);

    // JWT クレームは OAuthUser の tag(カスタム属性は不可)。alpha の PolicyStatement ビルダーは principal.x を生成し tag と矛盾するため
    // raw Cedar で書く(仮決め #17)。特定アクションを書くときは resource に具体的な Gateway ARN が必須(公式 policy-scope)
    const echoAction = 'AgentCore::Action::"VerifyTarget___echo_profile"';
    const gatewayResource = `AgentCore::Gateway::"${this.gateway.gatewayArn}"`;
    // P1: TESTCO のユーザーだけ echo_profile を呼べる(要件固有: 正規化した company_code で認可)
    const p1 = breakExperiment === 'noP1' ? undefined : policyEngine.addPolicy('P1PermitTestco', {
      policyName: 'p1_permit_testco',
      description: 'P1: only TESTCO users may call echo_profile',
      definition: `permit(
  principal is AgentCore::OAuthUser,
  action == ${echoAction},
  resource == ${gatewayResource}
) when {
  principal.hasTag("company_code") && principal.getTag("company_code") == "TESTCO"
};`,
    });
    // P2: 管理部(ADMIN1)は入力 note に "delete" を含む呼び出しを禁止(context.input と forbid 優先の実証)。note は任意項目なので has で確認
    const p2 = policyEngine.addPolicy('P2ForbidAdmin1Delete', {
      policyName: 'p2_forbid_admin1_delete',
      description: 'P2: ADMIN1 may not call echo_profile with note containing "delete"',
      definition: `forbid(
  principal is AgentCore::OAuthUser,
  action == ${echoAction},
  resource == ${gatewayResource}
) when {
  principal.hasTag("department_code") && principal.getTag("department_code") == "ADMIN1" &&
  context.input has note && context.input.note like "*delete*"
};`,
    });
    // P3(実験): 配列クレーム agents の tag 表現を確かめる探り。公式に配列 tag の記載が無いため like で当てる(仮決め #17)。
    // V4a-3 実測: tag は空白なしの JSON 配列文字列(["admin-only","inspect-headers"])。部分一致の誤ヒット(inspect-headers-v2 等)を
    // 避けるため、引用符ごと一致させる形にしている(当初は like "*inspect-headers*")。
    // ポリシー単位の LOG_ONLY(評価するが最終判定に数えない)にする: ACTIVE の permit だと V4b の「P1 削除でデフォルト拒否」が
    // P3 の許可で隠れるため。alpha L2 に項目が無いので L1 で設定(未確認事項 #5 の実測を兼ねる)
    const p3 = policyEngine.addPolicy('P3ProbeAgentsArray', {
      policyName: 'p3_probe_agents_array',
      description: 'P3 (probe, policy-level LOG_ONLY): how the agents array claim appears as a tag',
      definition: `permit(
  principal is AgentCore::OAuthUser,
  action == ${echoAction},
  resource == ${gatewayResource}
) when {
  principal.hasTag("agents") && principal.getTag("agents") like "*\\"inspect-headers\\"*"
};`,
    });
    (p3.node.defaultChild as agentcore.CfnPolicy).enforcementMode = 'LOG_ONLY';
    // P3a〜d(実験): P3 が当たった(V4a-2)ので、配列がどんな文字列の tag になるかを絞る。同じくポリシー単位 LOG_ONLY で、
    // どれが LogOnlyMatches に出るかで判定する(User-A は要素 1 つ、local-user-c は 2 つ)
    const arrayProbes: Array<[string, string, string]> = [
      ['P3aEquals', 'p3a_probe_equals', 'principal.getTag("agents") == "inspect-headers"'], // 要素 1 つなら素の文字列か
      ['P3bJson', 'p3b_probe_json', 'principal.getTag("agents") like "[*"'], // JSON 配列の文字列か
      ['P3cComma', 'p3c_probe_comma', 'principal.getTag("agents") like "*,*"'], // カンマ区切りか
      ['P3dSpace', 'p3d_probe_space', 'principal.getTag("agents") like "* *"'], // 空白区切りか
    ];
    const probes = arrayProbes.map(([id, name, cond]) => {
      const probe = policyEngine.addPolicy(id, {
        policyName: name,
        description: `P3 probe (policy-level LOG_ONLY): ${cond}`,
        definition: `permit(
  principal is AgentCore::OAuthUser,
  action == ${echoAction},
  resource == ${gatewayResource}
) when {
  principal.hasTag("agents") && ${cond}
};`,
      });
      (probe.node.defaultChild as agentcore.CfnPolicy).enforcementMode = 'LOG_ONLY';
      return probe;
    });
    // Cedar の検証(FAIL_ON_ANY_FINDINGS)はツールのスキーマを見るため、Gateway(定義中の ARN 参照で自動)に加えてターゲットの後に作る
    // (撤収後の再構築でツールより先にポリシーができて検証に落ちるのを防ぐ)
    for (const policy of [p1, p2, p3, ...probes]) {
      policy?.node.addDependency(verifyTarget);
    }

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
    new cdk.CfnOutput(this, 'PolicyEngineArn', { value: policyEngine.policyEngineArn });
  }
}
