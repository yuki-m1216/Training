# プロジェクト概要

## プロジェクトの目的
このリポジトリはTerraform練習用リポジトリで、AWSとNew Relicインフラストラクチャ設定の包括的な例を含んでいます。TypeScript/JavaScriptを使用したLambda関数、Next.jsフロントエンドアプリケーション、PythonベースのRAG（Retrieval-Augmented Generation）システムが含まれています。

## 技術スタック

### インフラストラクチャ
- **Terraform**: インフラストラクチャ管理（main tool）
- **AWS**: 主要クラウドプロバイダー（ACM、API Gateway、Lambda、ECS、VPC、OpenSearch、Bedrock等）
- **New Relic**: モニタリングとアラート

### アプリケーション開発
- **TypeScript/JavaScript**: Lambda関数開発
- **Node.js**: ランタイム環境（v22.17.0利用可能）
- **webpack**: TypeScript Lambda関数のビルド
- **Next.js 15.2.4**: フロントエンドフレームワーク（Turbopack使用）
- **React 19**: UIライブラリ
- **TailwindCSS v4**: スタイリング
- **ESLint**: コード品質チェック

### Python/AI関連
- **Python 3.13.5**: Python環境（pyenv利用可能）
- **Poetry**: Pythonパッケージ管理
- **langchain**: RAGシステム用
- **pypdf**: PDF処理用

## プロジェクト構造

```
Terraform/
├── AWS/
│   ├── modules/          # 再利用可能なTerraformモジュール
│   └── Resources/        # AWSサービス別リソース実装
├── NewRelic/
│   ├── modules/          # New Relicモジュール  
│   └── Resources/        # New Relicリソース実装
├── README.md            # プロジェクト説明
└── CLAUDE.md           # 詳細なプロジェクトガイド
```

### 主要機能
- LambdaとOpenAPI仕様を統合したAPI Gateway
- CloudFrontディストリビューションを使用したECSコンテナ化アプリケーション
- OpenSearchとBedrockを使用したRAG実装
- 様々な用途のLambda関数（コンソールログインアラーム、synthetics）
- VPC、セキュリティグループ、ルーティングを含む完全なネットワークセットアップ