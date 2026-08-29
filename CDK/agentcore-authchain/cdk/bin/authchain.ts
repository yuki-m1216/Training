#!/usr/bin/env node
import * as fs from 'fs';
import * as path from 'path';
import * as cdk from 'aws-cdk-lib';
import { AuthChainIdentityStack } from '../lib/identity-stack';
import { AuthChainRuntimeStack } from '../lib/runtime-stack';

const app = new cdk.App();

const env = {
  // アカウント ID はリポジトリにコミットせず、実行時の認証情報(プロファイル)から解決する
  account: process.env.CDK_DEFAULT_ACCOUNT,
  // 仮決め #9: ap-northeast-1 で確定(検証ログ V0 TODO 2)。環境非依存にしない意図の表明
  region: 'ap-northeast-1',
};

// Entra ID のメタデータ URL(テナント ID・アプリ ID を含む)は §6 によりリポジトリに置かない。
// 実値は out/saml-metadata-url.txt(gitignore)に保存し、毎回 context で渡す:
//   npx cdk deploy -c samlMetadataUrl="$(cat ../out/saml-metadata-url.txt)"
// 未指定のまま synth/deploy すると IdP が「削除」される差分になるため、ここで止める。
const samlMetadataUrl = app.node.tryGetContext('samlMetadataUrl') ?? process.env.SAML_METADATA_URL;
if (!samlMetadataUrl) {
  throw new Error(
    'samlMetadataUrl が未指定です。-c samlMetadataUrl="$(cat ../out/saml-metadata-url.txt)" ' +
      'または環境変数 SAML_METADATA_URL で Entra のフェデレーション メタデータ URL を渡してください。',
  );
}

// V1': Entra の OIDC 設定値(テナント ID・クライアント ID = GUID、シークレット名)。ランブック v2.0 §7 の out/entra-oidc.json(gitignore)を
// 既定の入力源とし、context(-c entraTenantId=... 等)があればそれを優先する。どちらも無ければ IdP が「削除」される差分になるため止める。
interface EntraOidcConfig {
  tenantId: string;
  clientId: string;
  clientSecretName: string;
  companyClaim?: string;
  departmentClaim?: string;
}
const entraOidcFile = path.join(__dirname, '../../out/entra-oidc.json');
const entraOidcFromFile: Partial<EntraOidcConfig> = fs.existsSync(entraOidcFile)
  ? (JSON.parse(fs.readFileSync(entraOidcFile, 'utf-8')) as Partial<EntraOidcConfig>)
  : {};
const entraOidc: Partial<EntraOidcConfig> = {
  tenantId: app.node.tryGetContext('entraTenantId') ?? entraOidcFromFile.tenantId,
  clientId: app.node.tryGetContext('entraClientId') ?? entraOidcFromFile.clientId,
  clientSecretName: app.node.tryGetContext('entraClientSecretName') ?? entraOidcFromFile.clientSecretName,
  companyClaim: app.node.tryGetContext('oidcCompanyClaim') ?? entraOidcFromFile.companyClaim,
  departmentClaim: app.node.tryGetContext('oidcDepartmentClaim') ?? entraOidcFromFile.departmentClaim,
};
if (!entraOidc.tenantId || !entraOidc.clientId || !entraOidc.clientSecretName) {
  throw new Error(
    'Entra OIDC の設定が未指定です。out/entra-oidc.json(tenantId / clientId / clientSecretName。ランブック v2.0 §7)を置くか、' +
      '-c entraTenantId=... -c entraClientId=... -c entraClientSecretName=... で渡してください。',
  );
}

// V1: Cognito(SP)+ 認可マスタ + 正規化 Lambda。V2(Runtime)/V3(Gateway)/V4(Policy)は別スタックとして順次追加する
const identity = new AuthChainIdentityStack(app, 'AuthChainIdentityStack', {
  env,
  samlMetadataUrl,
  // Entra 側「属性とクレーム」の Attribute Name(ランブック §5。Namespace 空 → 短名)。実物と違えば -c で上書きできる
  samlCompanyClaim: app.node.tryGetContext('samlCompanyClaim') ?? 'companyname',
  samlDepartmentClaim: app.node.tryGetContext('samlDepartmentClaim') ?? 'department',
  entraTenantId: entraOidc.tenantId,
  entraClientId: entraOidc.clientId,
  entraClientSecretName: entraOidc.clientSecretName,
  // OIDC 側のクレーム名も既定は短名(ランブック v2.0 §4)
  oidcCompanyClaim: entraOidc.companyClaim ?? 'companyname',
  oidcDepartmentClaim: entraOidc.departmentClaim ?? 'department',
});

// V2: Runtime(最小エージェント inspect_headers)。Identity の Pool/Client を JWT オーソライザの信頼元にする(クロススタック参照)。
//   V2a: -c forwardAuth=false(既定) → Authorization はエージェントに届かない
//   V2b: -c forwardAuth=true         → requestHeaderAllowlist: ["Authorization"] の 1 点差分
//   V3 : -c gatewayUrl=<Gateway スタックの出力> を追加
const AGENT_KEY = 'inspect-headers'; // AgentEntitlement の sk / agents クレーム / customClaims 一致値と同じ定数
new AuthChainRuntimeStack(app, 'AuthChainRuntimeStack', {
  env,
  userPool: identity.userPool,
  userPoolClient: identity.userPoolClient,
  agentKey: AGENT_KEY,
  forwardAuthorizationHeader: app.node.tryGetContext('forwardAuth') === 'true',
  gatewayUrl: app.node.tryGetContext('gatewayUrl'),
});
