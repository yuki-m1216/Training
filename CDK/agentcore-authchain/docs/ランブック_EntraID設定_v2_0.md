# ランブック：Entra ID 設定 v2.0（**OIDC** IdP として Cognito に接続する）

対象：計画書 `docs/計画_追加要件_v1_0.md` 要件 1（V1'）。**作業者＝私（ユーザー）**、Entra 管理センターでの手作業。Claude Code は値の受け渡しと Cognito 側（CDK）を担当。
v1.0（SAML 版）との違い：エンタープライズアプリ（SAML）ではなく **App registration（OIDC）** を作る。Cognito 側の値（ドメイン）は V1a で**デプロイ済み**なので、v1.0 のような 2 段階は不要——**このランブックの §2〜§7 は次回セッションの前にすべて実施できる**。

## 0. 全体像

| 項目 | 値 | 由来 |
|---|---|---|
| Redirect URI（Entra に登録） | `https://authchain-<ACCOUNT>.auth.ap-northeast-1.amazoncognito.com/oauth2/idpresponse` | `out/identity-outputs.json` の `HostedUiBaseUrl` + `/oauth2/idpresponse`（Cognito 公式。SAML の `/saml2/idpresponse` とは別パス） |
| Issuer（Cognito に登録。Claude Code 担当） | `https://login.microsoftonline.com/<tenant-id>/v2.0` | テナント GUID 必須（`common`/`organizations` は不可）。末尾スラッシュなし |
| Claude Code に渡す値（§7） | Directory (tenant) ID／Application (client) ID／Secrets Manager のシークレット名 | すべて `out/entra-oidc.json`（gitignore）へ。docs ではマスク |

流れ：§1 既存のテナント・ユーザーを流用 → §2 App registration → §3 クライアントシークレット（→ Secrets Manager）→ §4 クレーム（属性とクレーム）→ §5 manifest `acceptMappedClaims` → §6 ユーザー割り当て → §7 値の受け渡し → （任意）§8 jwt.ms で ID トークンの現物確認。

## 1. テナント・テストユーザー（v1.0 §1〜§2 をそのまま流用）
- テナント、User-A（`株式会社テスト商事` / `第一営業部`）、User-B（`株式会社アザー` / `管理部`）は v1.0 のものを使う。属性の変更不要
- v1.0 §3 で作った SAML エンタープライズアプリ（`cognito-authchain-verify`）は**残しておく**（V1' の実測が終わって SAML IdP を CDK から削除するまで併存）

## 2. App registration の作成
Entra 管理センター > **Entra ID > アプリの登録 > 新規登録**
- 名前：`cognito-authchain-oidc`（任意）
- サポートされているアカウントの種類：**この組織ディレクトリのみに含まれるアカウント（シングル テナント）** ← §5 の `acceptMappedClaims` はシングルテナント限定
- リダイレクト URI：プラットフォーム **Web**、値は §0 の Redirect URI（`https://` 必須・大文字小文字区別・完全一致。末尾スラッシュを付けない）
- 登録 → **概要**に出る **アプリケーション (クライアント) ID** と **ディレクトリ (テナント) ID** を控える（§7）
- 「認証」ブレードの **暗黙的な許可およびハイブリッド フロー（ID トークン）のチェックは不要**（Cognito は認可コードフロー。§8 の jwt.ms 確認をする場合のみ一時的に有効化）
- 「API のアクセス許可」は既定の `User.Read`（委任）のままでよい。`openid`/`profile`/`email` は OIDC の標準スコープとして追加の許可設定なしで要求できる（管理者の同意が求められたら「<テナント>に管理者の同意を与えます」を押す）

## 3. クライアントシークレットの発行 → Secrets Manager
アプリ > **証明書とシークレット > 新しいクライアント シークレット**
- 説明：`cognito-oidc`、有効期限：最短で足りる（検証期間 ＋ 余裕。**期限日を控える**——切れると Cognito の code 交換が `AADSTS7000222` 系で失敗する）
- 追加直後に表示される **「値」** を 1 回だけコピーできる（画面を離れると二度と見えない。「シークレット ID」ではなく「値」）
- 値は **Secrets Manager に平文文字列として**保存する（JSON にしない：CDK は `{{resolve:secretsmanager:<name>:SecretString:::}}` で文字列全体を参照する）。リポジトリ・チャット・ログには貼らない：

```bash
# (1) 値を一時ファイルに置く(out/ は gitignore)。コマンド履歴に値を残さないため引数ではなく file:// で渡す
printf '%s' '<貼り付け>' > out/entra-client-secret.txt
# (2) AWS_PROFILE を確認のうえ(Claude Code に任せる場合は次回セッションで実行)
aws secretsmanager create-secret \
  --name authchain/entra-oidc-client-secret \
  --description "Entra ID App registration (cognito-authchain-oidc) client secret for Cognito OIDC IdP" \
  --secret-string file://out/entra-client-secret.txt \
  --region ap-northeast-1
# (3) 一時ファイルを消す
rm out/entra-client-secret.txt
```
- シークレットを**ローテーションしたら**、Secrets Manager の値更新だけでは CloudFormation は再取得しない（公式）。IdP リソースの description 等を変えて再デプロイする（Claude Code 担当）
- Secrets Manager は有料（シークレット 1 件あたり月額少額＋API 呼び出し）。撤収時に削除する（計画書 §4 #2）

## 4. クレーム設定（属性とクレーム）
App registration を作ると、同名の **エンタープライズ アプリケーション**（サービスプリンシパル）が自動で作られる。クレームの追加はそちらで行う：
Entra 管理センター > **Entra ID > エンタープライズ アプリケーション > `cognito-authchain-oidc` > シングル サインオン > 属性とクレーム > 編集**
（OIDC アプリでも「属性とクレーム」が編集でき、JWT＝**ID トークン**に載る——公式 "Customize claims emitted in tokens for a specific app"）

「**新しいクレームの追加**」で 2 回（v1.0 §5-2 と同じ内容）：

| 名前 (Name) | 名前空間 (Namespace) | ソース | ソース属性 |
|---|---|---|---|
| `companyname` | **空** | 属性 | `user.companyname` |
| `department` | **空** | 属性 | `user.department` |

- 既定クレーム（`name`, `email`, `preferred_username` 等）は触らない
- 保存後に一覧に出る**クレーム名の文字列をそのまま控える**（Cognito 属性マッピングのキー。既定は短名 `companyname`/`department` を想定）
- **［未確認→V1' で実測］** 追加したカスタムクレームがスコープ（`profile`/`email`）に依存せず ID トークンに出るか。出なければ §8 で切り分け
- 値が空のユーザーではクレームが省略される（SAML と同じ挙動と推定）。User-A／User-B の会社名・部署が入っていることを v1.0 §2 で再確認

## 5. manifest で `acceptMappedClaims` を有効化（OIDC 固有・必須）
クレームを改変したアプリは、**カスタム署名鍵**か **`acceptMappedClaims: true`** のどちらかで「改変を受け入れる」宣言をしないと、ログイン時に **`AADSTS50146`**（"This application is required to be configured with an application-specific signing key…"）で止まる（公式）。カスタム署名鍵は discovery に `?appid=` が必要で Cognito と相性が悪いため、**シングルテナント向けの `acceptMappedClaims` を使う**。

App registration（エンタープライズアプリではない）> **マニフェスト**
- Microsoft Graph 形式のマニフェスト（既定表示）：`"api": { ... "acceptMappedClaims": true ... }` に変更
- 旧 Azure AD Graph 形式が表示されている場合：トップレベルの `"acceptMappedClaims": true`
- 保存。反映まで数分かかることがある
- **壊す実験（推奨）**：§5 を**あえて後回し**にして V1' の初回ログインで `AADSTS50146` を観測 → その後に true にして再ログイン（計画書 §1-4 (a)）。実施するかは次回セッション冒頭で決める（先に true にしてしまっても可）

## 6. ユーザーの割り当て
エンタープライズ アプリケーション > `cognito-authchain-oidc` > **プロパティ > 「割り当てが必要ですか？」= はい** を確認 → **ユーザーとグループ > ユーザーまたはグループの追加** → User-A、User-B。
未割り当てのユーザーは `AADSTS50105` で止まる（v1.0 と同じ）。

## 7. Claude Code に渡す値
`out/entra-oidc.json`（gitignore）に保存（Claude Code がファイル化してもよい）：
```json
{
  "tenantId": "<ディレクトリ (テナント) ID>",
  "clientId": "<アプリケーション (クライアント) ID>",
  "clientSecretName": "authchain/entra-oidc-client-secret",
  "companyClaim": "companyname",
  "departmentClaim": "department",
  "clientSecretExpires": "YYYY-MM-DD"
}
```
CDK には `-c entraTenantId=... -c entraClientId=... -c entraClientSecretName=...` で渡す（`bin/authchain.ts` 側で `out/entra-oidc.json` を読む形にしてもよい。リポジトリには書かない：公開リポジトリ方針）。

## 8. （任意）jwt.ms で Entra の ID トークンの現物を見る
OIDC の code 交換は **Cognito ↔ Entra のバックチャネル**で行われ、SAML の SAMLResponse のようにブラウザの DevTools で ID トークンを捕まえることは**できない**。Entra が何を出したかを直接見たいときだけ：
1. App registration > **認証** > プラットフォーム Web に `https://jwt.ms` を**追加**、「**ID トークン（暗黙的フローおよびハイブリッド フローに使用）**」にチェック → 保存
2. ブラウザで（`<tenant-id>`／`<client-id>` を置換）：
   `https://login.microsoftonline.com/<tenant-id>/oauth2/v2.0/authorize?client_id=<client-id>&response_type=id_token&redirect_uri=https%3A%2F%2Fjwt.ms&scope=openid%20profile%20email&response_mode=fragment&nonce=verify123`
3. User-A でログイン → jwt.ms にデコード済み ID トークンが表示される → `companyname` / `department` / `sub` / `iss` を確認（`iss` が §0 の Issuer と一致することも確認）
4. **確認後に元へ戻す**：`https://jwt.ms` を削除し、ID トークンのチェックを外す（implicit を開けたままにしない）
- 通常の切り分け順は v1.0 と同じ：トークン（`decode_jwt.py`）→ `admin-get-user` → （SAMLResponse の代わりに）§8

## 9. Cognito 側で満たしておくこと（V1' の設計入力。Claude Code 担当）
- IdP 名 `EntraOIDC`（3〜32 文字）。ユーザー名は `EntraOIDC_<sub>`（Entra の `sub` は**アプリごとに異なる pairwise 値**。App registration を作り直すと別ユーザーになる）
- `issuerUrl` は §0 の形式。`endpoints` は省略して discovery（`/.well-known/openid-configuration`）に任せる。Entra は `client_secret_post`・RS256・`kid` を満たす
- `scopes: ['openid', 'profile', 'email']`、`attributeRequestMethod: GET`
- 属性マッピング `custom:company_raw ← companyname`、`custom:department_raw ← department`（mutable 済み。クライアントの WriteAttributes は既定＝全属性）
- 必須属性は作らない（v1.0 §9 と同じ）。Cognito は ID トークンと userInfo の両方を見るが、Entra の userInfo は固定 6 クレームのみ
- アプリクライアントの `supportedIdentityProviders` に `EntraOIDC` を追加（移行期間は `EntraID`（SAML）と併記）。`get_token.py --idp EntraOIDC`
- SAML IdP の削除後、旧ユーザー `EntraID_*` と管理者副産物ユーザーは `admin-delete-user`（撤収手順に追記）

## 10. トラブルシュート早見（V1' で詰まったら。エラーコードは代表例＝推定。実物は検証ログに記録）

| 症状 | 見どころ | 主な原因 |
|---|---|---|
| Entra 画面で `AADSTS50146` | Entra | §5 `acceptMappedClaims` 未設定のままクレームを改変 |
| Entra 画面で `AADSTS50011` | Entra | Redirect URI 不一致（§2。`/oauth2/idpresponse`、末尾スラッシュ、https） |
| Entra 画面で `AADSTS50105` | Entra | ユーザー未割り当て（§6） |
| Entra 画面で `AADSTS700016` | Entra | クライアント ID がそのテナントに存在しない（テナント ID／クライアント ID の取り違え） |
| Cognito の callback に `error=invalid_request`／`error_description` に issuer・token の文言 | Cognito | `issuerUrl` の不一致（`common` を使った、末尾スラッシュ、GUID 誤り）、クライアントシークレット誤り／期限切れ（Entra 側は `AADSTS7000215`/`AADSTS7000222`） |
| ログインは成功するが `admin-get-user` に `custom:*_raw` が無い | Cognito/Entra | §4 のクレーム未追加・名前違い、ユーザーの会社名／部署が空、（未確認）スコープ依存 → §8 で現物確認 |
| ユーザー名が `EntraOIDC_<長い文字列>` で、以前の `EntraID_...` と別人になる | Cognito | 仕様（プロバイダ名＋pairwise `sub`）。異常ではない |

## 参照（公式）
- Cognito：[Using OIDC identity providers with a user pool](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-oidc-idp.html)（issuer の形式・コールバック URL・client_secret_post）／[OIDC フロー](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-oidc-flow.html)（ID トークンと userInfo の両方を参照、検証項目）／[Mapping IdP attributes](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-specifying-attribute-mapping.html)（ユーザー名 `<IdP>_<sub>`）
- Entra：[OpenID Connect on the Microsoft identity platform](https://learn.microsoft.com/en-us/entra/identity-platform/v2-protocols-oidc)（issuer／discovery）／[Customize claims emitted in tokens for a specific app](https://learn.microsoft.com/en-us/entra/identity-platform/jwt-claims-customization)（属性とクレーム、`acceptMappedClaims`、`AADSTS50146`、カスタム署名鍵と `?appid=`）／[Claims customization reference](https://learn.microsoft.com/en-us/entra/identity-platform/reference-claims-customization)（`user.companyname`/`user.department`）／[UserInfo endpoint](https://learn.microsoft.com/en-us/entra/identity-platform/userinfo)（固定 6 クレーム）／[Redirect URI restrictions](https://learn.microsoft.com/en-us/entra/identity-platform/reply-url)／[ID token claims reference](https://learn.microsoft.com/en-us/entra/identity-platform/id-token-claims-reference)（`sub` は pairwise、`profile`/`email` スコープ）／[Microsoft Graph app manifest](https://learn.microsoft.com/en-us/entra/identity-platform/reference-microsoft-graph-app-manifest)（`api.acceptMappedClaims`）
- AWS：[Secrets Manager 動的参照](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/dynamic-references-secretsmanager.html)
- 本ランブック中の「推定」箇所（Entra 画面の日本語表記、エラーコード、カスタムクレームのスコープ非依存）は V1' の実物で確定させ、変更履歴に反映する

## 変更履歴
- v2.0（2026-08-23）起票。SAML（v1.0）から OIDC への置き換え手順。計画書 `計画_追加要件_v1_0.md` 要件 1 に対応
