# CLAUDE.md

このファイルは、このリポジトリでコードを扱う際のClaude Code (claude.ai/code)へのガイダンスを提供します。

## プロジェクト概要

このリポジトリはAWSとNew Relicインフラストラクチャ設定の包括的な例を含むTerraform練習用リポジトリです。TypeScript/JavaScriptを使用したいくつかのLambda関数とNext.jsフロントエンドアプリケーションが含まれています。

## アーキテクチャ

リポジトリは2つの主要なプロバイダーセクションに整理されています：

### AWSインフラストラクチャ (`/Terraform/AWS/`)
- **Resources**: AWSサービス別に整理された完全なインフラストラクチャ例（ACM、API Gateway、Lambda、ECS、VPCなど）
- **Modules**: 一般的なAWSサービス用の再利用可能なTerraformモジュール
- **主要機能**:
  - LambdaとOpenAPI仕様を統合したAPI Gateway
  - CloudFrontディストリビューションを使用したECSコンテナ化アプリケーション
  - OpenSearchとBedrockを使用したRAG（Retrieval-Augmented Generation）実装
  - 様々な用途のLambda関数（コンソールログインアラーム、synthetics）
  - VPC、セキュリティグループ、ルーティングを含む完全なネットワークセットアップ

### New Relicモニタリング (`/Terraform/NewRelic/`)
- **Resources**: New Relicアラート、AWS統合、ログ転送、synthetics
- **Modules**: アラート、ワークフロー、統合用の再利用可能なコンポーネント

## 開発コマンド

### Terraform操作
すべての設定に標準的なTerraformコマンドが適用されます：
```bash
terraform init
terraform plan
terraform apply
terraform destroy
```

### Lambda関数開発
TypeScriptを使用するLambda関数の場合（例：`Terraform/AWS/Resources/APIGateway/synthetics_test_api/`）：
```bash
npm run build      # TypeScript Lambda関数をビルド
npm start          # webpackを使用した開発サーバー
```

Next.jsフロントエンドの場合（`Terraform/AWS/Resources/RAG/fe/src/`）：
```bash
npm run dev        # turbopackを使用した開発サーバー
npm run build      # プロダクションビルド
npm run start      # プロダクションサーバー
npm run lint       # ESLintチェック
```

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

### AWS認証情報
以下のいずれかを使用してAWS認証情報を設定：
```bash
# 直接認証情報
export TF_VAR_access_key="AKIAXXXXXXXXXXXXXXXXXX"
export TF_VAR_secret_key="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

# またはAWSプロファイルを使用
export AWS_PROFILE="your-profile"
```

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

### モジュール使用法
すべてのAWSリソースはローカルモジュールを使用した一貫したパターンに従います：
- `/Terraform/AWS/modules/`でのモジュール定義
- `/Terraform/AWS/Resources/`でのリソース実装
- 標準ファイル構造：`main.tf`、`variables.tf`、`outputs.tf`、`versions.tf`、`provider.tf`

### Lambda関数構造
Lambda関数は通常以下を含みます：
- `main.tf` - Lambdaモジュールを使用したTerraform設定
- `lambda/src/` - ソースコードディレクトリ
- `package.json` - Node.js依存関係とビルドスクリプト
- `tsconfig.json` - TypeScript設定
- `webpack.config.js` - パッケージング用のビルド設定

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