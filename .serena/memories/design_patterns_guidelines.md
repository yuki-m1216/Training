# 設計パターンとガイドライン

## Terraformアーキテクチャパターン

### モジュール設計
- **再利用可能なモジュール**: `/AWS/modules/`に配置
- **具体的な実装**: `/AWS/Resources/`に配置
- **標準ファイル構成**: main.tf、variables.tf、outputs.tf、versions.tf、provider.tf

### ステート管理
- **リモートバックエンド**: S3を使用したステート管理
- **ステートロック**: DynamoDBを使用（オプション）
- **バージョニング**: S3バケットでバージョニング有効

## Lambda関数設計パターン

### TypeScript Lambda
- **ディレクトリ構造**:
  ```
  {function-name}/
  ├── lambda/
  │   └── src/
  │       ├── index.ts
  │       └── models/
  ├── main.tf
  ├── package.json
  ├── tsconfig.json
  └── webpack.config.js
  ```
- **型定義**: aws-lambdaの型を使用
- **モデル分離**: models/ディレクトリで型定義を分離

### Python Lambda (RAGシステム)
- **ディレクトリ構造**:
  ```
  {service-name}/
  ├── main.py
  ├── test_main.py
  ├── requirements.txt
  └── layer/
      └── python/
  ```
- **依存関係管理**: requirements.txtでLambdaレイヤー用依存関係管理
- **テスト**: test_main.pyでテストコード配置

## API設計パターン

### API Gateway統合
- OpenAPI仕様との統合
- Lambdaプロキシ統合の使用
- CORS設定の標準化

### RESTful API
- リソースベースのURL設計
- 適切なHTTPメソッド使用
- エラーハンドリングの統一

## フロントエンド設計パターン

### Next.js構造
- **App Router**: 最新のNext.js App Routerを使用
- **TypeScript**: 厳密な型チェック
- **Tailwind CSS**: ユーティリティファーストCSS
- **ESLint**: Next.js推奨設定

## RAGシステム設計パターン

### マイクロサービス分離
1. **embed_doc**: ドキュメント処理・埋め込み生成
2. **vector_database**: ベクターデータベース管理
3. **answer_user_query**: クエリ処理・回答生成
4. **fe**: ユーザーインターフェース

### データフロー
1. PDFドキュメント → S3
2. embed_doc → ドキュメント分割・埋め込み
3. vector_database → ベクター保存
4. answer_user_query → 類似検索・回答生成
5. fe → ユーザーインターフェース

## インフラストラクチャパターン

### ネットワーク設計
- VPC、サブネット、セキュリティグループの適切な分離
- パブリック/プライベートサブネットの使い分け

### モニタリング統合
- New Relicとの統合
- CloudWatchログとメトリクス
- アラート設定の標準化