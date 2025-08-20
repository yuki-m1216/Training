# Python テスト・pytest 初心者ガイド

## はじめに

このガイドは、RAGシステムのテストコードで使われているPythonテスト・pytestの書き方を初心者向けに解説します。テストコードを読んだり書いたりするための基本的な知識を身につけることができます。

## テストとは何か？

**テスト**とは、作成したコードが期待通りに動作するかを確認するためのコードです。

```python
# テスト対象の関数
def add(a, b):
    return a + b

# テストコード
def test_add():
    result = add(2, 3)
    assert result == 5  # 期待した結果と一致するか確認
```

## pytestの基本

### 1. テストファイルの命名

```
answer_user_query/
├── main.py          # メインコード
└── test_main.py     # テストコード（test_で始める）
```

- テストファイルは`test_`で始める
- テスト関数は`test_`で始める
- テストクラスは`Test`で始める

### 2. 基本的なテスト関数

```python
def test_簡単な例():
    # 1. 準備（Arrange）
    x = 10
    y = 20
    
    # 2. 実行（Act）
    result = x + y
    
    # 3. 検証（Assert）
    assert result == 30
```

### 3. assertの書き方

```python
# 等しいことを確認
assert result == 期待値

# 含まれることを確認
assert "エラー" in error_message

# Trueであることを確認
assert condition is True

# 例外が発生することを確認
with pytest.raises(ValueError):
    raise ValueError("エラー")
```

## テストクラスの書き方

### 基本構造

```python
class TestCalculator:
    """計算機のテスト"""
    
    def test_add(self):
        """足し算のテスト"""
        assert add(2, 3) == 5
    
    def test_subtract(self):
        """引き算のテスト"""
        assert subtract(5, 3) == 2
```

**なぜクラスを使う？**
- 関連するテストをまとめて整理
- 共通の設定を使い回せる
- テストの管理が楽になる

## フィクスチャ（Fixture）

**フィクスチャ**とは、テストで使うデータやオブジェクトを事前に準備する仕組みです。

### 基本的なフィクスチャ

```python
@pytest.fixture
def sample_data():
    """テスト用のサンプルデータ"""
    return {"name": "太郎", "age": 30}

def test_example(sample_data):
    # sample_dataが自動的に渡される
    assert sample_data["name"] == "太郎"
```

### 実際のコードでの例

```python
@pytest.fixture
def sample_documents():
    """テスト用のドキュメントデータ"""
    return [
        {
            "page": 1,
            "text": "AWS Lambda はサーバーレスコンピューティングサービスです。",
            "embedding": [0.1, 0.2, 0.3, 0.4, 0.5]
        }
    ]

def test_process_documents(sample_documents):
    # sample_documentsが自動的に使える
    assert len(sample_documents) == 1
```

## モック（Mock）の基本

**モック**とは、実際のオブジェクトの代わりに使う「偽物」です。

### なぜモックを使う？

```python
# 実際のコード（テストでは困る）
def download_file():
    s3_client.download_file("bucket", "key", "/tmp/file")  # 実際にS3にアクセス
    return "/tmp/file"

# テストしたいのは：
# 1. S3に実際にアクセスせずに
# 2. 高速で
# 3. 確実に動作をテスト
```

### 基本的なMockの使い方

```python
from unittest.mock import Mock

# Mockオブジェクトの作成
mock_client = Mock()

# 戻り値の設定
mock_client.download_file.return_value = None

# メソッドが呼ばれたか確認
mock_client.download_file.assert_called_once()
```

## @patchデコレータ

**@patch**は、実際のオブジェクトを一時的にモックに置き換えるために使います。

### 基本的な使い方

```python
# main.py
import boto3
s3_client = boto3.client("s3")

def download_file():
    s3_client.download_file("bucket", "key", "/tmp/file")

# test_main.py
@patch('main.s3_client')  # main.pyのs3_clientをモックに置換
def test_download_file(mock_s3_client):
    # テスト実行中、s3_clientはmock_s3_clientになる
    download_file()
    
    # モックが呼ばれたか確認
    mock_s3_client.download_file.assert_called_once()
```

### 複数のパッチ

```python
@patch('main.bedrock_client')  # 2番目のパッチ
@patch('main.s3_client')       # 1番目のパッチ
def test_example(mock_s3_client, mock_bedrock_client):
    # 引数の順序は「下から上」（デコレータと逆順）
```

### 環境変数のパッチ

```python
@patch.dict(os.environ, {
    'S3BUCKET': 'test-bucket',
    'S3BUCKET_KEY': 'test-key'
})
def test_with_env_vars():
    # テスト中だけ環境変数が設定される
```

## よく使うモックのパターン

### 1. 戻り値を設定

```python
mock_function.return_value = "期待する戻り値"
```

### 2. 複数回呼び出しで異なる値

```python
mock_function.side_effect = [
    "1回目の戻り値",
    "2回目の戻り値",
    "3回目の戻り値"
]
```

### 3. エラーを発生させる

```python
mock_function.side_effect = Exception("エラーメッセージ")
```

### 4. 条件によって異なる動作

```python
def custom_side_effect(*args, **kwargs):
    if kwargs['type'] == 'A':
        return "Aタイプの結果"
    else:
        return "その他の結果"

mock_function.side_effect = custom_side_effect
```

## ファイルI/Oのモック

### mock_openの使い方

```python
from unittest.mock import mock_open, patch

# ファイル読み込みをモック
@patch('builtins.open', mock_open(read_data='{"key": "value"}'))
def test_load_json():
    # 実際のファイルではなく、指定したデータが読み込まれる
    result = load_json("/tmp/test.json")
    assert result["key"] == "value"
```

## モックの検証方法

### 呼び出し回数の確認

```python
# 1回だけ呼ばれた
mock_function.assert_called_once()

# 指定回数呼ばれた
assert mock_function.call_count == 3

# 呼ばれていない
mock_function.assert_not_called()
```

### 引数の確認

```python
# 最後の呼び出しの引数
mock_function.assert_called_with("期待する引数")

# 最後の呼び出しの引数（キーワード引数含む）
mock_function.assert_called_with(arg1="値1", arg2="値2")

# 特定の呼び出しがあったか
mock_function.assert_any_call("特定の引数")
```

### 詳細な引数確認

```python
# 呼び出し引数を取得
call_args = mock_function.call_args
print(call_args)  # call('引数1', keyword='値')

# 位置引数
args = call_args[0]
print(args[0])  # 1番目の引数

# キーワード引数
kwargs = call_args[1]
print(kwargs['keyword'])  # キーワード引数の値
```

## エラーテストの書き方

### 例外が発生することをテスト

```python
def test_error_case():
    with pytest.raises(ValueError, match="期待するエラーメッセージ"):
        # エラーが発生するコードを実行
        raise ValueError("期待するエラーメッセージ")
```

### AWSのエラーをシミュレート

```python
from botocore.exceptions import ClientError

@patch('main.s3_client')
def test_s3_error(mock_s3_client):
    # S3エラーをシミュレート
    mock_s3_client.download_file.side_effect = ClientError(
        error_response={'Error': {'Code': 'NoSuchKey'}},
        operation_name='download_file'
    )
    
    with pytest.raises(ClientError):
        download_file()
```

## 実際のコード例で学ぶ

### シンプルなテスト例

```python
# テスト対象の関数
def invoke_bedrock_embedding(client, model_id, text):
    response = client.invoke_model(
        modelId=model_id,
        body=json.dumps({"inputText": text})
    )
    return json.loads(response['body'].read())['embedding']

# テストコード
@patch('main.bedrock_client')
def test_invoke_bedrock_embedding(mock_bedrock_client):
    # 1. モックの設定
    mock_response = {'body': Mock()}
    mock_response['body'].read.return_value = json.dumps({
        'embedding': [0.1, 0.2, 0.3]
    }).encode()
    mock_bedrock_client.invoke_model.return_value = mock_response
    
    # 2. テスト実行
    result = invoke_bedrock_embedding(
        mock_bedrock_client, 
        "test-model", 
        "テストテキスト"
    )
    
    # 3. 検証
    assert result == [0.1, 0.2, 0.3]
    mock_bedrock_client.invoke_model.assert_called_once()
```

## テストの実行方法

### 基本的な実行

```bash
# 全てのテストを実行
poetry run pytest

# 特定のファイルのテストを実行
poetry run pytest test_main.py

# 詳細表示
poetry run pytest -v

# 特定のクラスのテストのみ
poetry run pytest test_main.py::TestClassName -v

# 特定のメソッドのテストのみ
poetry run pytest test_main.py::TestClassName::test_method_name -v
```

### 環境変数付きの実行

```bash
OPENSEARCH_ENDPOINT="https://test.com" poetry run pytest test_main.py -v
```

## デバッグのコツ

### print文を使ったデバッグ

```python
def test_debug_example(mock_client):
    print(f"モックの呼び出し回数: {mock_client.method.call_count}")
    print(f"呼び出し引数: {mock_client.method.call_args}")
    
    # -s オプションでprintが表示される
    # poetry run pytest test_main.py -v -s
```

### pdbを使ったデバッグ

```bash
# テスト実行中にデバッガーで停止
poetry run pytest test_main.py::test_name -v --pdb
```

## よくある間違いと対処法

### 1. パッチの対象が間違っている

```python
# 間違い - 元のモジュールを指定
@patch('boto3.client')

# 正しい - 使用している場所を指定
@patch('main.s3_client')
```

### 2. 引数の順序が間違っている

```python
# 間違い
@patch('main.client_a')
@patch('main.client_b')
def test(mock_a, mock_b):  # 順序が間違い

# 正しい
@patch('main.client_a')
@patch('main.client_b')
def test(mock_b, mock_a):  # デコレータと逆順
```

### 3. モックの設定忘れ

```python
# 間違い - 戻り値を設定していない
mock_function()  # None が返される

# 正しい - 戻り値を設定
mock_function.return_value = "期待する値"
result = mock_function()  # "期待する値" が返される
```

## まとめ

### テストを書く時の手順

1. **何をテストするか決める**（関数の正常動作、エラー処理など）
2. **外部依存を特定する**（AWS、ファイル、ネットワークなど）
3. **モックを設定する**（@patchでモックに置換）
4. **テストデータを準備する**（フィクスチャやサンプルデータ）
5. **実行と検証**（assert文で期待値をチェック）

### 良いテストの特徴

- **高速**：モックを使って外部依存を排除
- **独立**：他のテストに影響されない
- **再現可能**：何度実行しても同じ結果
- **わかりやすい**：何をテストしているかが明確

### 次のステップ

1. 既存のテストコードを読んで理解する
2. 簡単な関数から自分でテストを書いてみる
3. モックを使ったテストに挑戦する
4. エラーケースのテストも書いてみる

このガイドを参考に、少しずつテストコードに慣れていきましょう！