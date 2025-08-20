# コードスタイルと規約

## Terraform規約

### ファイル構造
すべてのTerraformリソースは一貫したパターンに従います：
- **標準ファイル構造**: `main.tf`、`variables.tf`、`outputs.tf`、`versions.tf`、`provider.tf`
- **追加ファイル**: `data.tf`（外部参照用）、`locals.tf`（ローカル値）、`iam.tf`（IAM関連）

### 命名規約
- **リソース命名**: ハイフンを使用した一貫した命名（例：`synthetics-test-api`）
- **AWSリソース命名規約**: AWS標準に準拠
- **変数名**: スネークケース使用

### コード組織
- **モジュール構造**: `/AWS/modules/`でのモジュール定義、`/AWS/Resources/`でのリソース実装
- **プロバイダー**: `provider.tf`でプロバイダー設定
- **バージョン制約**: `versions.tf`に適切なバージョン制約を含める
- **変数管理**: `variables.tf`に説明と型を含める
- **出力**: `outputs.tf`で重要な値をエクスポート

### ベストプラクティス
- 外部参照には`data.tf`でデータソースを使用
- リソース間の依存関係を明示
- 適切なタグ付けの実施

## TypeScript/JavaScript規約

### Lambda関数
- **構造**: `main.tf`（Terraform設定）、`lambda/src/`（ソースコード）
- **ビルド**: webpack使用、`webpack.config.js`でパッケージング設定
- **型定義**: `@types/aws-lambda`使用
- **設定ファイル**: `tsconfig.json`、`package.json`

### Next.js
- **バージョン**: Next.js 15.2.4、React 19使用
- **開発**: Turbopackによる高速開発サーバー
- **スタイリング**: TailwindCSS v4使用
- **型安全性**: TypeScript厳格モード

## Python規約

### RAGシステム
- **パッケージ管理**: Poetry使用
- **依存関係**: `requirements.txt`でLambda用依存関係管理
- **主要ライブラリ**: langchain、pypdf使用
- **Pythonバージョン**: pyenvで3.10.5指定（RAGシステム用）

## ディレクトリ構造規約

### AWS Resources
```
AWS/Resources/[Service]/[Implementation]/
├── main.tf          # メインTerraform設定
├── variables.tf     # 変数定義
├── outputs.tf       # 出力値
├── provider.tf      # プロバイダー設定
├── versions.tf      # バージョン制約
├── data.tf          # データソース（必要に応じて）
├── locals.tf        # ローカル値（必要に応じて）
└── lambda/src/      # Lambda関数ソース（該当する場合）
```

### Lambda Function Structure  
```
[lambda-function]/
├── main.tf
├── package.json
├── tsconfig.json
├── webpack.config.js
└── lambda/
    └── src/
        └── index.ts
```

## セキュリティ規約
- **認証情報**: コード内にハードコーディング禁止
- **環境変数**: AWS_PROFILE使用推奨
- **権限**: 最小権限の原則を適用
- **秘匿情報**: .gitignoreで適切に除外