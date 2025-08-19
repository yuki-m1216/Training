# 推奨コマンド

## Terraform操作
すべての設定に標準的なTerraformコマンドが適用されます：
```bash
terraform init      # Terraform初期化
terraform plan       # 実行プランの確認
terraform apply      # インフラストラクチャのデプロイ
terraform destroy    # リソースの削除
```

## AWS関連
```bash
# AWS認証情報設定（プロファイル方式推奨）
export AWS_PROFILE="your-profile"

# 直接認証情報（非推奨、テスト用のみ）
export TF_VAR_access_key="AKIAXXXXXXXXXXXXXXXXXX"
export TF_VAR_secret_key="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

# S3ステートバケット作成
BUCKET_NAME=s3-terraform-state-y-mitsuyama
REGION=ap-northeast-1
aws s3api create-bucket --create-bucket-configuration LocationConstraint=$REGION --bucket $BUCKET_NAME
aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled

# DynamoDBステートロック作成
aws dynamodb create-table \
    --table-name terrform-state \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
    --table-class STANDARD \
    --deletion-protection-enabled \
    --tags Key=Name,Value=terrform-state
```

## Lambda関数開発（TypeScript）
```bash
# Lambda関数ディレクトリで実行
npm run build        # TypeScript Lambda関数をビルド
npm start           # webpackを使用した開発サーバー
```

## Next.jsフロントエンド開発
```bash
# Next.jsプロジェクトディレクトリで実行
npm run dev         # turbopackを使用した開発サーバー
npm run build       # プロダクションビルド
npm run start       # プロダクションサーバー
npm run lint        # ESLintチェック
```

## Python環境セットアップ（RAGバックエンド）
```bash
# Pythonバージョンを設定
pyenv local 3.10.5

# Poetry環境を初期化
poetry init
poetry install --no-root

# 仮想環境をアクティブ化
poetry shell

# Lambdaレイヤーをビルド
poetry run pip install --upgrade -r requirements.txt -t ./layer/python
```

## New Relic設定
```bash
export NEW_RELIC_ACCOUNT_ID="<your-account-id>"
export NEW_RELIC_API_KEY="<your-api-key>"  
export TF_VAR_NEW_RELIC_ACCOUNT_ID="<your-account-id>"
```

## 基本的なLinuxコマンド
```bash
ls                  # ファイル一覧表示
cd <directory>      # ディレクトリ移動
grep <pattern>      # テキスト検索
find <path> -name   # ファイル検索
git status          # Gitステータス確認
git add .           # 変更をステージング
git commit -m ""    # コミット作成
```