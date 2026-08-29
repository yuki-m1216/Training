# 検証ログ V1'：Entra ID フェデレーションの OIDC 化（SAML → OIDC 置換） v1.0

対象：計画書 `計画_追加要件_v1_0.md` 要件 1（§1）、ランブック `ランブック_EntraID設定_v2_0.md`。仮決め #2 を SAML → OIDC に変更（2026-08-29 ユーザー承認）。

## V1' 合格条件チェックリスト
| # | 条件 | 状態 | 出典 |
|---|---|---|---|
| 1 | OIDC IdP `EntraOIDC` 経由のログインで `custom:company_raw` / `custom:department_raw` が保存される（`admin-get-user`） | **完了** | V1'-b |
| 2 | 同じ Pre Token Gen で `company_code` / `department_code` が両トークンに注入される（IdP 差し替えで下流不変） | **完了** | V1'-b |
| 3 | `acceptMappedClaims` 未設定時の `AADSTS50146` を実測（壊す実験）または理由を記録 | 省略（ユーザーが事前に true 設定済み） | V1'-b |
| 4 | SAML IdP 削除後も OIDC ログイン可、旧ユーザーの棚卸し完了 | 未 | V1'-c |
| 5 | シーケンス図（OIDC 版）、仮決め #2/#4 の実測列、コスト表 §3 の更新 | 未 | 完了時 |

---

## V1'-a：OIDC IdP 追加（SAML と併存）— CDK 差分と synth（2026-08-29）

### 目的
Entra ID を OIDC IdP として Cognito に追加し、SAML と併存させる。Entra 側（ランブック v2.0 §2〜§7）はユーザー作業のため、先に CDK 差分を作って synth で形を確認し、値が揃い次第デプロイする。

### 設計の要点（公式確認 → 反映。参照 URL は計画書 付録 A）
- `UserPoolIdentityProviderOidc`：`issuerUrl = https://login.microsoftonline.com/<tenant>/v2.0`（末尾スラッシュ不可、`common` 不可）、`endpoints` 省略（discovery 自動検出）、`scopes: openid profile email`、`attributeRequestMethod: GET`
- `clientSecret` は string 型のみ → `SecretValue.secretsManager(<name>).unsafeUnwrap()` で CFN 動的参照 `{{resolve:secretsmanager:<name>:SecretString:::}}` を埋め込む（**シークレットは平文文字列で保存**。JSON にすると `SecretString` 全体＝JSON がシークレット値として渡ってしまう）
- 属性マッピングは SAML と同じ受け皿（`custom:company_raw ← companyname`、`custom:department_raw ← department`）。Pre Token Gen 以降は無変更
- クライアント `supportedIdentityProviders` に `EntraOIDC` を併記、`addDependency(entraOidc)`
- 入力は `out/entra-oidc.json`（gitignore）を既定、`-c` で上書き。未指定は synth で停止（IdP 削除差分の事故防止。SAML の `samlMetadataUrl` と同じ流儀）
- 出力 `OidcRedirectUri = <HostedUiBaseUrl>/oauth2/idpresponse`（SAML の `/saml2/idpresponse` とは別パス）

### 予想（Claude が代行。実測と照合）
- (a) `cdk synth`：OIDC IdP のテンプレートは `ProviderType: OIDC`、`ProviderDetails` に `client_id` / `client_secret`（動的参照の文字列）/ `authorize_scopes: "openid profile email"` / `attributes_request_method: GET` / `oidc_issuer`。`authorize_url` 等 4 エンドポイントは**出ない**（discovery に任せる）
- (b) `cdk diff`（デプロイ前）：`[+] AWS::Cognito::UserPoolIdentityProvider EntraOidcIdp`、`[~] UserPoolClient` の `SupportedIdentityProviders` に 1 要素追加、`[+] Output OidcRedirectUri`、さらに **V2 の Runtime スタックを同じ app に配線したことによるクロススタック参照の出力 2 件**（`PublishOutputRefUserPool…` / `PublishOutputRefUserPoolPkceClient…`。synth で確認済み。Runtime 側は `Fn::GetStackOutput` で参照）の計 **5 点**。UserPool・テーブル・Lambda は不変
- (c) デプロイ：CFN が Secrets Manager を解決できないと IdP 作成で失敗（シークレット名の誤り／未作成／リージョン違い）。成功時、Cognito は IdP 作成時点で discovery を取りに行く（issuer 誤りはここで `InvalidParameterException`）

### 実行コマンド
```bash
# synth(ダミー値。AWS 認証情報不要)
npx cdk synth AuthChainIdentityStack --quiet \
  -c samlMetadataUrl="$(cat ../out/saml-metadata-url.txt)" \
  -c entraTenantId=<dummy GUID> -c entraClientId=<dummy GUID> -c entraClientSecretName=authchain/entra-oidc-client-secret
# デプロイ(out/entra-oidc.json が揃ってから)
npx cdk diff  -c samlMetadataUrl="$(cat ../out/saml-metadata-url.txt)"
npx cdk deploy -c samlMetadataUrl="$(cat ../out/saml-metadata-url.txt)" --outputs-file ../out/identity-outputs.json
```

### 出力（現物）：synth（2026-08-29、ダミー値）
```json
"EntraOidcIdp...": {
  "AttributeMapping": { "custom:company_raw": "companyname", "custom:department_raw": "department" },
  "ProviderDetails": {
    "client_id": "<dummy>",
    "client_secret": "{{resolve:secretsmanager:authchain/entra-oidc-client-secret:SecretString:::}}",
    "authorize_scopes": "openid profile email",
    "attributes_request_method": "GET",
    "oidc_issuer": "https://login.microsoftonline.com/<dummy>/v2.0"
  },
  "ProviderName": "EntraOIDC", "ProviderType": "OIDC"
}
Client.SupportedIdentityProviders = ["COGNITO", {"Ref": "EntraIdp..."}, {"Ref": "EntraOidcIdp..."}]
Outputs: OidcRedirectUri
```

### 実測と解釈
- **［実測］(a) 一致**：4 エンドポイントは出力されず discovery 任せ。`client_secret` は動的参照の文字列として埋め込まれ、`cdk.out` に平文なし
- **［実測］** クライアントの `SupportedIdentityProviders` は `Ref` で IdP を参照するため、CFN 上も IdP → クライアントの順序が保証される（`addDependency` は二重の安全）
- **［実測］(b) 一致（2026-08-29 `cdk diff`、変更セット方式）**：`[+] UserPoolIdentityProvider EntraOidcIdp`、`[~] UserPoolClient`（`SupportedIdentityProviders` に `Ref` 追加、`DependsOn` に IdP 追加）、`[+] Output` 3 件（`OidcRedirectUri`／`PublishOutputRefUserPool…`／`PublishOutputRefUserPoolPkceClient…`）。UserPool・テーブル・Lambda・ドメインは差分なし
- **［実測］(c) 一致（`cdk deploy`、16 秒）**：`EntraOidcIdp CREATE_COMPLETE`（2 秒）→ `PkceClient UPDATE_COMPLETE`。Secrets Manager の動的参照は CFN が解決し、Cognito は issuer から discovery を取得できた（失敗すれば IdP 作成で止まるはず）。事前に `describe-secret` で存在確認（値は取得しない）、`get-caller-identity` で `user/Y_admin` を確認
- **［実測］`describe-identity-provider EntraOIDC`**：`ProviderType = OIDC`、`AttributeMapping` は CDK で書いた 2 件に加えて **`username: sub` が自動追加**（OIDC の `sub` → ユーザー名。公式どおり）。`ProviderDetails` は `client_id`／`oidc_issuer = https://login.microsoftonline.com/<tenant>/v2.0`／`authorize_scopes = openid profile email`／`attributes_request_method = GET`／`attributes_url_add_attributes = false` の 5 項目で、**discovery で解決される `authorize_url`／`token_url`／`attributes_url`／`jwks_uri` は保存・表示されない**（予想 (a) の「出ない」はテンプレートだけでなく API 応答でも同じ。Cognito は実行時に discovery を引く）。`client_secret` は API 応答に平文で含まれる（計画書 §1-1 のとおり。上の抽出では除外）
- **［実測］** クライアントの `SupportedIdentityProviders` は `Ref` で IdP を参照するため、CFN 上も IdP → クライアントの順序が保証される（`addDependency` は二重の安全）
- **［実測］(b) 一致（2026-08-29 `cdk diff`、変更セット方式）**：`[+] UserPoolIdentityProvider EntraOidcIdp`、`[~] UserPoolClient`（`SupportedIdentityProviders` に `Ref` 追加、`DependsOn` に IdP 追加）、`[+] Output` 3 件（`OidcRedirectUri`／`PublishOutputRefUserPool…`／`PublishOutputRefUserPoolPkceClient…`）。UserPool・テーブル・Lambda・ドメインは差分なし
- **［実測］(c) 一致（`cdk deploy`、16 秒）**：`EntraOidcIdp CREATE_COMPLETE`（2 秒）→ `PkceClient UPDATE_COMPLETE`。Secrets Manager の動的参照は CFN が解決し、Cognito は issuer から discovery を取得できた（失敗すれば IdP 作成で止まるはず）。事前に `describe-secret` で存在確認（値は取得しない）、`get-caller-identity` で `user/Y_admin` を確認
- **［実測］`describe-identity-provider EntraOIDC`**：`ProviderType = OIDC`、`AttributeMapping = {custom:company_raw: companyname, custom:department_raw: department}`、`ProviderDetails` は `client_id`／`oidc_issuer = https://login.microsoftonline.com/<tenant>/v2.0`／`authorize_scopes = openid profile email`／`attributes_request_method = GET` に加え、**Cognito が discovery から補完した `authorize_url`／`token_url`／`attributes_url`／`jwks_uri`**（下記の現物）と `attributes_url_add_attributes = false`。`client_secret` は API 応答に平文で含まれる（計画書 §1-1 のとおり。ログには載せない）
- **［実測］** クライアントの `SupportedIdentityProviders = [COGNITO, EntraID, EntraOIDC]`（併存）

### 出力（現物）：describe-identity-provider（2026-08-29、GUID マスク、client_secret 除外）
```json
{
 "ProviderName": "EntraOIDC", "ProviderType": "OIDC",
 "AttributeMapping": { "custom:company_raw": "companyname", "custom:department_raw": "department", "username": "sub" },
 "ProviderDetails": {
  "attributes_request_method": "GET", "attributes_url_add_attributes": "false",
  "authorize_scopes": "openid profile email", "client_id": "<GUID>",
  "oidc_issuer": "https://login.microsoftonline.com/<GUID>/v2.0"
 },
 "IdpIdentifiers": []
}
SupportedIdentityProviders = ["COGNITO", "EntraID", "EntraOIDC"]
```


---

## V1'-b：OIDC ログインの観測（2026-08-29）

### 目的
`get_token.py --user userA-oidc --idp EntraOIDC` で User-A が Entra（OIDC）経由でログインし、属性マッピング → Pre Token Gen → トークンの連鎖が SAML 時と同じ結果になることを確認する。Entra 側は `acceptMappedClaims: true` 設定済み（壊す実験 (a) は省略）。

### 予想 → 実測
| # | 予想 | 実測 |
|---|---|---|
| (b) | 初回ログインで `custom:company_raw = 株式会社テスト商事` / `custom:department_raw = 第一営業部` が保存される | **一致**。`list-users` で新ユーザーに両属性あり（Entra の「属性とクレーム」で追加した短名クレームが ID トークンに載り、マッピングされた） |
| (c) | 新ユーザー `EntraOIDC_<sub>`（4 人目）、`identities.providerName = EntraOIDC`、自動グループ `<PoolId>_EntraOIDC` | **一致**。ユーザー名は `EntraOIDC_` + 43 文字の不透明文字列（計 53 文字、GUID 形ではない＝pairwise `sub`）、`UserStatus = EXTERNAL_PROVIDER`、`identities[0] = {providerName: EntraOIDC, providerType: OIDC, userId: <sub>, primary: true}`、両トークンの `cognito:groups = ["<PoolId>_EntraOIDC"]` |
| (d) | `triggerSource = TokenGeneration_HostedAuth`、両トークンに `company_code = TESTCO` / `department_code = SALES1` | **一致**。Lambda ログ：`{"triggerSource": "TokenGeneration_HostedAuth", "userAttributeKeys": ["cognito:user_status", "custom:company_raw", "custom:department_raw", "identities", "sub"], "scopes": ["openid", "profile", "email"]}` → `{"injectedClaims": {"company_code": "TESTCO", "department_code": "SALES1"}}`（329 ms） |
| (e) | 旧 SAML ユーザー `EntraID_…` は残り二重になる | **一致**。プールは 4 名（local-user-a／EntraID_<User-A>／EntraID_<管理者>#EXT#／EntraOIDC_<User-A>） |

### 出力（現物）：トークン（`decode_jwt.py --mask`、抜粋）
```
access_token: token_use=access, client_id=<ClientId>, scope="openid profile email", username="EntraOIDC_…",
              cognito:groups=["<PoolId>_EntraOIDC"], company_code=TESTCO, department_code=SALES1, exp=iat+3600
id_token    : aud=<ClientId>, cognito:username="EntraOIDC_…", custom:company_raw=株式会社テスト商事, custom:department_raw=第一営業部,
              identities=[{providerName: EntraOIDC, providerType: OIDC, userId: <sub>, issuer: null, primary: true}],
              cognito:groups=[…], company_code=TESTCO, department_code=SALES1
```

### 実測と解釈
- **［実測］IdP を差し替えても下流は無変更で成立**：Pre Token Gen に渡る `userAttributeKeys` は SAML 時と同じ 5 つ。「認可の根拠はプロファイルの `custom:*_raw` を経由してトークンで運ぶ」設計が IdP 方式に依存しないことの実証
- **［実測］ID トークンに `email`／`name`／`preferred_username` は無い**：`profile`/`email` スコープを要求しても、Cognito は**マッピングした属性しかプロファイルに書かない**（Entra の ID トークンには来ているはず）。人が読める識別子が欲しければ標準属性へのマッピングを足す（下記 Q&A）
- **［実測］OIDC の観測面は SAML より薄い**：ブラウザには `…/oauth2/idpresponse?code=…` のリダイレクトだけ。Entra が何を送ったかは `admin-get-user` の結果からの逆算（または ランブック v2.0 §8 の jwt.ms）
- **［実測］ユーザー名は pairwise `sub` 由来**：App registration を作り直すと別ユーザーになる（計画書 §1-5）

### 追加観測：標準属性マッピング（A 案、2026-08-29 17:03 deploy → 17:04 再ログイン）
CDK 差分は `EntraOidcIdp.AttributeMapping` に `preferred_username`／`email`／`name` の 3 件追加のみ（`cdk diff` は「Omitted 2 changes because they are likely mangled non-ASCII characters」を出したが、デプロイで更新されたリソースは IdP 1 つだけ＝表示上の注意で実害なし）。

| # | 予想 | 実測 |
|---|---|---|
| (f) | `admin-get-user` に `preferred_username`（UPN）／`email`／`name` が追加、ユーザー名不変・新ユーザーなし | **一部一致**：`preferred_username = <user>@<tenant>.onmicrosoft.com`、`name = User A` は追加。**`email` は追加されなかった**。EntraOIDC ユーザーは 1 名のまま（`UserLastModifiedDate` が再ログイン時刻に更新＝既存プロファイルの更新） |
| (g) | ID トークンに 3 クレーム、アクセストークンには載らない | **一部一致**：ID トークンに `preferred_username`／`name` あり、`email` なし。アクセストークンは `username = EntraOIDC_…` のみで属性なし |
| (h) | Lambda の `userAttributeKeys` に 3 つ増える | **一部一致**：`["cognito:user_status", "custom:company_raw", "custom:department_raw", "identities", "name", "preferred_username", "sub"]`（`email` なし）。注入結果は変わらず `TESTCO`/`SALES1` |

- **［実測→推定］`email` が来ない理由**：Entra の `email` クレームはユーザーの `mail` 属性が源で、テストユーザー（ライセンスなし・メールボックスなし）は `mail` が空 → Entra は**値の無いクレームを省略**する（SAML の V1b 初回と同じ挙動）。`email` スコープを要求しても値が無ければ出ない。確認するなら Entra でユーザーの「メール」を設定して再ログイン（任意）
- **［実測］マッピングは「無ければ黙って未設定」**：Cognito はエラーにせずログイン成功。必須属性にしていない限り、欠落は下流で気づくしかない（V1b と同じ教訓）
- **［実測］既存フェデレーションユーザーへの反映**：マッピング追加後の再サインインで、同じプロファイルに属性が追記された（ユーザー削除・再作成は不要）

### Q&A（ユーザー質問 2026-08-29）
1. **Cognito のユーザー名を Entra 側と合わせて読みやすくできるか**：公式「Amazon Cognito automatically maps the OIDC claim `sub` to `username`」「外部ディレクトリの属性と一致する属性が欲しければ、**`preferred_username` のようなサインイン属性にマッピングする**」（参照 A-15／A-3）。Microsoft も「UPN／メールは可変・再利用され得るため識別子に使わず `sub`/`oid` を使う」（A-16）。→ 推奨は **ユーザー名は `EntraOIDC_<sub>` のまま、UPN を `preferred_username` に写す**。`AttributeMapping` の `username` キーを `preferred_username` に上書きできるかは公式に明記なし（API はキーを受け付ける形。試すなら既存ユーザー削除が必要で、UPN 変更時に別ユーザー化するリスクを負う）
2. **Entra の UserPrincipalName を連携できるか**：できる。Entra の ID トークンは `profile` スコープで `preferred_username`（職場アカウントでは通常 UPN。可変）・`name`・`oid`（アプリ横断で不変）を、`email` スコープで `email` を返す。`upn` そのものは Token configuration の**オプションクレーム**（または属性とクレームで `user.userprincipalname`）で追加できる。Cognito 側は標準属性 `preferred_username`／`email`／`name`（CDK の標準属性は既定 mutable=true）にマッピングすれば ID トークンと `admin-get-user` に載る。**アクセストークンには属性が載らない**ので、Gateway/Cedar で使うなら Pre Token Gen で `upn` 等を注入する（V2 の `agents` 注入と同時に実装可）

---

## 変更履歴
- v1.0（2026-08-29）起票。V1'-a：OIDC IdP の CDK 差分と synth を記録（デプロイは Entra 側の値待ち）
- v1.0 追記（2026-08-29）V1'-a：diff／deploy の実測、describe-identity-provider の現物を記録
- v1.0 追記（2026-08-29）V1'-b：OIDC ログインの観測（予想 (b)〜(e) 全一致、トークン・Lambda ログの現物、ユーザー名／UPN の Q&A）を記録
- v1.0 追記（2026-08-29）V1'-b 追加観測：標準属性マッピング（preferred_username/name は反映、email は Entra 側に値が無く未反映）
