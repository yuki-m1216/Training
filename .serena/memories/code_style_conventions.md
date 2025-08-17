# コードスタイルと規約

## Terraform規約
- **ファイル構造**: 標準的なTerraformファイル構造を使用
  - `main.tf` - メインリソース定義
  - `variables.tf` - 変数定義
  - `outputs.tf` - 出力値定義
  - `versions.tf` - プロバイダーバージョン制約
  - `provider.tf` - プロバイダー設定
- **命名規約**: ハイフンを使用した一貫した命名（例：`synthetics-test-api`）
- **モジュール化**: `/AWS/modules/`でのモジュール定義、`/AWS/Resources/`でのリソース実装
- **外部参照**: `data.tf`でデータソースを使用

## TypeScript/JavaScript規約
- **パッケージ管理**: npm使用
- **ビルドツール**: webpack、turbopack（Next.js）
- **Lambda関数構造**:
  - `lambda/src/` - ソースコードディレクトリ
  - `package.json` - 依存関係とビルドスクリプト
  - `tsconfig.json` - TypeScript設定
  - `webpack.config.js` - パッケージング用ビルド設定

## Python規約
- **パッケージ管理**: Poetry推奨
- **Pythonバージョン**: 3.10.5
- **依存関係**: requirements.txt使用
- **主要ライブラリ**: LangChain、boto3

## Next.js規約
- **React**: Version 19
- **Next.js**: Version 15.2.4
- **スタイリング**: Tailwind CSS v4
- **リンティング**: ESLint with Next.js config
- **TypeScript**: 厳密な型チェック

## ディレクトリ構造パターン
- **Lambda関数**: `AWS/Resources/{Service}/{function-name}/`
- **モジュール**: `AWS/modules/{service}/`
- **フロントエンド**: `AWS/Resources/RAG/fe/src/`
- **バックエンド**: `AWS/Resources/RAG/be/src/{service}/`

## セキュリティ規約
- AWS認証情報はコードにハードコーディングしない
- 環境変数またはAWSプロファイルを使用
- 最小権限の原則を適用

## Git規約
- `.gitignore`でTerraformステートファイル、node_modules、Python cache除外
- Lambda関数のdistディレクトリ除外