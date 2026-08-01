import * as cdk from 'aws-cdk-lib';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import { Construct } from 'constructs';

/**
 * 認証基盤スタック(3スタック分割のうち「変化の遅い」層)。
 * AgentCore Gateway の M2M 認証に使う Cognito 一式を持つ。
 */
export class FoundationStack extends cdk.Stack {
  /** AgentPlatformStack が Gateway のインバウンド認可(JWT)設定で参照する */
  public readonly userPool: cognito.UserPool;
  /** AgentPlatformStack が許可クライアントIDとして参照する */
  public readonly userPoolClient: cognito.UserPoolClient;
  /** トークンエンドポイント URL の組み立てに使う */
  public readonly userPoolDomain: cognito.UserPoolDomain;

  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    this.userPool = new cognito.UserPool(this, 'AgentUserPool', {
      // M2M 専用プール。人間がサインアップする経路を構造的に閉じる
      selfSignUpEnabled: false,
      // 検証用のため明示的に DESTROY(L2 のデフォルトは RETAIN)。
      // 本番なら RETAIN + deletionProtection が定石
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // ドメインが無いと /oauth2/token エンドポイント自体がプロビジョニングされず、
    // client_credentials フローが成立しない(W1 のドメイン作成漏れの再発防止)
    this.userPoolDomain = this.userPool.addDomain('AuthDomain', {
      cognitoDomain: {
        // プレフィックスはリージョン内一意が必要 → グローバル一意なアカウントIDで担保
        domainPrefix: `agentcore-${this.account}`,
      },
    });

    // アクセストークンの scope クレームには '<identifier>/<scopeName>' = 'agentcore/read' として現れる
    const readScope = new cognito.ResourceServerScope({
      scopeName: 'read',
      scopeDescription: 'Read access to AgentCore Gateway tools',
    });
    const resourceServer = this.userPool.addResourceServer('AgentResourceServer', {
      identifier: 'agentcore',
      scopes: [readScope],
    });

    this.userPoolClient = this.userPool.addClient('M2MClient', {
      // client_credentials フローはシークレット必須
      generateSecret: true,
      oAuth: {
        // M2M 専用フロー。authorizationCode / implicit との同居は Cognito の制約上不可
        flows: { clientCredentials: true },
        // コンストラクト参照で渡すことで「リソースサーバー → クライアント」の
        // 作成順序が暗黙に保証される(手作業だと順序ミスで落ちるポイント)
        scopes: [cognito.OAuthScope.resourceServer(resourceServer, readScope)],
      },
    });

    // ---- トークン取得の動作確認用の出力(クライアントシークレットは出力しない) ----
    new cdk.CfnOutput(this, 'UserPoolId', { value: this.userPool.userPoolId });
    new cdk.CfnOutput(this, 'ClientId', { value: this.userPoolClient.userPoolClientId });
    new cdk.CfnOutput(this, 'TokenEndpoint', {
      value: `${this.userPoolDomain.baseUrl()}/oauth2/token`,
    });
    new cdk.CfnOutput(this, 'Scope', { value: 'agentcore/read' });
  }
}
