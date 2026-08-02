import * as path from 'path';
import * as cdk from 'aws-cdk-lib';
import * as agentcore from 'aws-cdk-lib/aws-bedrockagentcore';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import { Construct } from 'constructs';

export interface AgentPlatformStackProps extends cdk.StackProps {
  /** インバウンド認可の信頼元となる FoundationStack のユーザープール */
  readonly userPool: cognito.IUserPool;
  /** トークン発行を許可する M2M クライアント(allowedClients で照合される) */
  readonly userPoolClient: cognito.IUserPoolClient;
}

/**
 * エージェント基盤スタック(3スタック分割のうち「変化の速い」層)。
 * AgentCore Gateway とツール(Lambda ターゲット)を持つ。
 * ツール定義は今後頻繁に変わる想定のため、認証基盤(Foundation)とデプロイを分離している。
 */
export class AgentPlatformStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: AgentPlatformStackProps) {
    super(scope, id, props);

    // ツール用 Lambda(hello_world 相当)。
    // Gateway からの呼び出しでは event にツールの入力引数だけが入り、
    // ツール名は context.client_context.custom['bedrockAgentCoreToolName'] に
    // 「ターゲット名___ツール名」(アンダースコア3本)の prefix 付きで渡ってくる。
    // 将来ツールを増やしても対応できるよう、prefix を剥がして分岐する形にしておく
    const toolFunction = new lambda.Function(this, 'HelloToolFunction', {
      runtime: lambda.Runtime.PYTHON_3_13,
      handler: 'index.handler',
      code: lambda.Code.fromInline(`
def handler(event, context):
    # 'hello___hello_world' のような prefix 付きツール名を取得
    custom = getattr(context.client_context, 'custom', None) or {}
    prefixed = custom.get('bedrockAgentCoreToolName', '')
    # ターゲット名の名前空間 prefix を剥がす(区切りはアンダースコア3本)
    tool_name = prefixed.split('___')[-1]

    if tool_name == 'hello_world':
        name = event.get('name', 'world')
        return {'greeting': f'Hello, {name}!', 'received_tool_name': prefixed}

    raise ValueError(f'Unknown tool: {prefixed}')
`),
    });

    const gateway = new agentcore.Gateway(this, 'Gateway', {
      gatewayName: 'training-gateway',
      // デフォルト(Cognito自動生成)には任せず、Foundation の認証基盤を信頼元にする。
      // usingCognito は内部で usingCustomJwt に変換される:
      //   discoveryUrl = プールの iss + /.well-known/openid-configuration
      //   allowedClients = [クライアントID] (Cognitoアクセストークンに aud が無いため client_id で照合)
      authorizerConfiguration: agentcore.GatewayAuthorizer.usingCognito({
        userPool: props.userPool,
        allowedClients: [props.userPoolClient],
      }),
      // 既定より詳細なエラーを返す設定。後の壊し実験で既定との差を観察するため
      exceptionLevel: agentcore.GatewayExceptionLevel.DEBUG,
    });

    // MCP 上のツール名は「hello___hello_world」になる(gatewayTargetName が prefix になる)
    gateway.addLambdaTarget('HelloTarget', {
      gatewayTargetName: 'hello',
      lambdaFunction: toolFunction,
      toolSchema: agentcore.ToolSchema.fromInline([
        {
          name: 'hello_world',
          description: 'Returns a friendly greeting for the given name',
          inputSchema: {
            type: agentcore.SchemaDefinitionType.OBJECT,
            properties: {
              name: {
                type: agentcore.SchemaDefinitionType.STRING,
                description: 'Name of the person to greet',
              },
            },
            required: ['name'],
          },
        },
      ]),
    });

    // MCP クライアントの接続先。gatewayUrl の型が optional なのは
    // 既存 Gateway の import 構文と型を共有しているため。新規作成では必ず値が入るが、
    // 万一 undefined の場合に空文字で握りつぶすと問題の発見が deploy 後まで遅れるため、
    // synth 時点で失敗させる(フェイルファスト)
    if (!gateway.gatewayUrl) {
      throw new Error(
        'gateway.gatewayUrl が未定義です。新規作成した Gateway では取得できるはずのため構成を確認してください',
      );
    }
    new cdk.CfnOutput(this, 'GatewayUrl', { value: gateway.gatewayUrl });

    // ---- AgentCore Runtime (strands エージェント本体) ----

    // 直接コードデプロイ: Docker/ECR を使わず、build.sh の出力(arm64 依存 + agent.py)を
    // zip 化して CDK 管理の S3 バケットへアップロードする方式。
    // build/ は生成物のため、synth 前に runtime-code/build.sh の実行が前提
    const artifact = agentcore.AgentRuntimeArtifact.fromCodeAsset({
      path: path.join(__dirname, '..', 'runtime-code', 'build'),
      // AWS がマネージドで用意する実行環境のバージョン。build.sh の
      // --python-version 3.13 とペアで、ズレると import エラーになる
      runtime: agentcore.AgentCoreRuntime.PYTHON_3_13,
      // zip ルートの agent.py を起動する(Dockerfile の CMD 相当)
      entrypoint: ['agent.py'],
    });

    const runtime = new agentcore.Runtime(this, 'AgentRuntime', {
      // Runtime 名はハイフン不可(^[a-zA-Z][a-zA-Z0-9_]{0,47}$)のためスネークケース
      runtimeName: 'training_agent',
      agentRuntimeArtifact: artifact,
      // Gateway と同じ Foundation の Cognito を信頼元にする。
      // Gateway の usingCognito({...}) と違い Runtime 側は位置引数 + クライアント配列。
      // JWT を設定すると SigV4(IAM) では呼べなくなる(併用不可)点に注意
      authorizerConfiguration: agentcore.RuntimeAuthorizerConfiguration.usingCognito(
        props.userPool,
        [props.userPoolClient],
      ),
    });

    // 自動生成される実行ロールには ECR/CloudWatch 系しか無いため、strands が
    // Bedrock のモデルを呼ぶための権限を明示付与する。宛先は jp. 推論プロファイルと、
    // そこからルーティングされ得る国内リージョンの Haiku 4.5 基盤モデルに限定
    runtime.role.addToPrincipalPolicy(new iam.PolicyStatement({
      actions: ['bedrock:InvokeModel', 'bedrock:InvokeModelWithResponseStream'],
      resources: [
        `arn:aws:bedrock:${this.region}:${this.account}:inference-profile/jp.anthropic.claude-haiku-4-5-*`,
        // 基盤モデル ARN はアカウント ID を持たず、ルーティング先リージョンが
        // プロファイル側の都合で変わり得るためリージョンはワイルドカード
        'arn:aws:bedrock:*::foundation-model/anthropic.claude-haiku-4-5-*',
      ],
    }));

    // invoke 検証(Bearer トークンで直接 HTTPS)の URL 組み立てに ARN が必要になる
    new cdk.CfnOutput(this, 'RuntimeArn', { value: runtime.agentRuntimeArn });
  }
}
