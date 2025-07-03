# AWS Kubernetes ハンズオン学習課題集

## レベル1: Kubernetes基礎 (ローカル環境 - kind使用)

### 課題1-0: kindクラスターのセットアップ
**目標**: kindを使ったローカルKubernetes環境構築

**事前準備**
```bash
# kindのインストール (macOS)
brew install kind
# または
go install sigs.k8s.io/kind@v0.20.0

# Dockerが動作していることを確認
docker version
```

**課題内容**
1. 基本的なkindクラスターを作成
```bash
# シンプルなクラスター作成
kind create cluster --name learning-cluster

# クラスター情報確認
kubectl cluster-info --context kind-learning-cluster
kubectl get nodes
```

2. マルチノードクラスターの作成
```yaml
# kind-config.yaml を作成
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
- role: worker
- role: worker
```

```bash
# マルチノードクラスター作成
kind create cluster --config kind-config.yaml --name multi-node-cluster

# ノード確認
kubectl get nodes -o wide
```

**チェックポイント**
- control-planeと2つのworkerノードが作成されているか
- 各ノードがReady状態になっているか
- kubectl contextが正しく設定されているか

### 課題1-1: 最初のPodを作成しよう
**目標**: Kubernetesの基本操作を理解する

**課題内容**
1. nginx Podを作成してアクセスしてみよう
```yaml
# nginx-pod.yaml を作成
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:latest
    ports:
    - containerPort: 80
```

2. 実行コマンド
```bash
kubectl apply -f nginx-pod.yaml
kubectl get pods -o wide
kubectl describe pod nginx-pod
kubectl port-forward nginx-pod 8080:80
# ブラウザで http://localhost:8080 にアクセス

# kindならではの確認方法
docker ps  # kindのコンテナ確認
kubectl get pods -o yaml nginx-pod  # 詳細なYAML出力
```

**チェックポイント**
- Podが正常に起動しているか
- nginxのデフォルトページが表示されるか
- kubectl logsでログが確認できるか

### 課題1-2: DeploymentとServiceを作成しよう
**目標**: スケーラブルなアプリケーションデプロイメントを理解する

**課題内容**
1. nginx Deploymentを作成
```yaml
# nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
```

2. Serviceを作成
```yaml
# nginx-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
```

**実行手順**
```bash
kubectl apply -f nginx-deployment.yaml
kubectl apply -f nginx-service.yaml
kubectl get deployments
kubectl get services
kubectl get pods -o wide  # どのノードで動いているか確認
kubectl scale deployment nginx-deployment --replicas=5

# kindでのサービスアクセス方法
kubectl port-forward service/nginx-service 8080:80
# または
kubectl proxy  # 別ターミナルで実行
# http://localhost:8001/api/v1/namespaces/default/services/nginx-service:80/proxy/
```

**チェックポイント**
- 3つのPodが作成されているか
- Serviceから各Podにアクセスできるか
- スケールアップ/ダウンが正常に動作するか

### 課題1-2.5: kindでWebアプリケーションとルーティングを体験しよう
**目標**: Kubernetesの基本的なリソース（Pod、Service、ConfigMap）を使ったWebアプリケーション構築とアクセス

**課題内容**
1. テスト用アプリケーションを作成
```yaml
# test-apps.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1
  labels:
    app: app1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app1
  template:
    metadata:
      labels:
        app: app1
    spec:
      containers:
      - name: app1
        image: nginxdemos/hello:plain-text
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: app1-service
spec:
  selector:
    app: app1
  ports:
  - port: 80
    targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app2
  labels:
    app: app2
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app2
  template:
    metadata:
      labels:
        app: app2
    spec:
      containers:
      - name: app2
        image: hashicorp/http-echo:0.2.3
        args:
        - "-text=Hello from App2!"
        ports:
        - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: app2-service
spec:
  selector:
    app: app2
  ports:
  - port: 80
    targetPort: 5678
```

2. シンプルなWebサーバーとConfigMapを作成
```yaml
# simple-ingress-demo.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-server
  labels:
    app: web-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-server
  template:
    metadata:
      labels:
        app: web-server
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html
      volumes:
      - name: html
        configMap:
          name: web-content
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: web-content
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <title>Kubernetes Demo</title>
        <style>
            body { font-family: Arial; text-align: center; margin-top: 50px; }
            .container { max-width: 800px; margin: 0 auto; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Kubernetes Web Application Demo</h1>
            <p>This page shows that Kubernetes resources are working properly!</p>
            <hr>
            <h2>Running Services:</h2>
            <ul>
                <li>App1 - nginx demo service</li>
                <li>App2 - echo service</li>
            </ul>
        </div>
    </body>
    </html>
---
apiVersion: v1
kind: Service
metadata:
  name: web-server-service
spec:
  selector:
    app: web-server
  ports:
  - port: 80
    targetPort: 80
  type: NodePort
```

**実行手順**
```bash
# アプリケーションをデプロイ
kubectl apply -f test-apps.yaml
kubectl apply -f simple-ingress-demo.yaml

# Pod状態を確認
kubectl get pods -o wide
kubectl get services

# Webサーバーにアクセス（port-forward使用）
kubectl port-forward svc/web-server-service 8000:80

# ブラウザで http://localhost:8000 にアクセス
```

**個別サービスのテスト**
```bash
# App1サービスのテスト
kubectl port-forward svc/app1-service 8001:80
# ブラウザで http://localhost:8001 にアクセス

# App2サービスのテスト  
kubectl port-forward svc/app2-service 8002:80
# ブラウザで http://localhost:8002 にアクセス
```

**チェックポイント**
- ConfigMapを使ったWebページが正しく表示されるか
- port-forwardを使ってローカルからアクセスできるか
- 複数のPodがロードバランシングされているか（app1、app2で確認）
- ServiceとPodの関係が理解できたか

**学習のポイント**
- **ConfigMap**: 設定ファイルやWebコンテンツをPodに注入する方法
- **Service**: Podへの安定したアクセスポイントの提供
- **port-forward**: ローカル開発環境でのサービステスト方法
- **NodePort**: クラスター外部からのアクセス方法

### 課題1-2.6: Helm を使った本格的な Ingress Controller 体験（上級者向け）
**目標**: Helmパッケージマネージャーを使って、本格的なNGINX Ingress Controllerを構築

**事前準備**
```bash
# Helmのインストール（macOS）
brew install helm
# または Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Helmバージョン確認
helm version
```

**課題内容**
1. Helmfileを使ったIngress Controller インストール
```yaml
# helmfile-ingress-nginx.yaml
repositories:
- name: ingress-nginx
  url: https://kubernetes.github.io/ingress-nginx

releases:
- name: ingress-nginx
  namespace: ingress-nginx
  createNamespace: true
  chart: ingress-nginx/ingress-nginx
  version: 4.11.2
  values:
  - controller:
      hostPort:
        enabled: true
      service:
        type: NodePort
      nodeSelector:
        kubernetes.io/os: linux
      tolerations:
      - key: "node-role.kubernetes.io/control-plane"
        operator: "Equal"
        effect: "NoSchedule"
      - key: "node-role.kubernetes.io/master"
        operator: "Equal"
        effect: "NoSchedule"
```

2. インストール実行
```bash
# Helmfileを使ったインストール（Helmfileがある場合）
helmfile apply -f helmfile-ingress-nginx.yaml

# または、直接Helmコマンドを使用
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.hostPort.enabled=true \
  --set controller.service.type=NodePort
```

3. インストール確認
```bash
# Deploymentの確認
kubectl get deploy -n ingress-nginx

# Serviceの確認
kubectl get svc -n ingress-nginx

# IngressClassの確認
kubectl get ingressclasses

# Pod状態の確認
kubectl get pods -n ingress-nginx
```

4. 本格的なIngressリソースの作成
```yaml
# advanced-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /
        pathType: ImplementationSpecific
        backend:
          service:
            name: web-server-service
            port:
              number: 80
      - path: /app1
        pathType: ImplementationSpecific  
        backend:
          service:
            name: app1-service
            port:
              number: 80
      - path: /app2
        pathType: ImplementationSpecific
        backend:
          service:
            name: app2-service
            port:
              number: 80
```

**実行手順**
```bash
# 前提: 課題1-2.5のアプリケーションがデプロイ済みであること
kubectl get pods
kubectl get services

# Ingress Controllerのインストール
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.hostPort.enabled=true \
  --set controller.service.type=NodePort

# インストール完了まで待機
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

# Ingressリソースの作成
kubectl apply -f advanced-ingress.yaml

# Ingress状態の確認
kubectl get ingress
kubectl describe ingress web-ingress

# アクセステスト
curl http://localhost/
curl http://localhost/app1
curl http://localhost/app2
```

**トラブルシューティング**
```bash
# Ingress Controller Pod のログ確認
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Ingress Controller の詳細状態確認
kubectl describe pods -n ingress-nginx

# サービスエンドポイントの確認
kubectl get endpoints

# Ingressのイベント確認
kubectl describe ingress web-ingress
```

**チェックポイント**
- Helmを使ったパッケージ管理の理解
- Ingress Controllerが正常にインストールされているか
- パスベースルーティングが正常に動作するか
- ブラウザで http://localhost/, http://localhost/app1, http://localhost/app2 に正しくアクセスできるか
- 設定変更時のIngress Controllerの動的反映を確認

**学習のポイント**
- **Helm**: Kubernetesのパッケージマネージャーの活用
- **Ingress Controller**: 本格的な外部アクセス制御
- **アノテーション**: nginx特有の設定方法
- **pathType**: パスマッチングの動作制御
- **SSL終端**: HTTPS対応の基礎理解

**注意事項**
- この課題は基本課題（1-2.5まで）が完了してから実施
- エラーが発生した場合は、基本的なport-forward方式に戻ることも可能
- 企業環境での実装に近い本格的な内容

### 課題1-3: カスタムアプリケーションの作成
**目標**: 独自のDockerイメージを使ったアプリケーションデプロイ

**課題内容**
1. 簡単なNode.jsアプリを作成
```javascript
// app.js
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.json({
    message: 'Hello from Kubernetes!',
    hostname: require('os').hostname(),
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', uptime: process.uptime() });
});

app.listen(port, () => {
  console.log(`App running on port ${port}`);
});
```

```json
// package.json
{
  "name": "k8s-demo-app",
  "version": "1.0.0",
  "description": "Demo app for Kubernetes learning",
  "main": "app.js",
  "scripts": {
    "start": "node app.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
```

2. Dockerfileを作成
```dockerfile
FROM node:16-alpine
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
EXPOSE 3000
CMD ["node", "app.js"]
```

3. kindにイメージをロード
```bash
# Dockerイメージをビルド
docker build -t k8s-demo-app:v1.0.0 .

# kindクラスターにイメージをロード
kind load docker-image k8s-demo-app:v1.0.0 --name learning-cluster

# ロードされたイメージを確認
docker exec -it learning-cluster-control-plane crictl images | grep k8s-demo-app
```

4. K8sマニフェストでデプロイ
```yaml
# demo-app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: demo-app
  template:
    metadata:
      labels:
        app: demo-app
    spec:
      containers:
      - name: demo-app
        image: k8s-demo-app:v1.0.0
        imagePullPolicy: Never  # kindではローカルイメージを使用
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: demo-app-service
spec:
  selector:
    app: demo-app
  ports:
  - port: 80
    targetPort: 3000
```

**実行手順**
```bash
kubectl apply -f demo-app.yaml
kubectl get pods -l app=demo-app -o wide
kubectl get services
kubectl port-forward service/demo-app-service 8080:80

# 動作確認
curl http://localhost:8080
curl http://localhost:8080/health
```

**チェックポイント**
- カスタムアプリが正常に動作するか
- 複数のPod間でロードバランシングされているか（hostnameが異なる）
- ヘルスチェックが正常に動作するか
- 環境変数が正しく設定されているか

### 課題1-4: kindクラスターの管理とデバッグ
**目標**: kindクラスターの運用とトラブルシューティング技術

**課題内容**
1. クラスター情報の詳細確認
```bash
# クラスター一覧
kind get clusters

# ノード詳細情報
kubectl get nodes -o wide
kubectl describe node learning-cluster-control-plane

# クラスター内のDockerコンテナ確認
docker ps --filter name=learning-cluster
```

2. ログとイベントの確認
```bash
# Pod ログの確認
kubectl logs -l app=demo-app --tail=50 -f

# イベント確認
kubectl get events --sort-by=.metadata.creationTimestamp

# 特定のPodの詳細デバッグ
kubectl describe pod [POD_NAME]
kubectl exec -it [POD_NAME] -- /bin/sh
```

3. リソース使用状況の監視
```bash
# メトリクスサーバーのインストール
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# metrics-serverをkind用に設定
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

# リソース使用量確認
kubectl top nodes
kubectl top pods
```

4. クラスターのクリーンアップと再作成
```bash
# 特定のリソース削除
kubectl delete deployment,service -l app=demo-app

# クラスター全体の削除
kind delete cluster --name learning-cluster

# 設定ファイルからクラスター再作成
kind create cluster --config kind-config.yaml --name learning-cluster
```

**チェックポイント**
- リソースの使用状況が確認できるか
- ログを使って問題を特定できるか
- クラスターの削除・作成がスムーズに行えるか

## レベル2: AWS EKS入門

### 課題2-1: EKSクラスターの作成
**目標**: AWS上でKubernetesクラスターを構築する

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

## レベル3: 実用的な運用機能

### 課題3-1: ConfigMapとSecretsの活用
**目標**: 設定情報とシークレット情報の適切な管理

**課題内容**
1. 環境設定用のConfigMapを作成
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  database_host: "db.example.com"
  database_port: "5432"
  log_level: "info"
  feature_flag: "true"
```

2. データベース接続情報のSecretを作成
```bash
kubectl create secret generic db-secret \
  --from-literal=username=myuser \
  --from-literal=password=mypassword
```

3. アプリケーションでConfigMapとSecretを使用
```yaml
# 課題: 環境変数とファイルマウント両方の方法で設定を読み込む
```

**チェックポイント**
- ConfigMapの値が環境変数として正しく設定されているか
- Secretの値が適切にマスクされているか
- 設定変更時のPod再起動が自動で行われるか

### 課題3-2: 永続ストレージの実装
**目標**: StatefulSetとPersistent Volumeを使ったデータ永続化

**課題内容**
1. StorageClassを定義
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp2-ssd
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
  fsType: ext4
```

2. PostgreSQLをStatefulSetでデプロイ
```yaml
# 課題: PostgreSQL StatefulSetとPVCを作成
# - データの永続化
# - 初期化スクリプトの実行
# - レプリケーション設定
```

**チェックポイント**
- データベースが永続化されているか（Pod削除後もデータが残るか）
- 複数のレプリカでデータ同期ができているか

### 課題3-3: ヘルスチェックとモニタリング
**目標**: アプリケーションの健全性監視とメトリクス収集

**課題内容**
1. アプリケーションにヘルスチェックエンドポイントを追加
```javascript
// ヘルスチェック機能を追加
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', uptime: process.uptime() });
});

app.get('/ready', (req, res) => {
  // データベース接続チェックなど
  res.status(200).json({ status: 'ready' });
});
```

2. Liveness ProbeとReadiness Probeを設定
```yaml
# 課題: 適切なヘルスチェック設定を追加
```

3. メトリクス収集の設定
```bash
# Prometheus Operatorのインストール
# Grafanaダッシュボードの設定
```

**チェックポイント**
- 不健全なPodが自動的に再起動されるか
- メトリクスが正常に収集・可視化されているか

## レベル4: 自動化とCI/CD

### 課題4-1: GitOpsパイプラインの構築
**目標**: ArgoCD使用したGitOps実装

**課題内容**
1. ArgoCD のインストール
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

2. Git リポジトリの準備
```
my-k8s-app/
├── src/           # アプリケーションソース
├── k8s/           # Kubernetesマニフェスト
│   ├── base/      # 基本設定
│   └── overlays/  # 環境別設定
└── .github/workflows/  # CI設定
```

3. 自動デプロイメントの設定
```yaml
# 課題: ArgoCD Applicationリソースを作成
# - 自動同期の設定
# - ヘルスチェック
# - 同期ポリシー
```

**チェックポイント**
- GitにPushするとアプリケーションが自動デプロイされるか
- ロールバックが正常に動作するか

### 課題4-2: 完全自動化パイプライン
**目標**: GitHub Actions + ArgoCD による完全自動化

**課題内容**
1. CI パイプラインの設定
```yaml
# .github/workflows/ci.yml
# 課題: 以下を含むCIパイプラインを作成
# - テスト実行
# - Dockerイメージビルド
# - ECRへのpush
# - マニフェストファイルの更新
```

2. 複数環境への対応
```
環境構成:
- development (feature branchのpush)
- staging (main branchのpush)  
- production (タグ作成時)
```

**チェックポイント**
- プルリクエスト作成時に自動テストが実行されるか
- 環境ごとに適切にデプロイされるか
- プロダクション環境へのデプロイに承認フローがあるか

## レベル5: 本格運用課題

### 課題5-1: マイクロサービスアーキテクチャの実装
**目標**: 実際のマイクロサービス環境を構築

**課題内容**
サービス構成:
- Frontend (React)
- API Gateway 
- User Service (Node.js + PostgreSQL)
- Product Service (Python + MongoDB)
- Order Service (Java + MySQL)
- Message Queue (Redis)

実装すべき機能:
- サービス間通信
- 分散トレーシング
- 障害時の回復力
- ロードバランシング

**チェックポイント**
- 各サービスが独立してスケールできるか
- 一つのサービスが停止しても他に影響しないか
- パフォーマンス監視ができているか

### 課題5-2: セキュリティ強化
**目標**: 本番運用レベルのセキュリティ実装

**課題内容**
1. RBAC (Role-Based Access Control) の設定
2. Network Policy による通信制御
3. Pod Security Standards の適用
4. Secrets の暗号化
5. イメージの脆弱性スキャン

**チェックポイント**
- 最小権限の原則が適用されているか
- 不要な通信が遮断されているか
- セキュリティ監査に合格するか

## 学習の進め方

1. **各課題を順番に実施** - 前の課題で作成したリソースを活用
2. **エラーログを確認** - 問題が発生したら必ずログを確認
3. **クリーンアップ** - 各課題完了後はリソースを削除してコスト管理
4. **ドキュメント化** - 学んだことをメモして知識を定着

## 推定学習時間
- レベル1: 1-2週間
- レベル2: 2-3週間  
- レベル3: 3-4週間
- レベル4: 2-3週間
- レベル5: 4-6週間

**合計: 12-18週間**

## kubectl コマンドリファレンス

### 基本操作
```bash
# クラスター情報
kubectl cluster-info
kubectl config current-context
kubectl config get-contexts
kubectl config use-context [CONTEXT_NAME]

# ノード確認
kubectl get nodes
kubectl get nodes -o wide
kubectl describe node [NODE_NAME]
```

### リソース操作
```bash
# リソース確認（基本）
kubectl get pods
kubectl get services
kubectl get deployments
kubectl get ingress
kubectl get pv,pvc

# 詳細表示
kubectl get pods -o wide
kubectl get pods -o yaml [POD_NAME]
kubectl describe pod [POD_NAME]
kubectl describe service [SERVICE_NAME]

# 全ネームスペース
kubectl get pods --all-namespaces
kubectl get pods -A

# ラベルでフィルタ
kubectl get pods -l app=nginx
kubectl get pods -l environment=production

# リアルタイム監視
kubectl get pods -w
kubectl get events -w
```

### リソース作成・更新・削除
```bash
# 作成・更新
kubectl apply -f [FILE_NAME].yaml
kubectl apply -f ./manifests/
kubectl apply -k ./kustomize/

# 削除
kubectl delete -f [FILE_NAME].yaml
kubectl delete pod [POD_NAME]
kubectl delete deployment [DEPLOYMENT_NAME]
kubectl delete service [SERVICE_NAME]

# 強制削除
kubectl delete pod [POD_NAME] --force --grace-period=0

# ラベルで一括削除
kubectl delete pods,services -l app=nginx
```

### スケーリング
```bash
# Deploymentのスケール
kubectl scale deployment [DEPLOYMENT_NAME] --replicas=5

# 自動スケーリング
kubectl autoscale deployment [DEPLOYMENT_NAME] --cpu-percent=70 --min=1 --max=10

# スケール状況確認
kubectl get hpa
```

### ログとデバッグ
```bash
# ログ確認
kubectl logs [POD_NAME]
kubectl logs [POD_NAME] -c [CONTAINER_NAME]  # 複数コンテナの場合
kubectl logs -f [POD_NAME]  # フォロー
kubectl logs --tail=50 [POD_NAME]  # 最新50行
kubectl logs -l app=nginx  # ラベルで一括取得

# 前回のコンテナのログ
kubectl logs [POD_NAME] --previous

# イベント確認
kubectl get events
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl get events --field-selector involvedObject.name=[POD_NAME]

# コンテナ内でコマンド実行
kubectl exec -it [POD_NAME] -- /bin/bash
kubectl exec -it [POD_NAME] -- sh
kubectl exec [POD_NAME] -- ls -la /app
```

### ポートフォワーディング
```bash
# Pod へのポートフォワード
kubectl port-forward [POD_NAME] 8080:80

# Service へのポートフォワード
kubectl port-forward service/[SERVICE_NAME] 8080:80

# Deployment へのポートフォワード
kubectl port-forward deployment/[DEPLOYMENT_NAME] 8080:80
```

### ConfigMap と Secret
```bash
# ConfigMap作成
kubectl create configmap [CONFIG_NAME] --from-file=config.properties
kubectl create configmap [CONFIG_NAME] --from-literal=key1=value1 --from-literal=key2=value2

# Secret作成
kubectl create secret generic [SECRET_NAME] --from-literal=username=admin --from-literal=password=secret
kubectl create secret docker-registry [SECRET_NAME] --docker-server=[SERVER] --docker-username=[USER] --docker-password=[PASSWORD]

# 内容確認
kubectl get configmap [CONFIG_NAME] -o yaml
kubectl get secret [SECRET_NAME] -o yaml
kubectl describe configmap [CONFIG_NAME]
```

### リソース監視
```bash
# リソース使用量（metrics-server必要）
kubectl top nodes
kubectl top pods
kubectl top pods --containers

# リソース情報
kubectl describe node [NODE_NAME]
kubectl get pods -o custom-columns=NAME:.metadata.name,CPU:.spec.containers[0].resources.requests.cpu,MEMORY:.spec.containers[0].resources.requests.memory
```

### トラブルシューティング
```bash
# Podの状態詳細確認
kubectl describe pod [POD_NAME]
kubectl get pod [POD_NAME] -o yaml

# ネットワーク確認
kubectl get endpoints
kubectl get networkpolicies

# Podにアクセスして診断
kubectl exec -it [POD_NAME] -- nslookup [SERVICE_NAME]
kubectl exec -it [POD_NAME] -- wget -qO- http://[SERVICE_NAME]:[PORT]

# ヘルスチェック状況
kubectl get pods --show-labels
kubectl describe pod [POD_NAME] | grep -A 10 "Conditions:"
```

### ショートハンド
```bash
# よく使うエイリアス
po = pods
svc = services  
deploy = deployments
rs = replicasets
ns = namespaces
cm = configmaps
ing = ingress
pv = persistentvolumes
pvc = persistentvolumeclaims
sa = serviceaccounts

# 使用例
kubectl get po
kubectl get svc
kubectl get deploy
kubectl describe ing
```

### ネームスペース操作
```bash
# ネームスペース作成
kubectl create namespace [NAMESPACE_NAME]

# 現在のネームスペース確認
kubectl config view --minify -o jsonpath='{..namespace}'

# デフォルトネームスペース変更
kubectl config set-context --current --namespace=[NAMESPACE_NAME]

# 特定ネームスペースで実行
kubectl get pods -n [NAMESPACE_NAME]
kubectl apply -f manifest.yaml -n [NAMESPACE_NAME]
```

### 便利なTips
```bash
# JSON Path でカスタム出力
kubectl get pods -o jsonpath='{.items[*].metadata.name}'
kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}'

# 複数リソースを一度に確認
kubectl get pods,services,deployments

# ドライラン（実際には実行せず確認のみ）
kubectl apply -f manifest.yaml --dry-run=client -o yaml

# マニフェスト生成
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml
kubectl expose deployment nginx --port=80 --target-port=8000 --dry-run=client -o yaml

# 設定差分確認
kubectl diff -f manifest.yaml
```

### kind特有のコマンド
```bash
# クラスター管理
kind create cluster --name [CLUSTER_NAME]
kind delete cluster --name [CLUSTER_NAME]
kind get clusters

# イメージのロード
kind load docker-image [IMAGE_NAME] --name [CLUSTER_NAME]

# kindノードのシェルアクセス
docker exec -it [CLUSTER_NAME]-control-plane bash
```

---

各課題で困ったことがあれば、具体的なエラーメッセージや状況を教えてください。詳細な解決方法をサポートします。