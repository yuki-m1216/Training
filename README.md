# 📚 学習リポジトリ / Training Repository

インフラを中心に、フロントエンド・バックエンドまで幅広い技術を学習・実践するためのリポジトリです。

## 🛠️ 学習中の技術スタック

- **インフラ**: Terraform, Kubernetes, Docker, AWS, NewRelic
- **バックエンド**: NestJS, Node.js, TypeScript  
- **フロントエンド**: Next.js, React, TypeScript
- **CI/CD**: GitHub Actions

## 📁 プロジェクト構成

```
Training/
├── Terraform/              # Infrastructure as Code
│   ├── AWS/               # 20+ AWSサービスのモジュール実装
│   │   ├── Resources/     # 実際のリソース定義
│   │   └── modules/       # 再利用可能なモジュール
│   └── NewRelic/          # 監視・アラート設定
│       ├── Resources/
│       └── modules/
├── Kubernetes/            # コンテナオーケストレーション
│   ├── hello-k8s/        # K8s基礎学習
│   ├── learning-roadmap/ # 段階的学習プロジェクト
│   └── next-nest-k8s-app/ # Next.js + NestJS フルスタックアプリ
└── .github/workflows/     # Terraform自動検証
```

## 🚀 実装済みの主な内容

### Terraform / AWS
- **コンピューティング**: EC2, ECS, EKS, Lambda
- **ストレージ**: S3, EBS
- **データベース**: RDS, DynamoDB
- **ネットワーキング**: VPC, CloudFront, API Gateway, Route53
- **セキュリティ**: IAM, Security Groups, ACM
- **監視・ログ**: CloudWatch, CloudTrail, GuardDuty
- **その他**: Kinesis, OpenSearch, SNS, EventBridge

### Kubernetes
- **基礎**: Pod, Service, Deployment, ConfigMap
- **ネットワーキング**: Ingress設定
- **パッケージ管理**: Helm Charts
- **フルスタックアプリ**: Next.js + NestJS + PostgreSQL

### フルスタックアプリケーション
- **フロントエンド**: Next.js, React, TypeScript
- **バックエンド**: NestJS, TypeScript
- **データベース**: PostgreSQL
- **コンテナ化**: Docker, Docker Compose
- **オーケストレーション**: Kubernetes manifests

## 🔧 環境構築

### 必要ツール
- Terraform (>= 1.0)
- kubectl
- Docker & Docker Compose
- AWS CLI
- Node.js & npm

### 使用方法
各プロジェクトの詳細な使用方法については、各ディレクトリ内のREADMEを参照してください。

- [hello-k8s](./Kubernetes/hello-k8s/)
- [next-nest-k8s-app](./Kubernetes/next-nest-k8s-app/)

## 🔄 CI/CD

GitHub Actionsを使用したTerraformの自動検証を実装済み：
- プルリクエスト時の`terraform plan`実行
- メインブランチへのマージ時の自動適用

---

**Learning Progress**: 継続的に新しい技術を追加・実践しています 🌱