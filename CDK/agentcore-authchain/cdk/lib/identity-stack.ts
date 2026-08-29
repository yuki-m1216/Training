import * as crypto from 'crypto';
import * as path from 'path';
import * as cdk from 'aws-cdk-lib';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as cr from 'aws-cdk-lib/custom-resources';
import { Construct } from 'constructs';

export interface AuthChainIdentityStackProps extends cdk.StackProps {
  /**
   * Entra ID の「アプリのフェデレーション メタデータ URL」(ランブック §7)。
   * テナント ID・アプリ ID を含むためリポジトリに置かず、cdk の context(-c samlMetadataUrl=...)で渡す。
   */
  readonly samlMetadataUrl: string;
  /** Entra が SAML アサーションで送る会社名クレームの Attribute Name(ランブック §5。既定は Namespace 空の短名) */
  readonly samlCompanyClaim: string;
  /** 同、部門クレームの Attribute Name */
  readonly samlDepartmentClaim: string;
  /**
   * Entra ID の「ディレクトリ (テナント) ID」(ランブック v2.0 §2)。GUID のためリポジトリに置かず out/entra-oidc.json → context で渡す。
   * OIDC の issuer は https://login.microsoftonline.com/<tenantId>/v2.0(common / organizations は issuer がプレースホルダのため不可)
   */
  readonly entraTenantId: string;
  /** Entra ID App registration の「アプリケーション (クライアント) ID」(ランブック v2.0 §2) */
  readonly entraClientId: string;
  /**
   * クライアントシークレットを保存した Secrets Manager のシークレット名(ランブック v2.0 §3。平文文字列で保存)。
   * CDK の clientSecret は string 型しか無いため、動的参照 {{resolve:secretsmanager:...}} を埋め込む(テンプレートに平文を残さない)
   */
  readonly entraClientSecretName: string;
  /** Entra が OIDC の ID トークンで送る会社名クレーム名(ランブック v2.0 §4。Namespace 空 → 短名) */
  readonly oidcCompanyClaim: string;
  /** 同、部門クレーム名 */
  readonly oidcDepartmentClaim: string;
}

/**
 * 認証基盤スタック(V1a〜V1c)。
 * Cognito UserPool(Entra ID を SAML IdP として受ける SP)+ 認可マスタ(DynamoDB)+ 正規化 Lambda(Pre Token Generation)。
 *
 * - V1a: Pool / ドメイン / PKCE クライアント / 認可マスタ+シード / 正規化 Lambda(未接続)/ ローカルユーザー
 * - V1b: SAML IdP(EntraID)+ 属性マッピング + クライアントの supportedIdentityProviders 更新
 * - V1c: Pre Token Generation(V2_0)トリガー接続(addTrigger の 1 点差分)
 * - V1': OIDC IdP(EntraOIDC)を追加し SAML と併存 → OIDC で同じ連鎖(custom:*_raw → company_code)を実測後、SAML IdP を削除(計画_追加要件 §1)
 */
export class AuthChainIdentityStack extends cdk.Stack {
  /** V2/V3 の Runtime / Gateway が JWT オーソライザの discoveryUrl として参照する */
  public readonly userPool: cognito.UserPool;
  /** V2/V3 の allowedClients として参照する(アクセストークンの client_id と一致させる) */
  public readonly userPoolClient: cognito.UserPoolClient;
  /** hosted UI / OAuth2 エンドポイントの土台。SAML の ACS URL もこのドメイン配下 */
  public readonly userPoolDomain: cognito.UserPoolDomain;
  /** 会社名・部門名(表記ゆれあり)→ 正規化コードの認可マスタ */
  public readonly authzTable: dynamodb.TableV2;
  /** 正規化クレームを注入する Pre Token Generation Lambda(V1a では未接続) */
  public readonly preTokenGenFn: lambda.Function;

  constructor(scope: Construct, id: string, props: AuthChainIdentityStackProps) {
    super(scope, id, props);

    // ---------------------------------------------------------------- UserPool
    this.userPool = new cognito.UserPool(this, 'UserPool', {
      // Pre Token Generation V2_0(アクセストークン改変)は Essentials / Plus が前提
      featurePlan: cognito.FeaturePlan.ESSENTIALS,
      // 人がサインアップする経路は閉じる(ユーザーは Entra からのフェデレーション or 管理者作成のみ)
      selfSignUpEnabled: false,
      // ローカル切り分けユーザーは username でサインイン(email 等のエイリアスは作らない)
      signInAliases: { username: true },
      // 必須属性は作らない(作ると SAML から必ずマップしなければサインインが失敗する)
      standardAttributes: {},
      // フェデレーション属性マッピングの受け皿(仮決め #4)。SAML マッピング先は mutable 必須
      // (CDK の StringAttribute は既定 mutable=false なので明示する)
      customAttributes: {
        company_raw: new cognito.StringAttribute({ mutable: true, maxLen: 256 }),
        department_raw: new cognito.StringAttribute({ mutable: true, maxLen: 256 }),
      },
      // 検証用のため DESTROY(L2 既定は RETAIN)。本番は RETAIN + deletionProtection
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // ---------------------------------------------------------------- Domain(hosted UI / OAuth2 / SAML ACS の土台)
    this.userPoolDomain = this.userPool.addDomain('HostedUiDomain', {
      // プレフィックスはリージョン内一意 → アカウント ID で担保(兄弟プロジェクトと同じ手)
      cognitoDomain: { domainPrefix: `authchain-${this.account}` },
      // 仮決め #11: 最小工数の classic hosted UI(managed login はブランディング設定が別途必要)
      managedLoginVersion: cognito.ManagedLoginVersion.CLASSIC_HOSTED_UI,
    });

    // ---------------------------------------------------------------- SAML IdP(Entra ID)+ 属性マッピング(V1b)
    // Cognito は SP。Entra 側には SP entity ID(urn:amazon:cognito:sp:<PoolId>)と ACS URL(<domain>/saml2/idpresponse)を登録済み(ランブック §4)
    const entraIdp = new cognito.UserPoolIdentityProviderSaml(this, 'EntraIdp', {
      userPool: this.userPool,
      // 表示名 兼 フェデレーションユーザーのユーザー名プレフィックス(EntraID_<NameID>)。hosted UI のボタン名にもなる
      name: 'EntraID',
      // メタデータは URL 方式(Cognito が最長 6 時間キャッシュ)。証明書の手動登録は不要
      metadata: cognito.UserPoolIdentityProviderSamlMetadata.url(props.samlMetadataUrl),
      // SAML の Attribute Name → ユーザープール属性。キーは "custom:" プレフィックス付きでそのまま CFN AttributeMapping になる。
      // マッピング先は mutable 必須(#4)、かつアプリクライアントが書き込み可能であること(既定=全属性)
      attributeMapping: {
        custom: {
          'custom:company_raw': cognito.ProviderAttribute.other(props.samlCompanyClaim),
          'custom:department_raw': cognito.ProviderAttribute.other(props.samlDepartmentClaim),
        },
      },
      // idpSignout / encryptedResponses / requestSigningAlgorithm / idpInitiated は既定(off)。
      // 署名付きリクエストや暗号化は Cognito 側証明書を Entra に登録する追加手順が要るため本検証では使わない
    });

    // ---------------------------------------------------------------- OIDC IdP(Entra ID)+ 属性マッピング(V1')
    // Cognito は OIDC の RP。Entra 側には Web リダイレクト URI(<domain>/oauth2/idpresponse)を登録済み(ランブック v2.0 §2)。
    // Cognito は ID トークンと userInfo の両方を属性マッピングに使う(ID トークン優先)が、Entra の userInfo は固定 6 クレームのみのため
    // companyname / department は Entra 側「属性とクレーム」で ID トークンに載せる(+ manifest acceptMappedClaims)
    const entraOidc = new cognito.UserPoolIdentityProviderOidc(this, 'EntraOidcIdp', {
      userPool: this.userPool,
      // 表示名 兼 フェデレーションユーザーのユーザー名プレフィックス(EntraOIDC_<sub>。Entra の sub はアプリごとの pairwise 値)。3〜32 文字
      name: 'EntraOIDC',
      clientId: props.entraClientId,
      // Secrets Manager の動的参照。デプロイ時に CFN が解決するので cdk.out にも平文は出ない
      // (DescribeIdentityProvider では平文で返る = Cognito 内部保持は不可避)。値のローテーション後は自動で再取得されないため、
      // IdP リソースのプロパティ(scopes 等)を変えて再デプロイする
      clientSecret: cdk.SecretValue.secretsManager(props.entraClientSecretName).unsafeUnwrap(),
      // 末尾スラッシュ不可。Cognito は <issuer>/.well-known/openid-configuration から 4 エンドポイントを自動検出する(endpoints は省略)
      issuerUrl: `https://login.microsoftonline.com/${props.entraTenantId}/v2.0`,
      // openid 必須。Entra は name/oid に profile、email に email スコープが要る。カスタムクレームのスコープ依存は V1' で実測
      scopes: ['openid', 'profile', 'email'],
      // userInfo(https://graph.microsoft.com/oidc/userinfo)は GET/POST 両対応
      attributeRequestMethod: cognito.OidcAttributeRequestMethod.GET,
      // SAML と同じ受け皿にマッピングする(V1 の下流 = Pre Token Gen 以降を変えずに IdP だけ差し替える)
      attributeMapping: {
        // 人が読める識別子(V1'-b Q&A、A 案)。ユーザー名は EntraOIDC_<sub>(不変)のまま、Entra の可変な表示用クレームを
        // 標準属性に写す。Entra v2.0: preferred_username(通常 UPN)/name は profile スコープ、email は email スコープで来る。
        // 標準属性は CDK 既定で mutable、クライアントの writeAttributes は既定で全属性。アクセストークンには載らない
        preferredUsername: cognito.ProviderAttribute.other('preferred_username'),
        email: cognito.ProviderAttribute.other('email'),
        fullname: cognito.ProviderAttribute.other('name'),
        custom: {
          'custom:company_raw': cognito.ProviderAttribute.other(props.oidcCompanyClaim),
          'custom:department_raw': cognito.ProviderAttribute.other(props.oidcDepartmentClaim),
        },
      },
    });

    // ---------------------------------------------------------------- パブリッククライアント(PKCE / 認可コードグラント)
    this.userPoolClient = this.userPool.addClient('PkceClient', {
      // 公開クライアント(get_token.py はシークレットを持たず PKCE で交換する)
      generateSecret: false,
      oAuth: {
        flows: { authorizationCodeGrant: true },
        scopes: [cognito.OAuthScope.OPENID, cognito.OAuthScope.PROFILE, cognito.OAuthScope.EMAIL],
        callbackUrls: ['http://localhost:8400/callback'],
        logoutUrls: ['http://localhost:8400/logout'],
      },
      // V1a はローカル(COGNITO)のみだった。V1b で EntraID(SAML)を追加。V1' で EntraOIDC を併記(SAML 削除時にこの行と IdP を消す)
      supportedIdentityProviders: [
        cognito.UserPoolClientIdentityProvider.COGNITO,
        cognito.UserPoolClientIdentityProvider.custom(entraIdp.providerName),
        cognito.UserPoolClientIdentityProvider.custom(entraOidc.providerName),
      ],
      // ユーザー存在の有無をエラー文言で漏らさない
      preventUserExistenceErrors: true,
      // readAttributes / writeAttributes は既定(=全属性)。
      // 明示する場合は custom:company_raw / custom:department_raw を書き込み可能にしないと
      // SAML マッピングの値が「黙って設定されない」(ランブック §9)
    });
    // IdP が先に存在しないとクライアント更新が "provider does not exist" で失敗するため順序を明示
    this.userPoolClient.node.addDependency(entraIdp);
    this.userPoolClient.node.addDependency(entraOidc);

    // ---------------------------------------------------------------- 認可マスタ(DynamoDB)+ シード
    this.authzTable = new dynamodb.TableV2(this, 'AuthzMaster', {
      partitionKey: { name: 'pk', type: dynamodb.AttributeType.STRING },
      // 検証用のため DESTROY
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // 表記ゆれを複数登録し、正規化が「効く」ことを見せる(仮決め: User-A → TESTCO/SALES1 許可、User-B → OTHERCO/ADMIN1 拒否)
    const seedItems: { pk: string; code: string }[] = [
      { pk: 'COMPANY#株式会社テスト商事', code: 'TESTCO' },
      { pk: 'COMPANY#テスト商事（株）', code: 'TESTCO' },
      { pk: 'COMPANY#株式会社アザー', code: 'OTHERCO' },
      { pk: 'DEPT#第一営業部', code: 'SALES1' },
      { pk: 'DEPT#営業一部', code: 'SALES1' },
      { pk: 'DEPT#管理部', code: 'ADMIN1' },
    ];
    // シード内容が変わったときだけ再実行されるよう、物理 ID を内容のハッシュにする
    const seedHash = crypto.createHash('sha256').update(JSON.stringify(seedItems)).digest('hex').slice(0, 16);
    const seedCall: cr.AwsSdkCall = {
      service: 'DynamoDB',
      action: 'batchWriteItem',
      parameters: {
        RequestItems: {
          [this.authzTable.tableName]: seedItems.map((item) => ({
            PutRequest: { Item: { pk: { S: item.pk }, code: { S: item.code } } },
          })),
        },
      },
      physicalResourceId: cr.PhysicalResourceId.of(`authz-master-seed-${seedHash}`),
    };
    new cr.AwsCustomResource(this, 'AuthzMasterSeed', {
      onCreate: seedCall,
      onUpdate: seedCall,
      policy: cr.AwsCustomResourcePolicy.fromSdkCalls({ resources: [this.authzTable.tableArn] }),
      installLatestAwsSdk: false,
      // logRetention(非推奨。LogRetention 用 Lambda が余分に作られる)ではなく明示ロググループ + DESTROY
      logGroup: new logs.LogGroup(this, 'AuthzMasterSeedLogs', {
        retention: logs.RetentionDays.ONE_WEEK,
        removalPolicy: cdk.RemovalPolicy.DESTROY,
      }),
    });

    // ---------------------------------------------------------------- 正規化 Lambda(Pre Token Generation V2_0)。V1a では未接続
    const preTokenGenLogs = new logs.LogGroup(this, 'PreTokenGenLogs', {
      // 明示的に作って DESTROY にしておくと cdk destroy で消える(消し忘れ防止)
      retention: logs.RetentionDays.ONE_WEEK,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });
    this.preTokenGenFn = new lambda.Function(this, 'PreTokenGenFn', {
      runtime: lambda.Runtime.PYTHON_3_13,
      handler: 'handler.lambda_handler',
      code: lambda.Code.fromAsset(path.join(__dirname, '../../lambda/pre_token_gen')),
      environment: { TABLE_NAME: this.authzTable.tableName },
      timeout: cdk.Duration.seconds(5),
      logGroup: preTokenGenLogs,
    });
    this.authzTable.grantReadData(this.preTokenGenFn);
    // V1c: Pre Token Generation を V2_0(ID + アクセストークンの両方を改変)で接続。
    // V2_0 は PRE_TOKEN_GENERATION_CONFIG 側でのみ指定可(CFN: LambdaConfig.PreTokenGenerationConfig{LambdaArn, LambdaVersion})。
    // 併せて cognito-idp.amazonaws.com からの Invoke を許可する Lambda::Permission が生成される
    this.userPool.addTrigger(cognito.UserPoolOperation.PRE_TOKEN_GENERATION_CONFIG, this.preTokenGenFn, cognito.LambdaVersion.V2_0);

    // ---------------------------------------------------------------- 切り分け用ローカルユーザー(仮決め #12)
    // CloudFormation はパスワードを設定できないため、デプロイ後に
    //   aws cognito-idp admin-set-user-password --permanent を 1 回実行する(パスワードはリポジトリに置かない)
    new cognito.CfnUserPoolUser(this, 'LocalUserA', {
      userPoolId: this.userPool.userPoolId,
      username: 'local-user-a',
      // 招待メールを送らない(メールアドレスも持たせない)
      messageAction: 'SUPPRESS',
      // Entra 経由の User-A と同じ生値を持たせ、Cognito 以降(Pre Token Gen → AgentCore)を単独検証できるようにする
      userAttributes: [
        { name: 'custom:company_raw', value: '株式会社テスト商事' },
        { name: 'custom:department_raw', value: '第一営業部' },
      ],
    });

    // ---------------------------------------------------------------- 出力(Entra 側に入れる値と、スクリプトが使う値)
    const baseUrl = this.userPoolDomain.baseUrl();
    new cdk.CfnOutput(this, 'UserPoolId', { value: this.userPool.userPoolId });
    new cdk.CfnOutput(this, 'ClientId', { value: this.userPoolClient.userPoolClientId });
    new cdk.CfnOutput(this, 'HostedUiBaseUrl', { value: baseUrl });
    new cdk.CfnOutput(this, 'AuthorizeEndpoint', { value: `${baseUrl}/oauth2/authorize` });
    new cdk.CfnOutput(this, 'TokenEndpoint', { value: `${baseUrl}/oauth2/token` });
    // ランブック §4「識別子 (エンティティ ID)」と「応答 URL (ACS URL)」に入れる値そのもの
    new cdk.CfnOutput(this, 'SamlSpEntityId', { value: `urn:amazon:cognito:sp:${this.userPool.userPoolId}` });
    new cdk.CfnOutput(this, 'SamlAcsUrl', { value: `${baseUrl}/saml2/idpresponse` });
    // ランブック v2.0 §2「リダイレクト URI」に入れる値そのもの(OIDC は SAML の ACS とは別パス)
    new cdk.CfnOutput(this, 'OidcRedirectUri', { value: `${baseUrl}/oauth2/idpresponse` });
    new cdk.CfnOutput(this, 'AuthzTableName', { value: this.authzTable.tableName });
    new cdk.CfnOutput(this, 'PreTokenGenFunctionName', { value: this.preTokenGenFn.functionName });
  }
}
