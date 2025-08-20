# Answer User Query - テストドキュメント

## 概要

このドキュメントは`answer_user_query`のLambda関数に対するpytestテストの詳細説明です。このLambda関数は、ユーザーの質問に対してRAG（Retrieval-Augmented Generation）方式で回答を生成します。

## 機能概要

### 主要な処理フロー
1. **質問受信**: API Gateway経由でユーザーの質問を受信
2. **ベクトル化**: AWS Bedrock Titan Embeddings でテキストをベクトル化
3. **類似検索**: OpenSearch で関連ドキュメントを検索
4. **回答生成**: AWS Bedrock Claude でコンテキストベースの回答を生成
5. **レスポンス返却**: CORS対応のHTTPレスポンスを返却

## テストファイル構成

### ファイル構造
```
answer_user_query/
├── main.py              # メイン実装
├── test_main.py         # pytestテストファイル
├── pyproject.toml       # Poetry設定
├── poetry.lock          # 依存関係ロック
└── TEST_README.md       # このファイル
```

## セットアップ手順

### 1. 依存関係のインストール
```bash
# poetryで依存関係をインストール
poetry install

# テスト用の追加依存関係（既に追加済みの場合はスキップ）
poetry add pytest boto3 opensearch-py --group dev
```

### 2. 環境確認
```bash
# poetry環境の確認
poetry env info

# インストール済みパッケージの確認
poetry show
```

## テスト実行方法

### 基本実行
```bash
# ディレクトリ移動
cd /home/linux/git/Training/Terraform/AWS/Resources/RAG/be/src/answer_user_query

# 環境変数を設定してテスト実行
OPENSEARCH_ENDPOINT="https://test-endpoint.region.aoss.amazonaws.com" poetry run pytest test_main.py -v
```

### その他の実行オプション

#### 特定のテストクラスのみ実行
```bash
# TestLambdaHandlerクラスのみ
OPENSEARCH_ENDPOINT="https://test-endpoint.region.aoss.amazonaws.com" poetry run pytest test_main.py::TestLambdaHandler -v

# TestInvokeBedrockクラスのみ
OPENSEARCH_ENDPOINT="https://test-endpoint.region.aoss.amazonaws.com" poetry run pytest test_main.py::TestInvokeBedrock -v
```

#### 特定のテストメソッドのみ実行
```bash
# 成功ケースのみ
OPENSEARCH_ENDPOINT="https://test-endpoint.region.aoss.amazonaws.com" poetry run pytest test_main.py::TestLambdaHandler::test_lambda_handler_success -v
```

#### 詳細出力付き実行
```bash
# より詳細な出力
OPENSEARCH_ENDPOINT="https://test-endpoint.region.aoss.amazonaws.com" poetry run pytest test_main.py -v -s

# 失敗時に詳細表示
OPENSEARCH_ENDPOINT="https://test-endpoint.region.aoss.amazonaws.com" poetry run pytest test_main.py -v --tb=long
```

#### カバレッジ付きテスト実行
```bash
# カバレッジレポート付き（要pytest-cov）
poetry add pytest-cov --group dev
OPENSEARCH_ENDPOINT="https://test-endpoint.region.aoss.amazonaws.com" poetry run pytest test_main.py --cov=main --cov-report=html -v
```

### 依存関係

#### 必須パッケージ
- **pytest**: テストフレームワーク
- **boto3**: AWS SDK
- **opensearch-py**: OpenSearch クライアント

#### 現在のpyproject.toml設定例
```toml
[tool.poetry.group.dev.dependencies]
pytest = "^8.4.1"

[project]
dependencies = [
    "requests>=2.32.3,<3.0.0",
    "opensearch-py>=2.8.0,<3.0.0",
    "boto3>=1.39.13,<2.0.0"
]
```

## テストクラス詳細

### 1. TestInvokeBedrock クラス
**目的**: `invoke_bedrock_embedding`関数のテスト

#### test_invoke_bedrock_embedding_success
```python
def test_invoke_bedrock_embedding_success(self, mock_bedrock_client):
```
- **テスト内容**: Bedrock Titan Embeddings APIの正常な呼び出し
- **検証項目**:
  - 正しいembeddingベクトルが返されること
  - APIが1回だけ呼ばれること
  - 正しいモデルID、Content-Type、Acceptヘッダーが設定されること
  - リクエストボディに正しいパラメータが含まれること

**重要なポイント**:
```python
# モックレスポンスの構造
mock_response = {
    'body': Mock()
}
mock_response['body'].read.return_value = json.dumps({
    'embedding': [0.1, 0.2, 0.3, 0.4, 0.5]
}).encode()
```

### 2. TestSearchOpensearch クラス
**目的**: `search_opensearch`関数のテスト

#### test_search_opensearch_success
- **テスト内容**: OpenSearchでの類似検索の正常処理
- **検証項目**:
  - 正しい検索クエリが構築されること
  - 検索結果からテキストが正しく抽出されること
  - kNNクエリのパラメータが正確であること

#### test_search_opensearch_empty_results
- **テスト内容**: 検索結果が空の場合の処理
- **検証項目**: 空のリストが返されること

**kNNクエリ構造**:
```python
query = {
    "size": top_k,
    "query": {
        "knn": {
            "embedding": {
                "vector": embedding,
                "k": top_k
            }
        }
    }
}
```

### 3. TestAskClaude クラス
**目的**: `ask_claude`関数のテスト

#### test_ask_claude_success
- **テスト内容**: AWS Bedrock Claude APIでの回答生成
- **検証項目**:
  - 正しいモデルIDが使用されること
  - プロンプトが適切に構築されること
  - レスポンスから回答テキストが正しく抽出されること

**プロンプト構造**:
- システムプロンプト: AWS公式FAQからの回答指示
- ユーザー質問と提供されたコンテキストを含む
- 提供された情報のみを使用する制約

### 4. TestLambdaHandler クラス
**目的**: `lambda_handler`関数の包括的テスト

#### test_lambda_handler_options_request
```python
def test_lambda_handler_options_request(self, options_event):
```
- **テスト内容**: CORS preflightリクエスト（OPTIONS）の処理
- **検証項目**:
  - ステータスコード200
  - 必要なCORSヘッダーの設定
  - 適切なレスポンスメッセージ

**CORSヘッダー**:
```python
"Access-Control-Allow-Origin": "*"
"Access-Control-Allow-Methods": "POST, OPTIONS"
"Access-Control-Allow-Headers": "Content-Type"
```

#### test_lambda_handler_no_question
- **テスト内容**: 質問が提供されない場合のエラーハンドリング
- **検証項目**:
  - ステータスコード400
  - 適切なエラーメッセージ

#### test_lambda_handler_success
- **テスト内容**: 正常なリクエスト処理の全フロー
- **モック対象**:
  - `bedrock_client`: グローバル変数
  - `search_opensearch`: 検索関数
  - `invoke_bedrock_embedding`: embedding関数
  - `ask_claude`: 回答生成関数

**処理順序の検証**:
1. embedding生成 → 2. 類似検索 → 3. 回答生成

#### test_lambda_handler_no_search_results
- **テスト内容**: 検索結果が空の場合の処理
- **検証項目**: デフォルトメッセージが返されること

### 5. TestIntegration クラス
**目的**: 統合テスト（全体パイプライン）

#### test_full_pipeline_mock
- **テスト内容**: 実際のAPIを使わずに全フローをテスト
- **モック戦略**:
  - `side_effect`を使用してモデルIDに応じて異なるレスポンスを返す
  - embedding用とClaude用で別々のモックレスポンスを設定

## フィクスチャ（Fixture）

### mock_bedrock_client
```python
@pytest.fixture
def mock_bedrock_client():
    mock_client = Mock()
    return mock_client
```
- **用途**: Bedrockクライアントのモック
- **利用場面**: embedding生成、Claude回答生成のテスト

### sample_event
```python
@pytest.fixture
def sample_event():
    return {
        "httpMethod": "POST",
        "body": json.dumps({"question": "AWS Lambda とは何ですか？"})
    }
```
- **用途**: 正常なHTTPリクエストのサンプル
- **構造**: API Gateway形式のイベント

### options_event / invalid_event
- **options_event**: CORS preflightリクエスト用
- **invalid_event**: 無効なリクエスト（質問なし）用

## モッキング戦略

### 外部依存の置換
1. **AWS Bedrock**: APIレスポンスをモック
2. **OpenSearch**: 検索結果をモック
3. **グローバル変数**: `bedrock_client`を直接モック

### モックレスポンスの構造

#### Bedrock Embedding レスポンス
```python
{
    'body': Mock_object_with_read_method,
    'ResponseMetadata': {...}
}

# read()の戻り値
{
    'embedding': [0.1, 0.2, 0.3, 0.4, 0.5]
}
```

#### Bedrock Claude レスポンス
```python
{
    'content': [
        {
            'text': '回答テキスト'
        }
    ]
}
```

## トラブルシューティング

### よくある問題と解決方法

#### 1. 環境変数エラー
```
KeyError: 'OPENSEARCH_ENDPOINT'
```
**解決方法**: テスト実行時に環境変数を設定
```bash
OPENSEARCH_ENDPOINT="https://test-endpoint.region.aoss.amazonaws.com" poetry run pytest test_main.py -v
```

#### 2. モジュールが見つからない
```
ModuleNotFoundError: No module named 'pytest'
```
**解決方法**: poetry環境で依存関係をインストール
```bash
poetry install
poetry add pytest --group dev
```

#### 3. AWS認証情報エラー
```
botocore.exceptions.NoCredentialsError
```
**解決方法**: モックが正しく適用されていない場合は、パッチの対象を確認
```python
# グローバル変数の場合
@patch('main.bedrock_client')

# 関数内で作成される場合
@patch('main.boto3.client')
```

#### 4. side_effectが期待通りに動作しない
**原因**: 引数の条件分岐が正しくない
**解決方法**: `kwargs['modelId']`で正確にモデルIDを判定
```python
def bedrock_side_effect(*args, **kwargs):
    if kwargs['modelId'] == "amazon.titan-embed-text-v2:0":
        return mock_embedding_response
    elif kwargs['modelId'] == "apac.anthropic.claude-3-5-sonnet-20241022-v2:0":
        return mock_claude_response
```

### デバッグ用コマンド

#### テスト失敗時の詳細確認
```bash
# 失敗したテストの詳細表示
OPENSEARCH_ENDPOINT="https://test-endpoint.region.aoss.amazonaws.com" poetry run pytest test_main.py -v --tb=long -s

# 特定のテストのみデバッグ実行
OPENSEARCH_ENDPOINT="https://test-endpoint.region.aoss.amazonaws.com" poetry run pytest test_main.py::TestLambdaHandler::test_lambda_handler_success -v -s --pdb
```

#### モックの呼び出し確認
```python
# テスト内でモックの呼び出し回数を確認
print(f"mock_function.call_count: {mock_function.call_count}")
print(f"mock_function.call_args: {mock_function.call_args}")
```

## CI/CD での実行

### GitHub Actions での設定例
```yaml
- name: Run tests
  run: |
    cd Terraform/AWS/Resources/RAG/be/src/answer_user_query
    OPENSEARCH_ENDPOINT="https://test-endpoint.region.aoss.amazonaws.com" poetry run pytest test_main.py -v
```

### テスト結果の保存
```bash
# JUnit XML形式でテスト結果を出力
OPENSEARCH_ENDPOINT="https://test-endpoint.region.aoss.amazonaws.com" poetry run pytest test_main.py --junit-xml=test-results.xml
```

このテストスイートにより、RAGシステムの信頼性と品質を確保し、デプロイ前に問題を早期発見できます。