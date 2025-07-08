# レベル2: AWS EKS入門

**[← レベル1: Kubernetes基礎](02_level1_basics.md) | [次のレベル: 実用的な運用機能 →](04_level3_operations.md)**

### 課題2-1: EKSクラスターの作成
**目標**: AWS上でKubernetesクラスターを構築する

**学習内容の解説**:

### EKS vs セルフマネージド Kubernetes
**なぜ EKS を選ぶのか**:
```
セルフマネージド:
├── Control Plane管理 (自分で実施)
├── etcdバックアップ (自分で実施)  
├── Kubernetesアップグレード (自分で実施)
└── 高可用性設定 (自分で実施)

EKS (マネージド):
├── Control Plane管理 (AWS管理)
├── etcdバックアップ (AWS管理)
├── Kubernetesアップグレード (AWS管理) 
└── 高可用性設定 (AWS管理)
```

### eksctl による Infrastructure as Code
**eksctl の背後で動作する仕組み**:
```bash
eksctl create cluster --name my-cluster
    ↓
CloudFormation スタック作成:
├── VPC (10.0.0.0/16)
├── Subnets (Public × 2, Private × 2) 
├── Internet Gateway
├── NAT Gateway
├── Security Groups
├── IAM Roles (Cluster, NodeGroup)
└── EKS Cluster + Managed Node Group
```

**実際のコスト構造**:
```
EKS Control Plane: $0.10/hour ($72/month)
Worker Nodes (t3.medium × 2): $0.0416 × 2 × 24 × 30 = $59.9/month
NAT Gateway: $0.045/hour × 2 = $64.8/month
EBS Volumes: $0.1/GB/month × 20GB × 2 = $4/month
```
→ 最小構成でも月額約$200の費用が発生

### IAM統合の実装詳細
**従来のKubernetesの認証**:
```bash
# 証明書ベース認証
kubectl config set-credentials user --client-certificate=user.crt --client-key=user.key
```

**EKSでのIAM統合**:
```bash
# AWS IAM認証 (aws-iam-authenticator)
kubectl get pods
    ↓
1. kubectl → aws-iam-authenticator (AWS STS GetCallerIdentity)
2. AWS STS → IAM Role/User 検証
3. IAM Role → Kubernetes User/Group マッピング 
4. Kubernetes RBAC → 権限チェック
```

### ワーカーノード の種類と選択指針
**Managed Node Groups vs Self-managed vs Fargate**:
| 項目 | Managed | Self-managed | Fargate |
|------|---------|--------------|---------|
| ノード管理 | AWS自動 | 手動 | 不要 |
| OS更新 | AWS自動 | 手動 | AWS自動 |
| スケーリング | 簡単 | 手動/ASG | 自動 |
| コスト | 中 | 低 | 高 |
| カスタマイズ | 制限あり | 自由 | 制限あり |

**本番環境での構成例**:
```yaml
# 本番推奨構成
Cluster:
  Version: 1.28
  Endpoint: Private
  Logging: ["api", "audit", "authenticator"]

NodeGroups:
  - Name: "system"
    InstanceType: "t3.medium"  
    MinSize: 2, MaxSize: 4
    Labels: { workload: "system" }
    Taints: [{ key: "system", effect: "NoSchedule" }]
    
  - Name: "application"  
    InstanceType: "m5.large"
    MinSize: 3, MaxSize: 10
    Labels: { workload: "application" }
```

### ネットワーク設計の考慮事項
**Production-Ready VPC設計**:
```
VPC (10.0.0.0/16)
├── Public Subnets
│   ├── 10.0.1.0/24 (AZ-a) → ALB, NAT Gateway
│   └── 10.0.2.0/24 (AZ-c) → ALB, NAT Gateway
└── Private Subnets  
    ├── 10.0.10.0/24 (AZ-a) → Worker Nodes
    └── 10.0.20.0/24 (AZ-c) → Worker Nodes
```

**セキュリティグループ設計**:
```
Control Plane SG:
├── Inbound: 443 from Worker Nodes
└── Outbound: All to Worker Nodes

Worker Nodes SG:  
├── Inbound: All from Control Plane
├── Inbound: All from same SG (Pod間通信)
└── Outbound: All (internet access)
```

### 実際の企業導入パターン
**段階的移行アプローチ**:
```
Phase 1: 開発環境でPoCk実施
├── 既存アプリの1つをコンテナ化
├── EKSクラスター構築
└── 基本的なCI/CD構築

Phase 2: ステージング環境構築  
├── 本番相当の構成テスト
├── パフォーマンステスト
└── 運用手順の確立

Phase 3: 本番環境移行
├── 段階的なワークロード移行
├── モニタリング・アラート設定
└── 障害対応体制構築
```

### EKS特有の運用考慮事項
**Kubernetes バージョン管理**:
```bash
# EKSサポートバージョン (常に最新3バージョン)
Current: 1.28, 1.27, 1.26
EOL: 1.25 (サポート終了)

# アップグレード戦略
1. Control Plane → 新バージョン (ダウンタイムなし)
2. Node Groups → 新バージョン (ローリング更新)
3. Application → 互換性テスト
```

**コスト最適化戦略**:
```bash
# Spot Instances の活用
eksctl create cluster \
  --spot \
  --instance-types=m5.large,m5.xlarge,c5.large \
  --nodes-min=2 --nodes-max=10

# Cluster Autoscaler + HPA
Scale-out: 負荷増加時にPod→Node自動追加
Scale-in:  負荷減少時にNode→Pod自動削除
```

**事前準備**
```bash
# 必要なツールのインストール
# AWS CLI, eksctl, kubectl
aws configure
```

**課題内容**
1. EKSクラスターを作成
```bash
eksctl create cluster \
  --name my-first-cluster \
  --region ap-northeast-1 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3 \
  --managed
```

2. 接続確認
```bash
aws eks update-kubeconfig --region ap-northeast-1 --name my-first-cluster
kubectl get nodes
kubectl get pods --all-namespaces
```

**チェックポイント**
- EKSクラスターが正常に作成されたか
- ワーカーノードが準備完了状態か
- kubectlでクラスターにアクセスできるか

### 課題2-2: ECRとの連携
**目標**: AWS ECRを使ったプライベートコンテナレジストリ活用

**学習内容の解説**:
- **ECRとは**: Amazon Elastic Container Registryの役割とプライベートレジストリ
- **認証メカニズム**: AWS CLI経由でのDocker認証とトークン管理
- **イメージ管理**: タグ付け、バージョン管理、イメージのライフサイクル管理
- **セキュリティ**: プライベートレジストリの利点、脆弱性スキャン機能
- **EKSとの統合**: 自動的なイメージプル認証とIAMロールベースアクセス

**課題内容**
1. ECRリポジトリを作成
```bash
aws ecr create-repository --repository-name my-node-app --region ap-northeast-1
```

2. 先ほど作成したNode.jsアプリをECRにpush
```bash
# ECRログイン
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin [ACCOUNT_ID].dkr.ecr.ap-northeast-1.amazonaws.com

# イメージのビルドとタグ付け
docker build -t my-node-app .
docker tag my-node-app:latest [ACCOUNT_ID].dkr.ecr.ap-northeast-1.amazonaws.com/my-node-app:latest

# ECRにpush
docker push [ACCOUNT_ID].dkr.ecr.ap-northeast-1.amazonaws.com/my-node-app:latest
```

3. EKSクラスターにデプロイ
```yaml
# 課題: ECRイメージを使ったDeploymentマニフェストを作成
```

**チェックポイント**
- ECRにイメージが正常にpushされたか
- EKSからECRイメージを取得してデプロイできるか

### 課題2-3: AWS Load Balancer Controllerの設定
**目標**: AWS ALBを使った外部アクセスの設定

**学習内容の解説**:
- **AWS Load Balancer Controller**: ALB/NLBをKubernetesリソースとして管理
- **IAM Service Account**: IRSA (IAM Roles for Service Accounts) の仕組み
- **Application Load Balancer**: L7ロードバランサーの高度な機能活用
- **Ingressとの統合**: Kubernetesネイティブな外部アクセス設定
- **SSL/TLS**: Certificate Managerとの連携による自動証明書管理

**課題内容**
1. AWS Load Balancer Controllerをインストール
```bash
# IAMロール作成
eksctl create iamserviceaccount \
  --cluster=my-first-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess \
  --override-existing-serviceaccounts \
  --approve

# Helm経由でインストール
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=my-first-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

2. Ingressを作成
```yaml
# ingress.yaml を作成してALB経由でアクセス
```

**チェックポイント**
- ALBが正常に作成されたか
- インターネット経由でアプリケーションにアクセスできるか

