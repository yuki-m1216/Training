# プロジェクト概要

## プロジェクトの目的
このリポジトリはTerraform練習用リポジトリで、AWSとNew Relicインフラストラクチャ設定の包括的な例を含んでいます。

## 技術スタック
- **Infrastructure as Code**: Terraform
- **Programming Languages**: 
  - TypeScript/JavaScript (Lambda関数、Next.jsフロントエンド)
  - Python (RAGシステム)
- **クラウドプロバイダー**: AWS、New Relic
- **フレームワーク**: Next.js (React 19)、LangChain

## プロジェクト構造
```
Terraform/
├── AWS/
│   ├── modules/          # 再利用可能なTerraformモジュール
│   └── Resources/        # AWSサービス別の実装例
│       ├── Lambda/       # Lambda関数群
│       ├── APIGateway/   # API Gateway設定
│       ├── ECS/          # ECSコンテナ設定
│       ├── RAG/          # RAGシステム実装
│       └── ...           # その他のAWSサービス
├── NewRelic/
│   ├── modules/          # New Relic用モジュール
│   └── Resources/        # New Relicリソース設定
└── CLAUDE.md            # プロジェクト固有の指示
```

## 主要な特徴
- Lambda関数とOpenAPI仕様を統合したAPI Gateway
- CloudFrontディストリビューションを使用したECSコンテナ化アプリケーション
- OpenSearchとBedrockを使用したRAG（Retrieval-Augmented Generation）実装
- VPC、セキュリティグループ、ルーティングを含む完全なネットワークセットアップ
- New Relicアラート、AWS統合、ログ転送、synthetics