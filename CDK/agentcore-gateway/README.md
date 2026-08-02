# agentcore-gateway

Amazon Bedrock AgentCore Gateway の CDK ハンズオンプロジェクト。
Cognito の M2M 認証(client_credentials)で保護された AgentCore Gateway に
Lambda ツールを1本登録し、X-Ray Transaction Search で観測できる構成を
3スタックに分割して構築する。

## スタック構成(分割基準: 変化の速さ)

| スタック | 内容 |
| --- | --- |
| `FoundationStack` | Cognito ユーザープール / ドメイン / リソースサーバー(`agentcore/read`) / M2M アプリクライアント |
| `AgentPlatformStack` | AgentCore Gateway(CUSTOM_JWT 認可・exceptionLevel=DEBUG) + Lambda ターゲット(MCP ツール名 `hello___hello_world`)、AgentCore Runtime(strands エージェント・直接コードデプロイ・CUSTOM_JWT 認可) |
| `ObservabilityStack` | X-Ray Transaction Search 有効化(アカウント×リージョンレベル設定・他スタック非依存) |

- FoundationStack → AgentPlatformStack はコンストラクト参照を props で渡す(CFN 上は Export/Import)
- 検証用のため UserPool は `removalPolicy: DESTROY`。本番では RETAIN + deletionProtection が定石

## AgentCore Runtime (runtime-code/)

`runtime-code/` は Runtime にデプロイするエージェント本体(strands + Haiku 4.5)。
Docker/ECR を使わない直接コードデプロイ(`AgentRuntimeArtifact.fromCodeAsset`)のため、
依存は Runtime の実行基盤(linux/arm64, Python 3.13)向けにバンドルする必要がある。

```bash
# synth / test / deploy の前に必ず実行(build/ は gitignore 対象の生成物)
./runtime-code/build.sh
```

呼び出しは JWT 認証のため boto3/CLI 不可。HTTPS 直接:
`POST https://bedrock-agentcore.{region}.amazonaws.com/runtimes/{URLエンコードしたRuntimeArn}/invocations?qualifier=DEFAULT`
に `Authorization: Bearer`(Gateway と同じ Cognito トークン) +
`X-Amzn-Bedrock-AgentCore-Runtime-Session-Id`(33文字以上) + `{"prompt": "..."}`。

注意: Bedrock モデルの初回利用はアカウントで Marketplace 契約(agreement)の締結が必要。
未締結だと Runtime 内の ConverseStream が AccessDeniedException(aws-marketplace:Subscribe
の文言)で落ちる。管理者がプレイグラウンドで一度モデルを実行するか
`create-foundation-model-agreement` で締結してから検証する。

## 現在の構成と次のステップ(Runtime → Gateway 接続)

現状、Runtime と Gateway は Foundation の Cognito を共有するだけの並列構成で、
Runtime のエージェントはツールを持たない(Haiku が素で応答するだけ)。

```
[クライアント] ─Bearer─→ Runtime (strands + Haiku)        ← ツールなし
[クライアント] ─Bearer─→ Gateway ─→ Lambda (hello_world)
```

次のフィーチャーブランチで、AgentCore のリファレンス構成
「Runtime のエージェントが Gateway を MCP サーバーとして利用する」形に進める:

```
[クライアント] ─Bearer─→ Runtime (strands)
                            │ MCP + Bearer (アウトバウンド認可)
                            ▼
                         Gateway ─→ Lambda ツール群
```

予定している変更:

1. agent.py に strands の MCP クライアントを追加し、`GatewayUrl` のツール群を `Agent(tools=...)` に渡す
2. アウトバウンド認可は **AgentCore Identity の OAuth クレデンシャルプロバイダー**を使う
   (Runtime の環境変数にクライアントシークレットを直接置く簡易案は採らない)
3. Gateway URL は Runtime の `environmentVariables` でスタック内配線

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
