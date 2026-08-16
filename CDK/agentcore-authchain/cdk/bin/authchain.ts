#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import { AuthChainIdentityStack } from '../lib/identity-stack';

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

// V1: Cognito(SP)+ 認可マスタ + 正規化 Lambda。V2(Runtime)/V3(Gateway)/V4(Policy)は別スタックとして順次追加する
new AuthChainIdentityStack(app, 'AuthChainIdentityStack', {
  env,
  samlMetadataUrl,
  // Entra 側「属性とクレーム」の Attribute Name(ランブック §5。Namespace 空 → 短名)。実物と違えば -c で上書きできる
  samlCompanyClaim: app.node.tryGetContext('samlCompanyClaim') ?? 'companyname',
  samlDepartmentClaim: app.node.tryGetContext('samlDepartmentClaim') ?? 'department',
});
