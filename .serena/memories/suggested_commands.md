# 推奨コマンド

## Terraform操作
すべての設定に標準的なTerraformコマンドが適用されます：
```bash
terraform init      # 初期化
terraform plan       # 実行計画の確認
terraform apply      # リソース作成・変更
terraform destroy    # リソース削除
```

## Lambda関数開発

### TypeScriptを使用するLambda関数
```bash
npm run build        # TypeScript Lambda関数をビルド
npm start            # webpackを使用した開発サーバー
```

### Next.jsフロントエンド (AWS/Resources/RAG/fe/src/)
```bash
npm run dev          # turbopackを使用した開発サーバー
npm run build        # プロダクションビルド
npm run start        # プロダクションサーバー
npm run lint         # ESLintチェック
```

## Python環境セットアップ (RAGバックエンド)
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

## 環境設定コマンド

### AWS認証情報設定
```bash
# 直接認証情報（注意：本番環境では使用しない）
export TF_VAR_access_key="AKIAXXXXXXXXXXXXXXXXXX"
export TF_VAR_secret_key="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

# またはAWSプロファイルを使用（推奨）
export AWS_PROFILE="your-profile"
```

### New Relic設定
```bash
export NEW_RELIC_ACCOUNT_ID="<your-account-id>"
export NEW_RELIC_API_KEY="<your-api-key>"
export TF_VAR_NEW_RELIC_ACCOUNT_ID="<your-account-id>"
```

### Terraformステート管理用S3バケット作成
```bash
BUCKET_NAME=s3-terraform-state-y-mitsuyama
REGION=ap-northeast-1
aws s3api create-bucket --create-bucket-configuration LocationConstraint=$REGION --bucket $BUCKET_NAME
aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled
```

## システムユーティリティ (Linux)
```bash
ls                   # ファイル一覧
cd                   # ディレクトリ移動
grep                 # テキスト検索
find                 # ファイル検索
git status           # Git状態確認
git add .            # 変更をステージング
git commit -m "msg"  # コミット
```