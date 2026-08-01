# agentcore-gateway

Amazon Bedrock AgentCore Gateway の CDK ハンズオンプロジェクト。
Cognito の M2M 認証(client_credentials)で保護された AgentCore Gateway に
Lambda ツールを1本登録し、X-Ray Transaction Search で観測できる構成を
3スタックに分割して構築する。

## スタック構成(分割基準: 変化の速さ)

| スタック | 内容 |
| --- | --- |
| `FoundationStack` | Cognito ユーザープール / ドメイン / リソースサーバー(`agentcore/read`) / M2M アプリクライアント |
| `AgentPlatformStack` | AgentCore Gateway(CUSTOM_JWT 認可・exceptionLevel=DEBUG) + Lambda ターゲット(MCP ツール名 `hello___hello_world`) |
| `ObservabilityStack` | X-Ray Transaction Search 有効化(アカウント×リージョンレベル設定・他スタック非依存) |

- FoundationStack → AgentPlatformStack はコンストラクト参照を props で渡す(CFN 上は Export/Import)
- 検証用のため UserPool は `removalPolicy: DESTROY`。本番では RETAIN + deletionProtection が定石

## 前提

- リージョンは `ap-northeast-1` 固定(`bin/agentcore-gateway.ts` で指定)。アカウント ID は実行時の認証情報から解決する
- デプロイには cdk bootstrap 済みの環境が必要
- ObservabilityStack は ARN パーティションを `arn:aws:` 前提で合成する(非標準パーティションでは synth が失敗するガード付き)

## Useful commands

* `npm run build`   型チェック
* `npm test`        スタック合成テスト(Jest + fine-grained assertions)
* `npx cdk synth`   CloudFormation テンプレートを出力
* `npx cdk diff`    デプロイ済みスタックとの差分を表示
* `npx cdk deploy --all`  全スタックをデプロイ
