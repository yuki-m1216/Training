# ランブック：Entra ID 設定（SAML IdP として Cognito に接続する） v1.0

対象プロンプト：AgentCore認証チェーン検証実装 v1.1（§4 V0-5）。**作業者＝私（ユーザー）**、Entra 管理センターでの手作業。Claude Code は値の受け渡しと Cognito 側（CDK）を担当。

## 0. 全体像と 2 段階手順

Cognito が SP（サービスプロバイダ）、Entra ID が IdP。Entra 側に入力する値のうち **PoolId とユーザープールドメインは V1a のデプロイ後に確定**するため、手順は 2 段階に分かれる：

| 段階 | いつ | やること | 出力 |
|---|---|---|---|
| **第1段階（先にできる）** | 今〜V1a の前 | §1 テナント準備、§2 テストユーザー 2 名、§3 エンタープライズアプリ作成、§6 ユーザー割り当て | アプリの器 |
| **第2段階（V1a 後）** | V1a デプロイ後 | §4 Basic SAML Configuration に PoolId／ドメインを入力、§5 クレーム設定、§7 メタデータ URL 取得 → Claude Code に渡す | **App Federation Metadata Url** |
| （V1b 後） | ログイン観測時 | §8 DevTools で SAMLRequest／SAMLResponse を捕まえて `decode_saml.py` | 実物の SAML |

Cognito 側の値（V1a 後に確定。それまではプレースホルダ）：

| 項目 | 値 | 由来 |
|---|---|---|
| Identifier (Entity ID) | `urn:amazon:cognito:sp:<PoolId>` | Cognito 公式「SP entity ID」 |
| Reply URL (ACS URL) | `https://<CognitoDomain>/saml2/idpresponse` | Cognito 公式「ACS URL」。Cognito ドメインなら `https://<prefix>.auth.ap-northeast-1.amazoncognito.com/saml2/idpresponse` |
| Sign on URL | （空でよい） | SP-initiated（Cognito hosted UI から開始）のため不要 |

## 1. 無料テナントの用意

- Entra ID **Free** で足りる（SAML SSO のエンタープライズアプリ・カスタムクレームは Free で可）。追加ライセンス不要
- 既に Azure アカウント（Microsoft アカウント／職場アカウント）があれば、その**既定テナント**をそのまま使ってよい。検証専用に分けたい場合は次のどちらか：
  - (a) 新しい Microsoft アカウントで [無料の Azure アカウント](https://azure.microsoft.com/pricing/purchase-options/azure-account) にサインアップ → 既定テナントが 1 つ付いてくる
  - (b) 既存の**有料**サブスクリプション（従量課金等）を持つアカウントなら、Entra 管理センター > **Entra ID > 概要 > テナントの管理 > 作成**（Workforce）で追加テナントを作成。組織名／初期ドメイン名（`xxx.onmicrosoft.com`）／国＝Japan
  - **注意（公式記載）**：無料テナント／試用サブスクリプションのユーザーは管理センターから追加テナントを作成できない（「Only paid customers can create a new Workforce tenant」）。該当する場合は (a)
- 作成者には自動で **Global Administrator** が付く。以降の作業は Cloud Application Administrator 以上で可
- **控える値**：テナント ID（Entra ID > 概要 > テナント ID。**検証ログではマスク対象**）、初期ドメイン `<tenant>.onmicrosoft.com`

## 2. テストユーザー 2 名の作成（属性に意図的な表記ゆれ）

Entra 管理センター > **Entra ID > ユーザー > すべてのユーザー > 新しいユーザー > 新しいユーザーの作成**

| | User-A（許可対象） | User-B（拒否対象） |
|---|---|---|
| ユーザープリンシパル名 | `user-a@<tenant>.onmicrosoft.com` | `user-b@<tenant>.onmicrosoft.com` |
| 表示名 | `User A` | `User B` |
| パスワード | 自動生成を控える（初回サインインで変更を求められる） | 同左 |
| **プロパティ > 職務情報 > 会社名** | `株式会社テスト商事` | `株式会社アザー` |
| **プロパティ > 職務情報 > 部署** | `第一営業部` | `管理部` |
| 期待する正規化先（DynamoDB） | `TESTCO` / `SALES1` | `OTHERCO` / `ADMIN1` |

- 「会社名」「部署」は英語 UI では **Company name** / **Department**（= クレームのソース属性 `user.companyname` / `user.department`）
- 作成後、各ユーザーで一度サインイン（https://myapps.microsoft.com 等）してパスワード変更を済ませておくと、V1b のログイン観測が認証画面の脇道（パスワード変更・MFA 登録）で止まらない。**MFA／セキュリティ既定値の登録要求が出たら、検証中はスキップ可能な範囲で後回し**にしてよい（**推定・経験則**：新規テナントは「セキュリティの既定値群」が有効なことがあり、MFA 登録は一定期間「今はスキップ」できる。実際の画面で確認）
- 補足：ユーザーの会社名／部署は後から変えられる。表記ゆれの別パターン（`テスト商事（株）` / `営業一部`）は V1c の実験時に User-A の属性を書き換えて再ログインすれば試せる

## 3. エンタープライズアプリ（非ギャラリー）の作成

Entra 管理センター > **Entra ID > エンタープライズ アプリケーション > すべてのアプリケーション > 新しいアプリケーション > 独自のアプリケーションの作成**
- 名前：`cognito-authchain-verify`（任意）
- 「**ギャラリーに見つからないその他のアプリケーションを統合します（ギャラリー以外）**」を選択 → 作成
- 作成直後に **プロパティ > 「割り当てが必要ですか？」= はい**（既定）のままにする → §6 で 2 名だけ割り当てる（本番の「アプリに割り当てられたユーザーだけがログインできる」形を再現）

## 4. SAML SSO の基本設定（第2段階：V1a 後）

アプリ > **シングル サインオン > SAML** > **基本的な SAML 構成 > 編集**

| フィールド | 入力値 |
|---|---|
| 識別子 (エンティティ ID) | `urn:amazon:cognito:sp:<PoolId>`（既定として設定） |
| 応答 URL (Assertion Consumer Service URL) | `https://<CognitoDomain>/saml2/idpresponse` |
| サインオン URL | 空 |
| リレー状態 / ログアウト URL | 空 |

保存後、「**<アプリ名> のセットアップ**」欄の **ログイン URL**（`https://login.microsoftonline.com/<tenantId>/saml2`）／**Microsoft Entra 識別子**（`https://sts.windows.net/<tenantId>/`）を控える（SAMLRequest の Destination／SAMLResponse の Issuer として V1b の実物と照合する）。

## 5. クレーム設定（属性とクレーム）

アプリ > **シングル サインオン > 属性とクレーム > 編集**

### 5-1 既定で出るクレーム（触らない）
| 表示名 | 出力されるクレーム名 | ソース |
|---|---|---|
| 一意のユーザー識別子（名前 ID） | `NameID` | `user.userprincipalname` |
| givenname / surname / emailaddress / name | `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/{givenname,surname,emailaddress,name}` | 各 user.* |

**NameID の方針**：既定の UPN のままにする（Cognito のユーザー名が `EntraID_user-a@<tenant>.onmicrosoft.com` のように**人が読める形**になり観測しやすい）。Cognito 公式は「NameID は変わらない値から」と要求しており、本番では `user.objectid`＋形式 Persistent、または pairwiseid を検討する旨を検証ログに書き添える。

### 5-2 追加する 2 つのクレーム（本検証の本体）
「**新しいクレームの追加**」で 2 回：

| 名前 (Name) | 名前空間 (Namespace) | ソース | ソース属性 |
|---|---|---|---|
| `companyname` | **空** | 属性 | `user.companyname` |
| `department` | **空** | 属性 | `user.department` |

**名前空間の扱い（公式確認済み）**：Entra 公式「Enter the name of the claims. The value doesn't strictly need to follow a URI pattern, per the SAML spec. If you need a URI pattern, you can put that in the Namespace field.」— つまり **Namespace を空にすれば SAML の `Attribute Name` は短名（`companyname`）**、URI を入れれば `<Namespace>/<Name>` の形になる。既定クレームは URI 形（`http://schemas.xmlsoap.org/ws/2005/05/identity/claims/...`）で出る。

- 本検証は **Namespace 空＝短名**を採用（Cognito 側の属性マッピング `custom:company_raw ← companyname` が読みやすい。URI 形との違いも V1b の実物で見える）
- 保存後、「**追加の要求（Additional claims）**」の一覧に表示される**クレーム名の文字列をそのまま控える**（これが Cognito 属性マッピングのキー。表示が `companyname` なら短名、URI 付きなら URI 全体を Cognito 側に書く）
- **推定（V1b で実測）**：Namespace 空のとき、SAMLResponse の `<Attribute Name="companyname">` で出るはず。違えば `decode_saml.py` の Attributes 現物に合わせて Cognito 側マッピングを直す（V1b は「マッピングを合わせ直して再ログイン」の学習ループとして許容）

## 6. ユーザーの割り当て

アプリ > **ユーザーとグループ > ユーザーまたはグループの追加** → User-A、User-B を追加（ロールは既定 User）。
未割り当てのユーザーでログインすると Entra 側で `AADSTS50105`（アプリに割り当てられていない）で止まる——これも V1 の「壊す実験」の候補（任意）。

## 7. フェデレーション メタデータ URL の取得（Claude Code に渡す値）

アプリ > **シングル サインオン > SAML 証明書** セクション > **アプリのフェデレーション メタデータ URL** をコピー。
- 形は `https://login.microsoftonline.com/<tenantId>/federationmetadata/2007-06/federationmetadata.xml?appid=<appId>`（テナント ID・アプリ ID を含むので **検証ログではマスク**。CDK には context／パラメータで渡し、リポジトリに書かない：§6）
- Cognito 公式：メタデータ URL は https（443）必須、証明書は有効期限内、Cognito は URL からのメタデータを**最長 6 時間キャッシュ**
- 証明書のダウンロードは不要（URL 方式）。Cognito 側からの**署名付き SAML リクエスト**や**暗号化レスポンス**は本検証では使わない（使うと Cognito のユーザープール証明書を Entra に登録する追加手順が要る）

## 8. ブラウザ DevTools で SAML 往復を捕まえる手順（V1b）

`get_token.py` が開く hosted UI から Entra へ飛ぶ区間はスクリプトからは見えない。ブラウザで捕まえる。

1. Chrome/Edge で DevTools（F12）> **Network** タブ > **「Preserve log」を ON**（リダイレクトで消えないように）> フィルタに `saml` と入力
2. `get_token.py` が表示する authorize URL をそのブラウザで開き、Entra でログイン
3. **SAMLRequest（Cognito → Entra、HTTP-Redirect バインディング）**：一覧から `login.microsoftonline.com/<tenantId>/saml2?SAMLRequest=...` を選ぶ > **Payload**（Query String Parameters）> `SAMLRequest` の値をコピー（URL エンコードのままでよい。`RelayState` も並ぶ）
   - `python3 scripts/decode_saml.py '<コピーした値>'` → `AuthnRequest`：Issuer が `urn:amazon:cognito:sp:<PoolId>`、AssertionConsumerServiceURL が `/saml2/idpresponse`、ProtocolBinding が HTTP-POST であることを見る
4. **SAMLResponse（Entra → Cognito、HTTP-POST バインディング）**：一覧から `<CognitoDomain>/saml2/idpresponse` への **POST**（Status 302）を選ぶ > **Payload** > Form Data の `SAMLResponse` をコピー（「view decoded」でも「view source」でも `decode_saml.py` は受け付ける）
   - `python3 scripts/decode_saml.py '<コピーした値>'` → Issuer（`https://sts.windows.net/<tenantId>/`）、Destination／Recipient（`/saml2/idpresponse`）、Audience（`urn:amazon:cognito:sp:<PoolId>`）、NameID＋Format、**Attributes の現物（companyname / department と既定クレーム）**、InResponseTo が SAMLRequest の ID と一致
   - `--xml` で全文、`--json` で要約 JSON。検証ログには **NameID／テナント ID／メールをマスク**して貼る
5. 値はファイルに保存してよい（`out/saml_response_userA.b64` 等。`out/` は gitignore）
6. 代替：Firefox の拡張「SAML-tracer」でも同じものが見える。Cognito 側では `/oauth2/authorize` → 302 → Entra → POST `/saml2/idpresponse` → 302 → `http://localhost:8400/callback?code=...` の順に並ぶのが正常系

## 9. Cognito 側で満たしておくこと（V1a／V1b の設計入力。Claude Code 担当）

Cognito 公式（属性マッピング／SAML の注意点）から：
- マッピング先の **カスタム属性は mutable 必須**（immutable に IdP が値を送ると**エラーでサインイン失敗**）
- **アプリクライアントの WriteAttributes にマッピング先属性が含まれること**（含まれないと Cognito は値を**黙って設定せず認証は続行**——気づきにくい）→ `custom:company_raw` / `custom:department_raw` を書き込み可能に
- ユーザープールの**必須属性**は作らない（作るなら必ず SAML からマップする。例：`email ← http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress`）
- マッピング属性は**値が変わったときだけ更新**、IdP が送らなくなっても消えない
- ユーザー名は `<IdP名>_<NameID>`（case-insensitive プールなら全体が小文字化）
- メタデータ URL のキャッシュは最長 6 時間（Entra 側でクレームを変えても Cognito 側の再取得は不要——クレームはアサーション本文なのでメタデータと無関係。証明書ローテーションだけがキャッシュの影響を受ける）
- 4 バイト UTF-8（絵文字等）を属性値に含めない

## 10. トラブルシュート早見（V1b で詰まったら。エラーコードは代表例＝推定。実物は `docs/エラー文言表_v1_0.md` に追記）

| 症状 | 見どころ | 主な原因 |
|---|---|---|
| Entra 画面で `AADSTS50105` | Entra | ユーザーがアプリに未割り当て（§6） |
| Entra 画面で `AADSTS700016` / `AADSTS50011` | Entra | Identifier／Reply URL の不一致（§4）。SAMLRequest の Issuer と ACS URL を `decode_saml.py` で確認 |
| Cognito が `Invalid SAML response received: ...` を返す（callback に `error_description`） | Cognito | Audience／Recipient／InResponseTo の不一致、必須属性の欠落、immutable 属性へのマッピング。SAMLResponse を `decode_saml.py` で見る |
| `admin-get-user` に `custom:*_raw` が無い | Cognito | クレーム名の不一致（短名 vs URI）、WriteAttributes 漏れ、Entra 側で値が空 |
| CDK デプロイ時 `InvalidParameterException: Error retrieving metadata` | CDK/Cognito | メタデータ URL の誤り、https/443 以外 |

---

## 参照（公式）
- Cognito：[Using SAML identity providers with a user pool](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-saml-idp.html)（SP entity ID／ACS URL の形）／[Things to know about SAML IdPs](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-saml-idp-things-to-know.html)（NameID・Audience・InResponseTo・6 時間キャッシュ・POST バインディング）／[Mapping IdP attributes to profiles and tokens](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-specifying-attribute-mapping.html)（mutable 必須・WriteAttributes・ユーザー名の導出）
- Entra：[Customize SAML token claims](https://learn.microsoft.com/en-us/entra/identity-platform/saml-claims-customization)（Name／Namespace／NameID 形式）／[Enable SAML single sign-on for an enterprise application](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/add-application-portal-setup-sso)（Basic SAML Configuration・SAML 証明書・ロール）／[Quickstart: Add an enterprise application](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/add-application-portal)／[Quickstart: Create a new tenant](https://learn.microsoft.com/en-us/entra/fundamentals/create-new-tenant)（無料テナントからの追加作成不可の注記）
- 本ランブック中の「推定」箇所（Namespace 空→短名で出る、Entra 画面の日本語表記）は V1b の実物と画面で確定させ、変更履歴に反映する

## 変更履歴
- v1.0（2026-08-16）初版。2 段階手順・テストユーザー 2 名（表記ゆれ）・非ギャラリーアプリ・Basic SAML Configuration・クレーム（Namespace 空＝短名）・メタデータ URL・DevTools 捕捉手順・Cognito 側前提・トラブルシュートを記載
