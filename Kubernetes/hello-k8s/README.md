# Hello Kubernetes - 学習用最小サンプル

TypeScript + Express を使用した Kubernetes 学習用の Hello World アプリケーション

## 🎯 学習目標

- Docker コンテナを Kubernetes で実行する基本フロー
- Deployment, Service, Ingress の役割と連携
- Kubernetes の基本概念の理解

## 📁 プロジェクト構成

```
hello-k8s/
├── src/
│   └── index.ts          # Express アプリケーション
├── k8s/
│   ├── deployment.yaml   # アプリケーション実行設定
│   ├── service.yaml      # ネットワーク設定
│   └── ingress.yaml      # 外部アクセス設定
├── package.json          # Node.js 依存関係
├── tsconfig.json         # TypeScript 設定
├── dockerfile            # コンテナイメージ設定
└── README.md
```

## 🛠 実行手順

### 1. 前提条件

```bash
# 必要ツールのインストール確認
docker --version
kubectl version --client
kind --version
```

### 2. Kind クラスター作成

```bash
# クラスター作成
kind create cluster --name hello-k8s

# コンテキスト確認
kubectl config current-context
# 出力: kind-hello-k8s
```

### 3. Docker イメージビルド

```bash
# プロジェクトディレクトリでビルド
docker build -t hello-k8s:latest .

# Kind クラスターにイメージロード
kind load docker-image hello-k8s:latest --name hello-k8s

# イメージ確認
docker images | grep hello-k8s
```

### 4. Kubernetes リソースデプロイ

```bash
# マニフェスト適用
kubectl apply -f k8s/

# デプロイ状況確認
kubectl get deployments
kubectl get pods
kubectl get services
```

### 5. Service 経由でのアクセス確認

```bash
# ポートフォワード設定
kubectl port-forward service/hello-k8s-service 8080:80

# 別ターミナルでアクセステスト
curl http://localhost:8080
# 出力: Hello, Kubernetes!
```

### 6. Ingress Controller セットアップ

```bash
# Nginx Ingress Controller インストール
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/kind/deploy.yaml

# ノードにラベル追加（Kind用）
kubectl label node hello-k8s-control-plane ingress-ready=true

# Controller 準備完了まで待機
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s
```

### 7. Ingress 経由でのアクセス確認

```bash
# Ingress適用
kubectl apply -f k8s/ingress.yaml

# Ingress 状況確認
kubectl get ingress

# ポートフォワード経由でテスト（/etc/hosts編集不要）
kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80

# 別ターミナルでアクセステスト
curl -H "Host: hello-k8s.local" http://localhost:8080
# 出力: Hello, Kubernetes!
```

## 📝 Kubernetes 基本概念

### Deployment
- **役割**: アプリケーションの実行単位
- **特徴**: レプリカ数、更新戦略、リソース制限を管理

### Service
- **役割**: Pod 間のロードバランシング
- **特徴**: ClusterIP（内部）, NodePort（外部）, LoadBalancer（クラウド）

### Ingress
- **役割**: 外部からのアクセス制御とルーティング
- **特徴**: ホストベース/パスベースルーティング、SSL終端

## 🧹 クリーンアップ

```bash
# リソース削除
kubectl delete -f k8s/
kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/kind/deploy.yaml

# クラスター削除
kind delete cluster --name hello-k8s

# クリーンアップ確認
kind get clusters
docker images | grep hello-k8s
```

