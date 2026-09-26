# CLAUDE.md

このファイルは、このリポジトリでコードを扱う際のClaude Code (claude.ai/code)へのガイダンスを提供します。

## 開発コマンド

### Python環境セットアップ（RAGバックエンド）
RAG実装のPython Lambda関数の場合：
```bash
# Pythonバージョンを設定
pyenv local 3.10.5

# Poetry環境を初期化
poetry init
poetry install --no-root

# 仮想環境をアクティブ化（PowerShell）
Invoke-Expression (poetry env activate)

# Lambdaレイヤーをビルド
poetry run pip install --upgrade -r requirements.txt -t ./layer/python
```

## 環境設定
### New Relic設定
```bash
export NEW_RELIC_ACCOUNT_ID="<your-account-id>"
export NEW_RELIC_API_KEY="<your-api-key>"
export TF_VAR_NEW_RELIC_ACCOUNT_ID="<your-account-id>"
```

### Terraformステート管理
このリポジトリはステート管理にS3バックエンドを使用します。ステートバケットを設定：
```bash
BUCKET_NAME=s3-terraform-state-y-mitsuyama
REGION=ap-northeast-1
aws s3api create-bucket --create-bucket-configuration LocationConstraint=$REGION --bucket $BUCKET_NAME
aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled
```

## 主要パターン
### RAG実装のデプロイ順序
RAG（Retrieval-Augmented Generation）システムの場合、この特定の順序でデプロイします：
1. `embed_doc` - ドキュメント埋め込みサービス
2. `vector_database` - ベクターデータベースセットアップ
3. `answer_user_query` - クエリ処理サービス
4. `fe` - フロントエンドアプリケーション

## コード規約

- リソースにはハイフンを使用した一貫した命名を使用（例：`synthetics-test-api`）
- AWSリソース命名規約に従う
- `versions.tf`に適切なバージョン制約を含める
- 外部参照には`data.tf`でデータソースを使用
- 説明と型を含めて`variables.tf`に変数を保持
- `outputs.tf`で重要な値をエクスポート