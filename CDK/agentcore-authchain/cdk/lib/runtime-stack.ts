import * as fs from 'fs';
import * as path from 'path';
import * as cdk from 'aws-cdk-lib';
import * as agentcore from 'aws-cdk-lib/aws-bedrockagentcore';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';

/**
 * V5b でエージェント(Strands)が呼ぶモデル。jp の推論プロファイル = 東京・大阪のどちらかで推論する(データを国内に留める)。
 * 2026-10-25 ユーザー決定: Haiku 4.5(jp)。Haiku 5.5 は契約(agreement)を AVAILABLE にしてもこのアカウントでは
 * AccessDeniedException(アカウント単位の追加アクセスが必要なモデル)だったため切り替え(検証ログ_V5 V5b-2)
 */
const MODEL_INFERENCE_PROFILE_ID = 'jp.anthropic.claude-haiku-4-5-20251001-v1:0';
const MODEL_FOUNDATION_ID = 'anthropic.claude-haiku-4-5-20251001-v1:0';
/** jp プロファイルの送り先(2026-10-25 get-inference-profile で確認)。プロファイルを許可するときは送り先すべての foundation-model も要る */
const MODEL_DESTINATION_REGIONS = ['ap-northeast-1', 'ap-northeast-3'];

export interface AuthChainRuntimeStackProps extends cdk.StackProps {
  /** JWT オーソライザの discoveryUrl の元(AuthChainIdentityStack のプール) */
  readonly userPool: cognito.IUserPool;
  /** allowedClients(アクセストークンの client_id と照合) */
  readonly userPoolClient: cognito.IUserPoolClient;
  /**
   * このエージェントの識別子。Pre Token Gen が注入する agents クレームの要素、AgentEntitlement の sk(AGENT#<key>)、
   * Runtime の customClaims 一致値、エージェントの環境変数 AGENT_KEY を同じ値で結ぶ。
   * customClaims の一致値は [A-Za-z0-9_.-]+ のみ(コロン不可)
   */
  readonly agentKey: string;
  /**
   * Authorization ヘッダをエージェントへ転送するか(requestHeaderAllowlist)。
   * V2a = false(Runtime は検証だけして転送しない)→ V2b = true。差分をこの 1 点にする
   */
  readonly forwardAuthorizationHeader: boolean;
  /** Gateway の MCP URL(V3 で渡す。未指定ならエージェントの action=gateway はエラーを返す) */
  readonly gatewayUrl?: string;
}

/**
 * Runtime スタック(V2)。最小エージェント(inspect_headers)を直接コードデプロイ(仮決め #13)し、
 * Cognito JWT + customClaims(agents CONTAINS <agentKey>)で入口認証する(計画_追加要件 §3-3)。
 */
export class AuthChainRuntimeStack extends cdk.Stack {
  public readonly runtime: agentcore.Runtime;

  constructor(scope: Construct, id: string, props: AuthChainRuntimeStackProps) {
    super(scope, id, props);

    if (!/^[A-Za-z0-9_.-]+$/.test(props.agentKey)) {
      throw new Error(`agentKey "${props.agentKey}" は customClaims の一致値パターン [A-Za-z0-9_.-]+ に合いません`);
    }

    // 直接コードデプロイ: runtime-code/build.sh の出力(arm64 wheel + agent.py)を zip 化して CDK 管理 S3 へ。
    // build/ は生成物(gitignore)。実行漏れを synth 時点で分かるメッセージで止める(兄弟プロジェクトと同じ流儀)
    const runtimeCodePath = path.join(__dirname, '..', '..', 'runtime-code', 'build');
    if (!fs.existsSync(path.join(runtimeCodePath, 'agent.py'))) {
      throw new Error(
        'runtime-code/build/ が未生成です。先に CDK/agentcore-authchain/runtime-code/build.sh を実行してください',
      );
    }

    // MODEL_ID は実行ロールで InvokeModel* を許可する推論プロファイルと同じ値(V5b)
    const environmentVariables: Record<string, string> = {
      AGENT_KEY: props.agentKey,
      MODEL_ID: MODEL_INFERENCE_PROFILE_ID,
    };
    if (props.gatewayUrl) {
      environmentVariables.GATEWAY_URL = props.gatewayUrl;
    }

    this.runtime = new agentcore.Runtime(this, 'InspectHeadersRuntime', {
      // ^[a-zA-Z][a-zA-Z0-9_]{0,47}$(ハイフン不可)。agentKey(ハイフン可)とは別物
      runtimeName: 'authchain_inspect_headers',
      agentRuntimeArtifact: agentcore.AgentRuntimeArtifact.fromCodeAsset({
        path: runtimeCodePath,
        // build.sh の --python-version 3.13 とペア
        runtime: agentcore.AgentCoreRuntime.PYTHON_3_13,
        entrypoint: ['agent.py'],
      }),
      // JWT オーソライザ。usingCognito は discoveryUrl = https://cognito-idp.<region>.amazonaws.com/<poolId>/.well-known/openid-configuration、
      // allowedClients = [clientId] を描画する。Cognito のアクセストークンに aud は無いので allowedAudience は付けない。
      // customClaims: トークンの agents(配列)に agentKey が含まれることを Runtime 入口で要求(仮決め #15)。
      // 複数条件は AND。クレーム欠落・不一致時の HTTP コードは V2 で実測(計画 §6-2)
      authorizerConfiguration: agentcore.RuntimeAuthorizerConfiguration.usingCognito(
        props.userPool,
        [props.userPoolClient],
        undefined,
        undefined,
        [agentcore.RuntimeCustomClaim.withStringArrayValue('agents', [props.agentKey])],
      ),
      // 既定は転送なし。Authorization は customJWTAuthorizer 設定時のみ allowlist に入れられる(仮決め #16)
      requestHeaderConfiguration: props.forwardAuthorizationHeader ? { allowlistedHeaders: ['Authorization'] } : undefined,
      environmentVariables,
      // 仮決め #8: PUBLIC(既定)
    });

    // V5b: モデル呼び出しの権限。公式(inference-profiles-prereq)の「プロファイル経由でのみ呼べる」形:
    // プロファイルの ARN と、送り先リージョンの foundation-model を bedrock:InferenceProfileArn 条件付きで許可する。
    // InvokeModel* = InvokeModel と InvokeModelWithResponseStream(Converse／ConverseStream もこの 2 つで認可される)
    const inferenceProfileArn = cdk.Stack.of(this).formatArn({
      service: 'bedrock',
      resource: 'inference-profile',
      resourceName: MODEL_INFERENCE_PROFILE_ID,
    });
    this.runtime.role.addToPrincipalPolicy(
      new iam.PolicyStatement({
        sid: 'InvokeViaInferenceProfile',
        actions: ['bedrock:InvokeModel*'],
        resources: [inferenceProfileArn],
      }),
    );
    this.runtime.role.addToPrincipalPolicy(
      new iam.PolicyStatement({
        sid: 'InvokeFoundationModelOnlyViaProfile',
        actions: ['bedrock:InvokeModel*'],
        resources: MODEL_DESTINATION_REGIONS.map(
          (region) => `arn:${cdk.Aws.PARTITION}:bedrock:${region}::foundation-model/${MODEL_FOUNDATION_ID}`,
        ),
        conditions: { StringLike: { 'bedrock:InferenceProfileArn': inferenceProfileArn } },
      }),
    );

    new cdk.CfnOutput(this, 'RuntimeArn', { value: this.runtime.agentRuntimeArn });
    new cdk.CfnOutput(this, 'RuntimeId', { value: this.runtime.agentRuntimeId });
    new cdk.CfnOutput(this, 'AgentKey', { value: props.agentKey });
    new cdk.CfnOutput(this, 'ForwardAuthorizationHeader', { value: String(props.forwardAuthorizationHeader) });
  }
}
