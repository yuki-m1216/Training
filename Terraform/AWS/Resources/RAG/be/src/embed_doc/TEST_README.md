# Embed Doc - テストドキュメント

## 概要

このドキュメントは`embed_doc`のLambda関数に対するpytestテストの詳細説明です。このLambda関数は、S3に保存されたPDFファイルをダウンロードし、テキスト抽出、チャンク分割、embedding生成、最終的にJSONファイルとしてS3にアップロードする処理を行います。

## 機能概要

### 主要な処理フロー
1. **PDFダウンロード**: S3バケットから指定されたPDFファイルをダウンロード
2. **テキスト抽出**: Langchain PyPDFLoaderでPDFからテキストを抽出
3. **テキスト分割**: CharacterTextSplitterで8192文字単位にチャンク分割
4. **ベクトル化**: AWS Bedrock Titan Embeddings でテキストをベクトル化
5. **JSONアップロード**: テキストとembeddingをペアにしたJSONをS3にアップロード

## テストファイル構成

### ファイル構造
```
embed_doc/
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
- **langchain**: ドキュメント処理とテキスト分割
- **langchain-community**: PyPDFLoaderを含むコミュニティパッケージ
- **pypdf**: PDFファイル処理
- **boto3**: AWS SDK

## テスト実行方法

### 基本実行
```bash
# ディレクトリ移動
cd /home/linux/git/Terraform/AWS/Resources/RAG/be/src/embed_doc

# 環境変数を設定してテスト実行
S3BUCKET="test-bucket" S3BUCKET_KEY="test-document.pdf" poetry run pytest test_main.py -v
```

### その他の実行オプション

#### 特定のテストクラスのみ実行
```bash
# TestDownloadPdfクラスのみ
S3BUCKET="test-bucket" S3BUCKET_KEY="test-document.pdf" poetry run pytest test_main.py::TestDownloadPdf -v

# TestLambdaHandlerクラスのみ
S3BUCKET="test-bucket" S3BUCKET_KEY="test-document.pdf" poetry run pytest test_main.py::TestLambdaHandler -v
```

#### 特定のテストメソッドのみ実行
```bash
# PDF処理のテストのみ
S3BUCKET="test-bucket" S3BUCKET_KEY="test-document.pdf" poetry run pytest test_main.py::TestPdfToText::test_pdf_to_text_success -v
```

#### 詳細出力付き実行
```bash
# より詳細な出力
S3BUCKET="test-bucket" S3BUCKET_KEY="test-document.pdf" poetry run pytest test_main.py -v -s

# 失敗時に詳細表示
S3BUCKET="test-bucket" S3BUCKET_KEY="test-document.pdf" poetry run pytest test_main.py -v --tb=long
```

#### カバレッジ付きテスト実行
```bash
# カバレッジレポート付き（要pytest-cov）
poetry add pytest-cov --group dev
S3BUCKET="test-bucket" S3BUCKET_KEY="test-document.pdf" poetry run pytest test_main.py --cov=main --cov-report=html -v
```

### 依存関係

#### 現在のpyproject.toml設定例
```toml
[project]
dependencies = [
    "langchain (>=0.3.21,<0.4.0)",
    "boto3 (>=1.37.17,<2.0.0)",
    "langchain-community (>=0.3.20,<0.4.0)",
    "pypdf (>=5.4.0,<6.0.0)",
    "h11 (>=0.16.0,<0.17.0)"
]

[tool.poetry.group.dev.dependencies]
pytest = "^8.4.1"
```

## テストクラス詳細

### 1. TestDownloadPdf クラス
**目的**: `download_pdf`関数のテスト

#### test_download_pdf_success
```python
def test_download_pdf_success(self, mock_s3_client):
```
- **テスト内容**: S3からPDFファイルの正常ダウンロード
- **検証項目**:
  - 正しいローカルパス（`/tmp/document.pdf`）が返されること
  - S3クライアントの`download_file`が正しい引数で呼ばれること
  - 環境変数（`S3BUCKET`、`S3BUCKET_KEY`）が正しく使用されること

#### test_download_pdf_s3_error
- **テスト内容**: S3ダウンロード時のエラーハンドリング
- **検証項目**: `ClientError`（NoSuchKey）が適切に発生すること

**重要なポイント**:
```python
# 環境変数をテスト内で設定
@patch.dict(os.environ, {
    'S3BUCKET': 'test-bucket',
    'S3BUCKET_KEY': 'test-document.pdf'
})
```

### 2. TestPdfToText クラス
**目的**: `pdf_to_text`関数のテスト

#### test_pdf_to_text_success
- **テスト内容**: PDFからテキスト抽出と分割の正常処理
- **モック対象**:
  - `PyPDFLoader`: PDF読み込み
  - `CharacterTextSplitter`: テキスト分割（chunk_size=8192）
- **検証項目**:
  - PyPDFLoaderが正しいパスで初期化されること
  - `load_and_split()`が呼ばれること
  - TextSplitterが正しいチャンクサイズで初期化されること
  - `split_documents()`が呼ばれること

#### test_pdf_to_text_loader_error
- **テスト内容**: PDFローダーでのエラー処理
- **検証項目**: PDF読み込みエラー時の例外処理

**Langchainのモック戦略**:
```python
@patch('main.PyPDFLoader')
@patch('main.CharacterTextSplitter')
def test_pdf_to_text_success(self, mock_splitter_class, mock_loader_class):
    # クラスのインスタンス生成をモック
    mock_loader = Mock()
    mock_loader_class.return_value = mock_loader
    
    # メソッドの戻り値を設定
    mock_loader.load_and_split.return_value = mock_pages
```

### 3. TestInvokeBedrockEmbedding クラス
**目的**: `invoke_bedrock_embedding`関数のテスト

#### test_invoke_bedrock_embedding_success
- **テスト内容**: Bedrock Titan Embeddings APIの正常な呼び出し
- **検証項目**:
  - 正しいembeddingベクトルが返されること
  - 正しいモデルID（`amazon.titan-embed-text-v2:0`）が使用されること
  - リクエストボディの内容確認（inputText、dimensions、normalize）

#### test_invoke_bedrock_embedding_api_error
- **テスト内容**: Bedrock APIエラー時の例外処理
- **検証項目**: `ClientError`が適切に発生すること

### 4. TestProcessAndUploadText クラス
**目的**: `process_and_upload_text`関数のテスト

#### test_process_and_upload_text_success
- **テスト内容**: テキストの embedding 生成とS3アップロードの正常処理
- **モック対象**:
  - `invoke_bedrock_embedding`: embedding生成
  - `s3_client.upload_file`: S3アップロード
  - `builtins.open`: ファイル書き込み
- **検証項目**:
  - 各ドキュメントに対してembedding生成が呼ばれること
  - 正しいJSON構造でファイルが書き込まれること
  - S3に正しいパスでアップロードされること

**JSON出力構造の検証**:
```python
# ファイルに書き込まれた内容の確認
written_content = mock_file().write.call_args[0][0]
written_data = json.loads(written_content)

# データ構造の確認
assert written_data[0]['page'] == 1
assert written_data[0]['text'] == "期待するテキスト"
assert written_data[0]['embedding'] == [0.1, 0.2, 0.3, 0.4, 0.5]
```

#### test_process_and_upload_text_s3_upload_error
- **テスト内容**: S3アップロード時のエラー処理
- **検証項目**: アップロードエラー時の例外処理

### 5. TestLambdaHandler クラス
**目的**: `lambda_handler`関数の包括的テスト

#### test_lambda_handler_success
- **テスト内容**: Lambda関数全体の正常実行
- **モック対象**: 全ての主要関数をモック
- **検証項目**:
  - 正しい順序で関数が呼ばれること
  - 正しいレスポンス構造が返されること
  - 成功メッセージが含まれること

**処理順序の検証**:
1. `download_pdf()` → 2. `pdf_to_text()` → 3. `process_and_upload_text()`

#### test_lambda_handler_download_error
- **テスト内容**: PDFダウンロードエラー時の処理
- **検証項目**: エラーが適切に伝播されること

#### test_lambda_handler_pdf_processing_error
- **テスト内容**: PDF処理エラー時の処理
- **検証項目**: PDF処理エラーが適切に伝播されること

### 6. TestIntegration クラス
**目的**: 統合テスト（全体パイプライン）

#### test_full_pipeline_mock
- **テスト内容**: 実際のライブラリを使わずに全フローをテスト
- **モック戦略**:
  - Langchainライブラリ全体をモック
  - AWS SDKをモック
  - ファイルI/Oをモック
- **検証項目**: 全体フローが期待通りに動作すること

## フィクスチャ（Fixture）

### mock_s3_client / mock_bedrock_client
```python
@pytest.fixture
def mock_s3_client():
    mock_client = Mock()
    return mock_client
```
- **用途**: AWS SDKクライアントのモック

### sample_text_docs
```python
@pytest.fixture
def sample_text_docs():
    mock_doc1 = Mock()
    mock_doc1.page_content = "AWS Lambda はサーバーレスコンピューティングサービスです。"
    return [mock_doc1, mock_doc2]
```
- **用途**: Langchainドキュメントオブジェクトのモック
- **構造**: `page_content`属性を持つオブジェクト

### sample_embedding
```python
@pytest.fixture
def sample_embedding():
    return [0.1, 0.2, 0.3, 0.4, 0.5]
```
- **用途**: embedding ベクトルのサンプルデータ

## モッキング戦略

### 外部ライブラリの置換

#### Langchain関連
```python
@patch('main.PyPDFLoader')
@patch('main.CharacterTextSplitter')
```
- **PyPDFLoader**: PDF読み込みライブラリ
- **CharacterTextSplitter**: テキスト分割ライブラリ

#### AWS SDK
```python
@patch('main.s3_client')
@patch('main.bedrock_client')
```
- **s3_client**: S3操作（ダウンロード、アップロード）
- **bedrock_client**: Bedrock API（embedding生成）

#### ファイルI/O
```python
@patch('builtins.open', new_callable=mock_open)
```
- **ファイル書き込み**: 実際のファイル作成を回避

### side_effectの活用

#### 複数ドキュメントのembedding生成
```python
mock_invoke_bedrock.side_effect = [
    [0.1, 0.2, 0.3, 0.4, 0.5],  # 1番目のドキュメント用
    [0.6, 0.7, 0.8, 0.9, 1.0]   # 2番目のドキュメント用
]
```

## トラブルシューティング

### よくある問題と解決方法

#### 1. 環境変数エラー
```
KeyError: 'S3BUCKET'
```
**解決方法**: テスト実行時に環境変数を設定
```bash
S3BUCKET="test-bucket" S3BUCKET_KEY="test-document.pdf" poetry run pytest test_main.py -v
```

#### 2. Langchainモジュールエラー
```
ModuleNotFoundError: No module named 'langchain'
```
**解決方法**: poetry環境で依存関係をインストール
```bash
poetry install
# または個別追加
poetry add langchain langchain-community pypdf
```

#### 3. モックが効かない問題
**原因**: インポートパスの違い
**解決方法**: 正しいモジュールパスを指定
```python
# 正しい例
@patch('main.PyPDFLoader')  # main.pyでインポートしている場合

# 間違い例
@patch('langchain_community.document_loaders.PyPDFLoader')
```

#### 4. ファイルI/Oのモック問題
**原因**: `open()`関数のモックが正しく設定されていない
**解決方法**: `mock_open`を適切に使用
```python
with patch('builtins.open', mock_open(read_data=json_content)):
    # テストコード
```

### デバッグ用コマンド

#### テスト失敗時の詳細確認
```bash
# 失敗したテストの詳細表示
S3BUCKET="test-bucket" S3BUCKET_KEY="test-document.pdf" poetry run pytest test_main.py -v --tb=long -s

# 特定のテストのみデバッグ実行
S3BUCKET="test-bucket" S3BUCKET_KEY="test-document.pdf" poetry run pytest test_main.py::TestPdfToText::test_pdf_to_text_success -v -s --pdb
```

#### モックの呼び出し確認
```python
# テスト内でモックの呼び出しを確認
print(f"PyPDFLoader call count: {mock_loader_class.call_count}")
print(f"load_and_split call args: {mock_loader.load_and_split.call_args}")
```

## パフォーマンス考慮事項

### テスト高速化の工夫
1. **実際のPDF処理を回避**: Langchainライブラリをモック
2. **ファイルI/O回避**: `mock_open`で実際のファイル作成を回避
3. **AWS API呼び出し回避**: boto3クライアントをモック
4. **最小限のデータ**: 大きなembeddingベクトルは使用しない

### メモリ効率
- 大きなPDFファイルのロードを回避
- embedding ベクトルは最小限のサイズ（5次元）を使用
- 不要なテストデータ生成を避ける

## CI/CD での実行

### GitHub Actions での設定例
```yaml
- name: Run embed_doc tests
  run: |
    cd AWS/Resources/RAG/be/src/embed_doc
    S3BUCKET="test-bucket" S3BUCKET_KEY="test-document.pdf" poetry run pytest test_main.py -v
```

### テスト結果の保存
```bash
# JUnit XML形式でテスト結果を出力
S3BUCKET="test-bucket" S3BUCKET_KEY="test-document.pdf" poetry run pytest test_main.py --junit-xml=test-results.xml
```

### 並列テスト実行
```bash
# pytest-xdistを使用した並列実行
poetry add pytest-xdist --group dev
S3BUCKET="test-bucket" S3BUCKET_KEY="test-document.pdf" poetry run pytest test_main.py -n auto
```

## 改善提案

### テストカバレッジ向上
1. **大きなPDFファイル**: メモリ効率のテスト
2. **異なるPDFフォーマット**: 様々なPDF形式への対応
3. **エラーリカバリ**: 部分的な失敗時の処理
4. **境界値テスト**: 空のPDF、最大サイズPDFの処理

### パフォーマンステスト
1. **処理時間測定**: 各段階での実行時間
2. **メモリ使用量**: 大きなドキュメント処理時のメモリ効率
3. **並列処理**: 複数ドキュメントの同時処理

このテストスイートにより、PDF処理からembedding生成までのパイプラインの信頼性を確保できます。