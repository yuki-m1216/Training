# Vector Database - テストドキュメント

## 概要

このドキュメントは`vector_database`のLambda関数に対するpytestテストの詳細説明です。このLambda関数は、S3に保存されたembedding付きJSONファイルをダウンロードし、OpenSearch Serverlessにバルクインデックスする処理を行います。RAGシステムの検索データベース構築を担当します。

## 機能概要

### 主要な処理フロー
1. **JSONダウンロード**: S3バケットからembedding付きJSONファイルをダウンロード
2. **JSON読み込み**: ローカルファイルからJSONデータを読み込み
3. **OpenSearch接続**: AWS認証を使用してOpenSearch Serverlessに接続
4. **バルクインデックス**: ドキュメントを効率的にまとめてインデックス
5. **結果返却**: 成功・失敗件数を含むレスポンスを返却

## テストファイル構成

### ファイル構造
```
vector_database/
├── main.py              # メイン実装
├── test_main.py         # pytestテストファイル
├── pyproject.toml       # Poetry設定
├── poetry.lock          # 依存関係ロック
├── requirements.txt     # 旧形式の依存関係
└── TEST_README.md       # このファイル
```

## セットアップ手順

### 1. 依存関係のインストール
```bash
# poetryで依存関係をインストール
poetry install

# テスト用の追加依存関係（既に追加済みの場合はスキップ）
poetry add pytest boto3 --group dev
```

### 2. 環境確認
```bash
# poetry環境の確認
poetry env info

# インストール済みパッケージの確認
poetry show
```

### 3. 主要依存関係
- **opensearch-py**: OpenSearch Python クライアント
- **boto3**: AWS SDK（S3操作、認証）

## テスト実行方法

### 基本実行
```bash
# ディレクトリ移動
cd /home/linux/git/Training/Terraform/AWS/Resources/RAG/be/src/vector_database

# 環境変数を設定してテスト実行
OPENSEARCH_ENDPOINT="https://test-endpoint.region.aoss.amazonaws.com" S3BUCKET="test-bucket" S3BUCKET_KEY="output/text-with-embedding.json" poetry run pytest test_main.py -v
```

### その他の実行オプション

#### 特定のテストクラスのみ実行
```bash
# TestIndexDocumentsBulkクラスのみ
OPENSEARCH_ENDPOINT="https://test-endpoint.region.aoss.amazonaws.com" S3BUCKET="test-bucket" S3BUCKET_KEY="output/text-with-embedding.json" poetry run pytest test_main.py::TestIndexDocumentsBulk -v

# TestLambdaHandlerクラスのみ
OPENSEARCH_ENDPOINT="https://test-endpoint.region.aoss.amazonaws.com" S3BUCKET="test-bucket" S3BUCKET_KEY="output/text-with-embedding.json" poetry run pytest test_main.py::TestLambdaHandler -v
```

#### 特定のテストメソッドのみ実行
```bash
# バルクインデックスのテストのみ
OPENSEARCH_ENDPOINT="https://test-endpoint.region.aoss.amazonaws.com" S3BUCKET="test-bucket" S3BUCKET_KEY="output/text-with-embedding.json" poetry run pytest test_main.py::TestIndexDocumentsBulk::test_index_documents_bulk_success -v
```

#### 詳細出力付き実行
```bash
# より詳細な出力
OPENSEARCH_ENDPOINT="https://test-endpoint.region.aoss.amazonaws.com" S3BUCKET="test-bucket" S3BUCKET_KEY="output/text-with-embedding.json" poetry run pytest test_main.py -v -s

# 失敗時に詳細表示
OPENSEARCH_ENDPOINT="https://test-endpoint.region.aoss.amazonaws.com" S3BUCKET="test-bucket" S3BUCKET_KEY="output/text-with-embedding.json" poetry run pytest test_main.py -v --tb=long
```

#### カバレッジ付きテスト実行
```bash
# カバレッジレポート付き（要pytest-cov）
poetry add pytest-cov --group dev
OPENSEARCH_ENDPOINT="https://test-endpoint.region.aoss.amazonaws.com" S3BUCKET="test-bucket" S3BUCKET_KEY="output/text-with-embedding.json" poetry run pytest test_main.py --cov=main --cov-report=html -v
```

### 依存関係

#### 現在のpyproject.toml設定例
```toml
[project]
dependencies = [
    "opensearch-py (>=2.8.0,<3.0.0)"
]

[tool.poetry.group.dev.dependencies]
pytest = "^8.4.1"
boto3 = "^1.39.14"
```

## テストクラス詳細

### 1. TestDownloadJsonFromS3 クラス
**目的**: `download_json_from_s3`関数のテスト

#### test_download_json_from_s3_success
```python
def test_download_json_from_s3_success(self, mock_s3_client):
```
- **テスト内容**: S3からJSONファイルの正常ダウンロード
- **検証項目**:
  - 正しいローカルパス（`/tmp/document.json`）が返されること
  - S3クライアントの`download_file`が正しい引数で呼ばれること
  - 環境変数（`S3BUCKET`、`S3BUCKET_KEY`）が正しく使用されること

#### test_download_json_from_s3_error
- **テスト内容**: S3ダウンロード時のNoSuchKeyエラー
- **検証項目**: `ClientError`が適切に発生すること

#### test_download_json_from_s3_access_denied
- **テスト内容**: S3アクセス拒否エラー
- **検証項目**: アクセス権限エラー時の例外処理

**重要なポイント**:
```python
# 環境変数をテスト内で設定
@patch.dict(os.environ, {
    'S3BUCKET': 'test-bucket',
    'S3BUCKET_KEY': 'output/text-with-embedding.json'
})
```

### 2. TestLoadJson クラス
**目的**: `load_json`関数のテスト

#### test_load_json_success
- **テスト内容**: JSONファイルの正常な読み込み
- **検証項目**:
  - 正しいJSON構造が読み込まれること
  - ドキュメント数が期待通りであること
  - 各ドキュメントに`text`と`embedding`が含まれること

#### test_load_json_file_not_found
- **テスト内容**: ファイルが存在しない場合のエラー処理
- **検証項目**: `FileNotFoundError`が適切に発生すること

#### test_load_json_invalid_json
- **テスト内容**: 無効なJSONフォーマットの処理
- **検証項目**: `JSONDecodeError`が適切に発生すること

#### test_load_json_empty_file
- **テスト内容**: 空のファイルの処理
- **検証項目**: 空ファイル時のエラーハンドリング

**JSONデータ構造の例**:
```python
sample_documents = [
    {
        "page": 1,
        "text": "AWS Lambda はサーバーレスコンピューティングサービスです。",
        "embedding": [0.1, 0.2, 0.3, 0.4, 0.5]
    },
    {
        "page": 2,
        "text": "AWS S3 はオブジェクトストレージサービスです。",
        "embedding": [0.6, 0.7, 0.8, 0.9, 1.0]
    }
]
```

### 3. TestConnectOpensearch クラス
**目的**: `connect_opensearch`関数のテスト

#### test_connect_opensearch_success
- **テスト内容**: OpenSearch Serverlessへの正常な接続
- **モック対象**:
  - `boto3.Session`: AWS セッション
  - `OpenSearch`: OpenSearchクライアント
- **検証項目**:
  - 正しい接続設定が使用されること
  - AWSV4SignerAuthが設定されること
  - SSL、証明書検証が有効になること

#### test_connect_opensearch_credentials_error
- **テスト内容**: AWS認証情報取得エラー
- **検証項目**: 認証情報取得失敗時の例外処理

**OpenSearch接続設定**:
```python
OpenSearch(
    hosts=[{"host": "test-endpoint.region.aoss.amazonaws.com", "port": 443}],
    http_auth=auth,
    use_ssl=True,
    verify_certs=True,
    connection_class=RequestsHttpConnection,
    timeout=30
)
```

### 4. TestIndexDocumentsBulk クラス
**目的**: `index_documents_bulk`関数のテスト

#### test_index_documents_bulk_success
- **テスト内容**: ドキュメントの正常なバルクインデックス
- **モック対象**: `opensearchpy.helpers.bulk`
- **検証項目**:
  - 正しいアクション構造が生成されること
  - インデックス名（`faqs`）が正しく設定されること
  - `text`と`embedding`が正しく`_source`に含まれること
  - 成功・失敗件数が正しく返されること

#### test_index_documents_bulk_partial_failure
- **テスト内容**: 一部のドキュメントでインデックスが失敗した場合
- **検証項目**: 部分的な失敗が適切に処理されること

#### test_index_documents_bulk_empty_documents
- **テスト内容**: 空のドキュメントリストの処理
- **検証項目**: 空リスト時の適切な処理

#### test_index_documents_bulk_opensearch_error
- **テスト内容**: OpenSearchエラー時の例外処理
- **検証項目**: `OpenSearchException`が適切に発生すること

**バルクアクション構造**:
```python
actions = [
    {
        "_index": "faqs",
        "_source": {"text": doc["text"], "embedding": doc["embedding"]}
    }
    for doc in documents
]
```

### 5. TestLambdaHandler クラス
**目的**: `lambda_handler`関数の包括的テスト

#### test_lambda_handler_success
- **テスト内容**: Lambda関数全体の正常実行
- **モック対象**: 全ての主要関数をモック
- **検証項目**:
  - 正しい順序で関数が呼ばれること
  - 正しいレスポンス構造が返されること
  - 成功メッセージに件数が含まれること

**処理順序の検証**:
1. `download_json_from_s3()` → 2. `load_json()` → 3. `connect_opensearch()` → 4. `index_documents_bulk()`

#### test_lambda_handler_partial_success
- **テスト内容**: 一部のドキュメントでインデックスが失敗した場合
- **検証項目**: 部分的な成功が適切に報告されること

#### test_lambda_handler_s3_download_error
- **テスト内容**: S3ダウンロードエラー時の処理
- **検証項目**: エラーが適切に伝播されること

#### test_lambda_handler_json_load_error
- **テスト内容**: JSON読み込みエラー時の処理
- **検証項目**: JSONパースエラーが適切に伝播されること

#### test_lambda_handler_opensearch_connection_error
- **テスト内容**: OpenSearch接続エラー時の処理
- **検証項目**: 接続エラーが適切に伝播されること

### 6. TestIntegration クラス
**目的**: 統合テスト（全体パイプライン）

#### test_full_pipeline_mock
- **テスト内容**: 実際のサービスを使わずに全フローをテスト
- **モック戦略**:
  - S3クライアント、OpenSearchクライアント、bulk関数を全てモック
  - `mock_open`でファイル読み込みをモック
- **検証項目**: 全体フローが期待通りに動作すること

## フィクスチャ（Fixture）

### mock_s3_client / mock_opensearch_client
```python
@pytest.fixture
def mock_s3_client():
    mock_client = Mock()
    return mock_client
```
- **用途**: AWS S3クライアント、OpenSearchクライアントのモック

### sample_documents
```python
@pytest.fixture
def sample_documents():
    return [
        {
            "page": 1,
            "text": "AWS Lambda はサーバーレスコンピューティングサービスです。",
            "embedding": [0.1, 0.2, 0.3, 0.4, 0.5]
        },
        # ... more documents
    ]
```
- **用途**: embedding付きドキュメントのサンプルデータ
- **構造**: `page`、`text`、`embedding`フィールドを持つ辞書

### sample_json_content
```python
@pytest.fixture
def sample_json_content(sample_documents):
    return json.dumps(sample_documents, ensure_ascii=False)
```
- **用途**: JSONファイルの内容をシミュレート

## モッキング戦略

### 外部サービスの置換

#### AWS関連
```python
@patch('main.s3_client')
@patch('main.boto3.Session')
```
- **s3_client**: S3ダウンロード操作
- **boto3.Session**: AWS認証情報取得

#### OpenSearch関連
```python
@patch('main.OpenSearch')
@patch('main.bulk')
```
- **OpenSearch**: クライアント作成
- **bulk**: バルクインデックス操作

#### ファイルI/O
```python
@patch('builtins.open', mock_open(read_data=json_content))
```
- **ファイル読み込み**: 実際のファイル読み込みを回避

### バルクインデックスのモック

#### 成功ケース
```python
mock_bulk.return_value = (3, [])  # 成功3件、失敗0件
```

#### 部分失敗ケース
```python
failed_docs = [{"index": {"_id": "3", "status": 400, "error": {"reason": "Invalid document"}}}]
mock_bulk.return_value = (2, failed_docs)  # 成功2件、失敗1件
```

## トラブルシューティング

### よくある問題と解決方法

#### 1. 環境変数エラー
```
KeyError: 'OPENSEARCH_ENDPOINT'
```
**解決方法**: テスト実行時に必要な環境変数を全て設定
```bash
OPENSEARCH_ENDPOINT="https://test-endpoint.region.aoss.amazonaws.com" S3BUCKET="test-bucket" S3BUCKET_KEY="output/text-with-embedding.json" poetry run pytest test_main.py -v
```

#### 2. OpenSearchモジュールエラー
```
ModuleNotFoundError: No module named 'opensearchpy'
```
**解決方法**: poetry環境で依存関係をインストール
```bash
poetry install
# または個別追加
poetry add opensearch-py
```

#### 3. バルクインデックスのモック問題
**原因**: `opensearchpy.helpers.bulk`のインポートパスが間違っている
**解決方法**: 正しいモジュールパスを指定
```python
# 正しい例
@patch('main.bulk')  # main.pyでfrom opensearchpy.helpers import bulk

# 間違い例
@patch('opensearchpy.helpers.bulk')
```

#### 4. AWS認証関連のエラー
**原因**: boto3セッションのモックが不完全
**解決方法**: セッションとクレデンシャルの両方をモック
```python
mock_session = Mock()
mock_session_class.return_value = mock_session
mock_credentials = Mock()
mock_session.get_credentials.return_value = mock_credentials
```

### デバッグ用コマンド

#### テスト失敗時の詳細確認
```bash
# 失敗したテストの詳細表示
OPENSEARCH_ENDPOINT="https://test-endpoint.region.aoss.amazonaws.com" S3BUCKET="test-bucket" S3BUCKET_KEY="output/text-with-embedding.json" poetry run pytest test_main.py -v --tb=long -s

# 特定のテストのみデバッグ実行
OPENSEARCH_ENDPOINT="https://test-endpoint.region.aoss.amazonaws.com" S3BUCKET="test-bucket" S3BUCKET_KEY="output/text-with-embedding.json" poetry run pytest test_main.py::TestIndexDocumentsBulk::test_index_documents_bulk_success -v -s --pdb
```

#### モックの呼び出し確認
```python
# テスト内でモックの呼び出しを確認
print(f"bulk call count: {mock_bulk.call_count}")
print(f"bulk call args: {mock_bulk.call_args}")

# アクションデータの詳細確認
actions = mock_bulk.call_args[0][1]
print(f"Actions: {json.dumps(actions, indent=2)}")
```

## パフォーマンス考慮事項

### テスト高速化の工夫
1. **実際のOpenSearch接続を回避**: クライアント作成をモック
2. **S3操作回避**: ダウンロード操作をモック
3. **ファイルI/O回避**: `mock_open`で実際のファイル読み込みを回避
4. **最小限のデータ**: 大きなembeddingベクトルは使用しない

### メモリ効率
- embedding ベクトルは最小限のサイズ（5次元）を使用
- 大量ドキュメントのテストは避ける
- 不要なデータ生成を避ける

### OpenSearch固有の考慮事項
- バルクインデックスのレスポンス構造を正確にモック
- 部分失敗時のエラー情報構造を適切に設定
- タイムアウト設定のテスト

## CI/CD での実行

### GitHub Actions での設定例
```yaml
- name: Run vector_database tests
  run: |
    cd Terraform/AWS/Resources/RAG/be/src/vector_database
    OPENSEARCH_ENDPOINT="https://test-endpoint.region.aoss.amazonaws.com" S3BUCKET="test-bucket" S3BUCKET_KEY="output/text-with-embedding.json" poetry run pytest test_main.py -v
```

### テスト結果の保存
```bash
# JUnit XML形式でテスト結果を出力
OPENSEARCH_ENDPOINT="https://test-endpoint.region.aoss.amazonaws.com" S3BUCKET="test-bucket" S3BUCKET_KEY="output/text-with-embedding.json" poetry run pytest test_main.py --junit-xml=test-results.xml
```

### 並列テスト実行
```bash
# pytest-xdistを使用した並列実行
poetry add pytest-xdist --group dev
OPENSEARCH_ENDPOINT="https://test-endpoint.region.aoss.amazonaws.com" S3BUCKET="test-bucket" S3BUCKET_KEY="output/text-with-embedding.json" poetry run pytest test_main.py -n auto
```

## 改善提案

### テストカバレッジ向上
1. **大量データ処理**: 数千件のドキュメントでの性能テスト
2. **ネットワークエラー**: OpenSearch接続タイムアウトのテスト
3. **インデックスエラー**: 様々なOpenSearchエラーのテスト
4. **データ検証**: embedding次元数の不一致などのテスト

### パフォーマンステスト
1. **バルクサイズ最適化**: 最適なバッチサイズの測定
2. **メモリ使用量**: 大きなembeddingデータでのメモリ効率
3. **インデックス速度**: ドキュメント数に対するインデックス速度

### セキュリティテスト
1. **認証エラー**: AWS認証情報の不正・期限切れ
2. **アクセス制御**: OpenSearchへのアクセス権限テスト
3. **データ検証**: 不正なembeddingデータの処理

このテストスイートにより、OpenSearchへのベクターデータ投入処理の信頼性と効率性を確保できます。