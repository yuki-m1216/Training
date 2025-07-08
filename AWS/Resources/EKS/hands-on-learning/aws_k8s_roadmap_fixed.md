# AWS Kubernetes ハンズオン学習課題集

## 📑 目次

- [📋 学習前の前提知識チェック](#-学習前の前提知識チェック)
  - [必須の前提知識](#必須の前提知識)
  - [推奨される事前知識](#推奨される事前知識)
  - [環境要件](#環境要件)
- [🎯 学習目標と期待成果](#-学習目標と期待成果)
  - [このハンズオンで身につくスキル](#このハンズオンで身につくスキル)
  - [学習後のキャリアパス](#学習後のキャリアパス)
- [📖 レベル1: Kubernetes基礎 (ローカル環境 - kind使用)](#-レベル1-kubernetes基礎-ローカル環境---kind使用)
  - [課題1-0: kindクラスターのセットアップ](#課題1-0-kindクラスターのセットアップ)
  - [課題1-1: 最初のPodを作成しよう](#課題1-1-最初のpodを作成しよう)
  - [課題1-2: DeploymentとServiceを作成しよう](#課題1-2-deploymentとserviceを作成しよう)
  - [課題1-2.5: kindでWebアプリケーションとルーティングを体験しよう](#課題1-25-kindでwebアプリケーションとルーティングを体験しよう)
  - [課題1-2.6: Nginx Ingress Controller ハンズオン（kind環境）](#課題1-26-nginx-ingress-controller-ハンズオンkind環境)
  - [課題1-3: カスタムアプリケーションの作成](#課題1-3-カスタムアプリケーションの作成)
  - [課題1-4: kindクラスターの管理とデバッグ](#課題1-4-kindクラスターの管理とデバッグ)
- [☁️ レベル2: AWS EKS入門](#️-レベル2-aws-eks入門)
  - [課題2-1: EKSクラスターの作成](#課題2-1-eksクラスターの作成)
  - [課題2-2: ECRとの連携](#課題2-2-ecrとの連携)
  - [課題2-3: AWS Load Balancer Controllerの設定](#課題2-3-aws-load-balancer-controllerの設定)
- [🔧 レベル3: 実用的な運用機能](#-レベル3-実用的な運用機能)
  - [課題3-1: ConfigMapとSecretsの活用](#課題3-1-configmapとsecretsの活用)
  - [課題3-2: 永続ストレージの実装](#課題3-2-永続ストレージの実装)
  - [課題3-3: ヘルスチェックとモニタリング](#課題3-3-ヘルスチェックとモニタリング)
- [⚙️ レベル4: 自動化とCI/CD](#️-レベル4-自動化とcicd)
  - [課題4-1: GitOpsパイプラインの構築](#課題4-1-gitopsパイプラインの構築)
  - [課題4-2: 完全自動化パイプライン](#課題4-2-完全自動化パイプライン)
- [🏗️ レベル5: 本格運用課題](#️-レベル5-本格運用課題)
  - [課題5-1: マイクロサービスアーキテクチャの実装](#課題5-1-マイクロサービスアーキテクチャの実装)
  - [課題5-2: セキュリティ強化](#課題5-2-セキュリティ強化)
- [📈 学習の進め方](#-学習の進め方)
- [📊 学習進捗管理](#-学習進捗管理)
  - [推定学習時間とマイルストーン](#推定学習時間とマイルストーン)
  - [📋 学習進捗チェックリスト](#-学習進捗チェックリスト)
  - [🎖️ 達成度バッジシステム](#️-達成度バッジシステム)
  - [週次レビューテンプレート](#週次レビューテンプレート)
- [📖 kubectl コマンドリファレンス](#-kubectl-コマンドリファレンス)
  - [基本操作](#基本操作)
  - [リソース操作](#リソース操作)
  - [リソース作成・更新・削除](#リソース作成更新削除)
  - [スケーリング](#スケーリング)
  - [ログとデバッグ](#ログとデバッグ)
  - [ポートフォワーディング](#ポートフォワーディング)
  - [ConfigMap と Secret](#configmap-と-secret)
  - [リソース監視](#リソース監視)
  - [トラブルシューティング](#トラブルシューティング)
  - [ショートハンド](#ショートハンド)
  - [ネームスペース操作](#ネームスペース操作)
  - [便利なTips](#便利なtips)
  - [kind特有のコマンド](#kind特有のコマンド)
- [🧹 学習後のクリーンアップ](#-学習後のクリーンアップ)
  - [ローカル環境（kind）のクリーンアップ](#ローカル環境kindのクリーンアップ)
  - [AWS環境のクリーンアップ](#aws環境のクリーンアップ)
  - [注意事項](#注意事項)
  - [クリーンアップ確認](#クリーンアップ確認)
- [🔧 よくある質問とトラブルシューティング](#-よくある質問とトラブルシューティング)
- [📚 参考資料とさらなる学習](#-参考資料とさらなる学習)
  - [公式ドキュメント](#公式ドキュメント)
  - [推奨書籍](#推奨書籍)
  - [オンライン学習リソース](#オンライン学習リソース)
  - [コミュニティ](#コミュニティ)
- [🏆 次のステップ](#-次のステップ)
  - [認定試験への挑戦](#認定試験への挑戦)
  - [実践プロジェクト案](#実践プロジェクト案)

---

## 📋 学習前の前提知識チェック

### 必須の前提知識
- **Docker基礎**: コンテナ、イメージ、Dockerfileの理解
- **Linux基本コマンド**: bash、ファイル操作、権限管理
- **ネットワーク基礎**: IP、ポート、HTTP/HTTPSの理解
- **YAML形式**: 基本的な構文理解

### 推奨される事前知識
- **クラウド基礎**: AWS基本サービス（EC2、VPC、IAM）
- **CI/CD概念**: ビルド、テスト、デプロイの流れ
- **API設計**: REST API、JSONの理解

### 環境要件
- **開発マシン**: Windows 10/11、macOS 10.15+、Ubuntu 18.04+
- **必要リソース**: RAM 8GB以上、ディスク容量 20GB以上
- **ネットワーク**: インターネット接続（Docker Hub、GitHub、AWS API アクセス用）

## 🎯 学習目標と期待成果

### このハンズオンで身につくスキル
- **Kubernetes基礎**: Pod、Service、Deployment等のコア概念
- **実践的運用**: モニタリング、ログ管理、トラブルシューティング
- **クラウドネイティブ**: AWS EKS、ECR等のマネージドサービス活用
- **自動化**: CI/CD、GitOps、Infrastructure as Code
- **本番運用**: セキュリティ、スケーリング、災害復旧

### 学習後のキャリアパス
- **DevOpsエンジニア**: インフラ自動化、CI/CD構築
- **SRE（Site Reliability Engineer）**: 高可用性システム運用
- **クラウドアーキテクト**: クラウドネイティブシステム設計
- **Kubernetesエンジニア**: コンテナオーケストレーション専門家

## レベル1: Kubernetes基礎 (ローカル環境 - kind使用)

### 課題1-0: kindクラスターのセットアップ
**目標**: kindを使ったローカルKubernetes環境構築

**学習内容の解説**:

### kindの特徴と利点
- **kind (Kubernetes in Docker)**: Dockerコンテナ内でKubernetesクラスターを実行する軽量ツール
- **ローカル開発環境の利点**: 
  - クラウドコストをかけずにKubernetes学習が可能
  - 高速なクラスター作成・削除（約30秒〜1分）
  - 実際のKubernetesクラスターと同等の機能
  - CI/CDパイプラインでのテスト環境としても利用

### クラスター構成の理解
**単一ノードクラスター**:
```
[Control Plane + Worker] ← すべての機能が1つのコンテナに統合
```

**マルチノードクラスター**:
```
[Control Plane] ← API Server, etcd, Scheduler
     |
[Worker Node 1] ← Pod実行環境
[Worker Node 2] ← Pod実行環境
```

### 実践的なポートマッピング設定
```yaml
extraPortMappings:
- containerPort: 80   # kindコンテナ内のポート
  hostPort: 80        # ホストマシンのポート
  protocol: TCP
```
この設定により、`localhost:80`でkindクラスター内のサービスにアクセス可能

### 本格運用との違い
- **本番環境**: 物理サーバーまたはクラウドVM上でKubernetes実行
- **kind環境**: Dockerコンテナ内でKubernetes実行
- **学習効果**: 本質的なKubernetesの概念は同じため、学習内容は本番でも活用可能

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

**学習内容の解説**:

### Podの核心概念
**Podとは何か**:
```
Pod = 1つまたは複数のコンテナ + 共有ストレージ + ネットワーク
```

**DockerコンテナとPodの違い**:
| 項目 | Dockerコンテナ | Kubernetes Pod |
|------|----------------|----------------|
| 最小単位 | コンテナ | Pod（コンテナを含む） |
| ネットワーク | 独立 | Pod内のコンテナは共有 |
| ストレージ | 独立 | Pod内のコンテナは共有可能 |
| ライフサイクル | 個別管理 | Pod単位で管理 |

### YAMLマニフェストの構造理解
```yaml
apiVersion: v1        # Kubernetes APIのバージョン
kind: Pod            # リソースタイプ
metadata:            # メタデータ（名前、ラベル等）
  name: nginx-pod
  labels:
    app: nginx
spec:               # 仕様（期待される状態）
  containers:
  - name: nginx
    image: nginx:latest
    ports:
    - containerPort: 80
```

### 宣言的管理の重要性
**命令的 vs 宣言的**:
```bash
# 命令的（従来の方法）
docker run -d -p 80:80 nginx

# 宣言的（Kubernetesの方法）
kubectl apply -f nginx-pod.yaml
```

**宣言的管理の利点**:
- **バージョン管理**: Gitでマニフェストファイルを管理
- **再現性**: 同じマニフェストで同じ環境を構築
- **変更追跡**: 設定変更の履歴が明確
- **ロールバック**: 以前の状態に簡単に戻せる

### kubectl基本コマンドの実践的理解
```bash
# リソース作成・更新
kubectl apply -f nginx-pod.yaml    # マニフェストを適用

# 状態確認
kubectl get pods                   # Pod一覧表示
kubectl get pods -o wide          # 詳細情報付きで表示
kubectl describe pod nginx-pod    # 詳細な状態とイベント

# ログ確認
kubectl logs nginx-pod             # Podのログ表示

# アクセス確認
kubectl port-forward nginx-pod 8080:80  # ローカルポートフォワード
```

### 実際の動作フロー
1. **マニフェスト作成**: YAMLファイルで期待する状態を定義
2. **API Server**: kubectl がマニフェストをAPI Serverに送信
3. **etcd**: API ServerがetcdにPodの定義を保存
4. **Scheduler**: 適切なノードを選択してPodを配置
5. **kubelet**: 選択されたノード上でコンテナを起動
6. **状態監視**: kubeletが継続的にPodの健全性を監視

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

**学習内容の解説**:

### Deploymentによる高可用性の実現
**なぜPodを直接使わないのか**:
```
Pod (直接作成) → 障害時に自動復旧しない
Deployment → Pod障害時に自動で新しいPodを作成
```

**Deploymentの階層構造**:
```
Deployment
  └── ReplicaSet (Pod テンプレート管理)
      ├── Pod 1
      ├── Pod 2
      └── Pod 3
```

### 実際のスケーリングシナリオ
**水平スケーリング（Pod数の増減）**:
```bash
# 現在のPod数確認
kubectl get pods -l app=nginx

# スケールアウト（負荷増加対応）
kubectl scale deployment nginx-deployment --replicas=5

# スケールイン（コスト削減）
kubectl scale deployment nginx-deployment --replicas=2
```

**スケーリングが必要になる実例**:
- **ブラックフライデー**: ECサイトのトラフィック急増
- **朝の通勤時間**: 交通アプリのアクセス集中
- **深夜時間**: バッチ処理でのリソース調整

### Serviceによるネットワーク抽象化
**Service がない場合の問題**:
```
Client → Pod IP (10.244.1.5) ← Pod再作成時にIPが変わる！
```

**Service による解決**:
```
Client → Service (Cluster IP: 10.96.1.10) → Pod群
                    ↓
              安定したエンドポイント
```

### サービスタイプの選択指針
| タイプ | 用途 | アクセス方法 | 実用例 |
|--------|------|-------------|--------|
| ClusterIP | クラスター内通信 | クラスター内のみ | データベース、内部API |
| NodePort | 開発・テスト | ノードIP:ポート | 開発環境でのアクセス |
| LoadBalancer | 本番外部公開 | 外部LB経由 | Webアプリケーション |
| ExternalName | 外部サービス統合 | DNS CNAME | 外部データベース |

### ラベルセレクターによる疎結合
```yaml
# Deployment側
spec:
  selector:
    matchLabels:
      app: nginx      # この条件でPodを管理

# Service側  
spec:
  selector:
    app: nginx        # この条件でPodを選択
```

**利点**:
- **柔軟性**: ラベルを変更するだけで対象を変更可能
- **デバッグ**: 特定のPodだけをサービスから外すことが可能
- **段階的デプロイ**: カナリアリリースやブルーグリーンデプロイに活用

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

**学習内容の解説**:

### ConfigMapによる設定の外部化
**従来の問題点**:
```dockerfile
# Dockerfile内にハードコーディング
ENV DATABASE_URL="postgres://prod-db:5432/app"
ENV LOG_LEVEL="info"
```
→ 環境ごとにイメージを作り直す必要

**ConfigMapによる解決**:
```yaml
# 設定をマニフェストで管理
apiVersion: v1
kind: ConfigMap
metadata:
  name: web-content
data:
  index.html: |
    <h1>Environment: {{ENV}}</h1>
    <p>Database: {{DATABASE_URL}}</p>
```

### 実際の企業でのユースケース
**マルチテナント SaaS アプリケーション**:
```
tenant-a.example.com → App1 (Apache + カスタムHTML)
tenant-b.example.com → App2 (nginx + 別のHTML)
```

**マイクロサービス開発**:
```
frontend-service    (React/Vue.js)
api-gateway-service (nginx proxy)
auth-service       (Node.js)
user-service       (Python)
```

### port-forwardingの開発フロー
**実際の開発シナリオ**:
```bash
# 1. フロントエンド開発者の作業
kubectl port-forward svc/frontend-service 3000:80
# → http://localhost:3000 でフロントエンド確認

# 2. バックエンド開発者の作業  
kubectl port-forward svc/api-service 8080:80
# → http://localhost:8080/api でAPI確認

# 3. 統合テスト
kubectl port-forward svc/web-server-service 8000:80
# → http://localhost:8000 で全体確認
```

### 複数サービスの動作パターン比較
**Apache httpd の特徴**:
- **設定**: httpd.conf による詳細制御
- **パフォーマンス**: プロセスベース、安定性重視
- **用途**: 企業システム、PHP アプリケーション

**nginx の特徴**:
- **設定**: シンプルなディレクティブ
- **パフォーマンス**: イベントドリブン、高速
- **用途**: 静的コンテンツ、リバースプロキシ

### ラベルセレクターの実践的活用
```bash
# 環境ラベルでフィルタ
kubectl get pods -l environment=development
kubectl get pods -l environment=production

# アプリケーションタイプでフィルタ
kubectl get pods -l app=frontend
kubectl get pods -l app=backend

# 複数条件での絞り込み
kubectl get pods -l app=nginx,environment=production
```

**ブルーグリーンデプロイでの活用例**:
```yaml
# Blue環境
metadata:
  labels:
    app: myapp
    version: blue

# Green環境  
metadata:
  labels:
    app: myapp
    version: green

# Serviceは一時的にBlueを向く
selector:
  app: myapp
  version: blue  # ← 切り替え時にgreenに変更
```

**ファイル場所**: `04-web-application/`

**課題内容**
1. テスト用アプリケーションを作成
```yaml
# test-apps.yaml - シンプルで確実に動作する版
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
        image: httpd:alpine
        ports:
        - containerPort: 80
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
    targetPort: 80
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
        image: nginx:alpine
        ports:
        - containerPort: 80
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
    targetPort: 80
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
                <li>App1 - Apache httpd service</li>
                <li>App2 - nginx service</li>
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
# App1サービスのテスト（Apache httpd）
kubectl port-forward svc/app1-service 8001:80
# ブラウザで http://localhost:8001 にアクセス → "It works!" が表示

# App2サービスのテスト（nginx）
kubectl port-forward svc/app2-service 8002:80
# ブラウザで http://localhost:8002 にアクセス → nginxデフォルトページが表示
```

**トラブルシューティング**
```bash
# Pod状態確認
kubectl get pods,svc -o wide
kubectl get endpoints

# ログ確認
kubectl logs -l app=app1
kubectl logs -l app=app2

# Pod内接続テスト
kubectl exec -it $(kubectl get pod -l app=app1 -o jsonpath='{.items[0].metadata.name}') -- wget -qO- localhost:80
kubectl exec -it $(kubectl get pod -l app=app2 -o jsonpath='{.items[0].metadata.name}') -- wget -qO- localhost:80
```

**チェックポイント**
- App1（Apache httpd）で "It works!" ページが表示されるか
- App2（nginx）でnginxデフォルトページが表示されるか
- port-forwardを使ってローカルからアクセスできるか
- 複数のPodがロードバランシングされているか（app1、app2で確認）
- ServiceとPodの関係が理解できたか

**学習のポイント**
- **複数アプリケーション**: 異なるWebサーバー（Apache httpd、nginx）の比較
- **Service**: Podへの安定したアクセスポイントの提供
- **port-forward**: ローカル開発環境でのサービステスト方法
- **シンプルなデプロイメント**: 確実に動作する基本的な設定

### 課題1-2.6: Nginx Ingress Controller ハンズオン（kind環境）
**目標**: kind環境でNginx Ingress Controllerを構築し、マニフェストベースでのデプロイ方法を学習

**学習内容の解説**:

### なぜIngress Controllerが必要なのか？
**Serviceのみの場合の制限**:
```
従来のServiceアプローチ:
├── LoadBalancer Service 1 → app1 (固有のIP/Port)
├── LoadBalancer Service 2 → app2 (固有のIP/Port)  
└── LoadBalancer Service 3 → app3 (固有のIP/Port)

問題点:
- 各サービスごとに外部ロードバランサー必要 → コスト増
- SSL証明書を各サービスで個別管理 → 運用負荷
- 複雑なルーティング（パス、ヘッダーベース）が困難
- 統一的なアクセスログ・監視が困難
```

**Ingress Controllerによる解決**:
```
Ingressアプローチ:
External Traffic → [Ingress Controller] → 内部Service群
                      ↓
               単一エントリーポイント
                ├── /app1/* → app1-service
                ├── /app2/* → app2-service
                └── /app3/* → app3-service

利点:
- 1つのロードバランサーで複数アプリ管理 → コスト削減
- 集約されたSSL管理 → 運用簡素化
- 高度なルーティング → 柔軟性向上
- 統一ログ・監視 → 可視性向上
```

### 企業での実際のユースケース
**1. マイクロサービスアーキテクチャ**:
```
company.com/
├── /api/users/*     → user-service
├── /api/orders/*    → order-service  
├── /api/products/*  → product-service
├── /admin/*         → admin-dashboard
└── /*               → frontend-app

従来の問題:
- 各サービスごとにLoadBalancer作成
- AWS ALB: $22.5/月 × 5サービス = $112.5/月

Ingress Controller:
- 1つのALBで全サービス管理
- AWS ALB: $22.5/月のみ → 80%コスト削減
```

**2. 複数チーム開発環境**:
```
dev.company.com/
├── /team-a/*    → team-a-namespace
├── /team-b/*    → team-b-namespace
└── /team-c/*    → team-c-namespace

利点:
- チームごとに独立した開発環境
- 単一ドメインでの統合管理
- namespace分離によるリソース隔離
```

**3. カナリアデプロイメント**:
```yaml
# カナリアリリース設定例
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "10"  # 10%を新バージョンに
spec:
  rules:
  - host: app.company.com
    http:
      paths:
      - path: /
        backend:
          service:
            name: app-v2  # 新バージョン
```

### Service vs Ingress Controller比較表
| 項目 | Service (LoadBalancer) | Ingress Controller |
|------|------------------------|-------------------|
| **コスト** | サービス数 × LB料金 | 1つのLB料金のみ |
| **SSL管理** | 各サービスで個別 | 一元管理 |
| **ルーティング** | L4（IP/Port） | L7（Host/Path/Header） |
| **高度な機能** | 基本的な負荷分散のみ | 認証、Rate limiting等 |
| **監視** | 分散したログ | 集約されたログ |
| **設定複雑さ** | シンプル | やや複雑 |

### 実際の運用でのメリット
**1. 運用コスト削減**:
```
# 従来（5マイクロサービス）
Load Balancer × 5 = $112.5/月
SSL証明書管理 × 5 = 管理工数増
監視設定 × 5 = 設定工数増

# Ingress Controller
Load Balancer × 1 = $22.5/月  
SSL証明書管理 × 1 = 管理工数削減
監視設定 × 1 = 設定工数削減
```

**2. 開発効率向上**:
```bash
# 開発者の作業
# Service方式: 各サービスごとにport-forward
kubectl port-forward svc/user-service 8001:80
kubectl port-forward svc/order-service 8002:80
kubectl port-forward svc/product-service 8003:80

# Ingress方式: 1つのエンドポイントで全アクセス
kubectl port-forward svc/ingress-nginx-controller 8080:80
# → http://localhost:8080/api/users
# → http://localhost:8080/api/orders
# → http://localhost:8080/api/products
```

### 高度な機能の活用例
**1. 認証統合**:
```yaml
# OAuth2 Proxy統合
annotations:
  nginx.ingress.kubernetes.io/auth-url: "https://oauth2-proxy.company.com/oauth2/auth"
  nginx.ingress.kubernetes.io/auth-signin: "https://oauth2-proxy.company.com/oauth2/start"
```

**2. Rate Limiting**:
```yaml  
# API Rate制限
annotations:
  nginx.ingress.kubernetes.io/rate-limit: "100"  # 100req/sec
  nginx.ingress.kubernetes.io/rate-limit-window: "1m"
```

**3. 地理的ルーティング**:
```yaml
# 地域別ルーティング  
annotations:
  nginx.ingress.kubernetes.io/server-snippet: |
    if ($geoip_country_code = "JP") {
      set $backend "japan-backend";
    }
    if ($geoip_country_code = "US") {
      set $backend "us-backend";  
    }
```

### 企業導入時の段階的アプローチ
**Phase 1: 単一アプリでの検証**:
```
1つのアプリケーション → Ingress Controller
目標: 基本動作確認、運用手順確立
```

**Phase 2: 複数アプリの統合**:
```
2-3個のアプリケーション → 同一Ingress Controller
目標: ルーティング設定、SSL管理の習熟
```

**Phase 3: 全社展開**:
```
全マイクロサービス → Ingress Controller
目標: 本格運用、監視・アラート整備
```

### Ingress Controllerが特に有効なシナリオ
**1. 当てはまる場合**:
- 複数のWebアプリケーション/APIを運用
- 統一ドメインでのサービス提供が必要
- SSL証明書の一元管理が必要  
- 高度なルーティング（A/Bテスト、カナリア等）が必要
- 運用コストの削減が重要

**2. 不要な場合**:
- 単一アプリケーションのみ
- 内部通信のみ（外部公開不要）
- シンプルな負荷分散のみで十分
- L4レベルの処理で要件を満たす

この知識により、単なるService使用からIngress Controller導入への技術的な判断ができるようになり、実際の企業環境での適用可能性を理解できます。

**ファイル場所**: `05-ingress-controller/`

**使用ファイル一覧**
- `kind-cluster.yaml`: Ingress用ポートマッピング設定のkindクラスタ設定
- `sample-app.yaml`: サンプルアプリケーション（nginx、httpbin）
- `ingress-demo.yaml`: 複数種類のIngressリソース

**前提条件**
- kindがインストールされていること
- kubectlがインストールされていること

**ステップ1: kindクラスタの作成**
```bash
# Ingress用ポートマッピングを含むkindクラスタを作成
kind create cluster --config=05-ingress-controller/kind-cluster.yaml --name nginx-demo
```

**ステップ2: Nginx Ingress Controllerのデプロイ**
```bash
# kind環境用（bare metal）マニフェストを直接適用
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.3/deploy/static/provider/baremetal/deploy.yaml

# デプロイメントの確認
kubectl get pods --namespace=ingress-nginx

# Ingress Controllerの準備完了を待機
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

> **📋 マニフェスト選択の補足**
> 
> **公式ドキュメント参照**: [Deploy - Ingress NGINX Controller](https://github.com/kubernetes/ingress-nginx/blob/main/docs/deploy/index.md)
>
> Ingress NGINX Controllerには環境別の複数のマニフェストが提供されています：
> - **Cloud Provider用** (`/provider/cloud/`): LoadBalancerサービスを使用（AWS、GCP、Azure等）
> - **Bare Metal用** (`/provider/baremetal/`): NodePortサービスを使用（クラウドプロバイダー統合なし）
> - **プロバイダー個別用**: AWS、Digital Ocean、Exoscale等の専用設定
>
> **kind環境でbare metal用を使用する理由：**
> - kind環境はLoadBalancerサービスをサポートしていない
> - 「clusters without cloud provider integrations」に該当
> - NodePortベースの設定が適している
> 
> **追加設定**: kind環境では、さらにhostPort設定（80、443）が必要な場合があります。
> これにより、localhost経由での直接アクセスが可能になります。

**ステップ3: サンプルアプリケーションのデプロイ**
```bash
# サンプルアプリケーションをデプロイ
kubectl apply -f 05-ingress-controller/sample-app.yaml

# Ingressリソースを適用
kubectl apply -f 05-ingress-controller/ingress-demo.yaml
```

**ステップ4: 動作確認**
```bash
# ローカルでのテスト
curl -H "Host: nginx-demo.local" http://localhost
curl -H "Host: httpbin.local" http://localhost/get
```

**学習のポイント**

1. **kind環境での特別な設定**: 
   - `kind-cluster.yaml`でのポートマッピング設定
   - ローカルホストでのアクセス方法

2. **Nginx Ingress Controllerの理解**:
   - 公式マニフェストの構造
   - 名前空間の分離
   - ServiceとDeploymentの関係

3. **Ingressリソースの設定**:
   - ホストベースルーティング
   - パスベースルーティング
   - バックエンドサービスの設定

4. **トラブルシューティング**:
   - ログの確認方法
   - サービスの疎通確認
   - DNSの設定

**詳細な動作確認とデバッグ**
```bash
# Ingress Controllerの状態確認
kubectl get pods -n ingress-nginx -o wide
kubectl describe pod -n ingress-nginx -l app.kubernetes.io/component=controller

# Serviceの確認
kubectl get svc -n ingress-nginx
kubectl get endpoints -n ingress-nginx

# Ingressリソースの確認
kubectl get ingress
kubectl describe ingress -A

# ログの確認
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# サンプルアプリケーションの確認
kubectl get pods,svc -l app=nginx-demo
kubectl get pods,svc -l app=httpbin
```

**応用テスト**
```bash
# 直接Podへのアクセステスト
kubectl port-forward svc/nginx-service 8080:80
curl http://localhost:8080

kubectl port-forward svc/httpbin-service 8081:80  
curl http://localhost:8081/get

# Ingress経由でのアクセステスト
curl -H "Host: nginx-demo.local" http://localhost/
curl -H "Host: httpbin.local" http://localhost/status/200
curl -H "Host: httpbin.local" http://localhost/json
```

**トラブルシューティング: localhost接続できない場合**

もし `curl -H "Host: nginx-demo.local" http://localhost/` で接続エラーが発生する場合、hostPort設定が必要です：

```bash
# Ingress ControllerにhostPort設定を追加
kubectl patch deployment ingress-nginx-controller -n ingress-nginx -p '{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "controller",
          "ports": [
            {"containerPort": 80, "hostPort": 80, "protocol": "TCP"},
            {"containerPort": 443, "hostPort": 443, "protocol": "TCP"},
            {"containerPort": 8443, "hostPort": 8443, "protocol": "TCP"}
          ]
        }]
      }
    }
  }
}'

# Podの再起動を待機
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

これにより、kind-cluster.yamlで設定したポートマッピング（80→80, 443→443）とIngress Controllerが正しく連携します。

**チェックポイント**
- kindクラスタが適切なポートマッピングで作成されているか
- Nginx Ingress Controllerが正常にデプロイされているか
- サンプルアプリケーションがRunning状態になっているか
- Ingressリソースが正しく設定されているか
- ホストヘッダーを指定したcurlでアクセスできるか
- 各サービスが独立してアクセス可能か

## 🔍 通信フローの詳細解説

### curl → Pod への通信経路

```
[Client] → [Docker Host] → [kind Container] → [Ingress Controller] → [Service] → [Pod]
   ↓           ↓              ↓                    ↓                ↓         ↓
  curl    localhost:80   hostPort:80        nginx proxy      ClusterIP   Pod IP
```

### 具体的な通信フロー

**1. クライアント → Docker Host**
```bash
curl -H "Host: nginx-demo.local" http://localhost/
```
- `localhost:80` に HTTP リクエスト送信
- Hostヘッダーで `nginx-demo.local` を指定

**2. Docker Host → kind Container**
```
kind-cluster.yaml の extraPortMappings:
- containerPort: 80    # kindコンテナ内のポート80
  hostPort: 80         # ホストのポート80
```
- ホストの80番ポートがkindコンテナの80番ポートにマッピング

**3. kind Container → Ingress Controller**
```
Ingress Controllerの hostPort設定:
- containerPort: 80
  hostPort: 80       # kindコンテナのポート80にバインド
```
- kindコンテナ内でIngress Controllerが直接80番ポートを使用

**4. Ingress Controller → Service選択**
```yaml
# Ingressリソースでのルーティング設定
rules:
- host: nginx-demo.local      # Hostヘッダーによる判定
  http:
    paths:
    - path: /
      pathType: Prefix
      backend:
        service:
          name: nginx-demo    # 転送先サービス
          port:
            number: 80
```
- Hostヘッダー `nginx-demo.local` に基づいて `nginx-demo` サービスを選択

**5. Service → Pod選択**
```yaml
# nginx-demo Service
spec:
  selector:
    app: nginx-demo    # Podセレクター
  ports:
  - port: 80
    targetPort: 80
```
- `app: nginx-demo` ラベルを持つPodにロードバランシング

**6. 最終的なPod**
```yaml
# nginx-demo Pod
metadata:
  labels:
    app: nginx-demo
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
```
- 実際のnginxコンテナがリクエストを処理

### ネットワーク層での詳細

**IPアドレスとポートの変換:**

```
1. Client:        localhost:80 (127.0.0.1:80)
2. kind Node:     172.18.0.2:80 (kind container IP)
3. Ingress Pod:   10.244.0.X:80 (Pod network)
4. Service:       10.96.Y.Z:80 (ClusterIP)
5. Target Pod:    10.244.0.W:80 (Pod network)
```

**パケットの流れ:**

```
HTTP Request Headers:
GET / HTTP/1.1
Host: nginx-demo.local     ← Ingressルーティングで使用
User-Agent: curl/8.5.0
```

**Ingress Controllerでの処理:**
1. **Host Header解析**: `nginx-demo.local` → `nginx-demo-ingress` ルール適用
2. **Path Matching**: `/` → `pathType: Prefix` で一致
3. **Backend選択**: `nginx-demo` サービスに転送
4. **Load Balancing**: サービスが複数Podから1つを選択

**レスポンスの逆経路:**
```
[Pod] → [Service] → [Ingress Controller] → [kind Container] → [Docker Host] → [Client]
```

### 重要なポイント

**1. ホストヘッダーの重要性**
- `curl http://localhost/` だけでは不十分
- `curl -H "Host: nginx-demo.local" http://localhost/` が必要
- Ingressはこのヘッダーでルーティングを決定

**2. kind環境特有の設定**
- **extraPortMappings**: Docker ↔ kind container
- **hostPort**: kind container ↔ Ingress Controller
- この2段階のポートマッピングが必要

**3. Kubernetesネットワーク**
- **Pod Network**: 10.244.0.0/16 (通常)
- **Service Network**: 10.96.0.0/12 (通常)
- **NodePort Range**: 30000-32767 (デフォルト)

### デバッグコマンド

```bash
# 通信フローの各段階を確認
docker ps | grep nginx-demo                    # 1. kind container確認
kubectl get pods -n ingress-nginx -o wide      # 2. Ingress Controller確認  
kubectl get svc                                # 3. Service確認
kubectl get pods -o wide                       # 4. Target Pod確認
kubectl get ingress                             # 5. Ingress rules確認
```

## 📝 アプリケーション別の動作の違い

### nginx vs httpbin のアクセス方法の違い

テストコマンドで異なるパスを使用している理由を理解しましょう：

```bash
# nginx: ルートパス（/）にアクセス
curl -H "Host: nginx-demo.local" http://localhost/

# httpbin: 特定のエンドポイント（/get）にアクセス  
curl -H "Host: httpbin.local" http://localhost/get
```

**なぜこの違いがあるのか？**

### 1. **nginx** - 静的Webサーバー
```yaml
# nginx-demo は静的HTMLファイルを配信
image: nginx:1.25-alpine
volumeMounts:
- name: nginx-html
  mountPath: /usr/share/nginx/html  # 静的ファイルの配置場所
```

**動作特性:**
- **`/` (ルートパス)**にアクセス → `index.html` を自動配信
- Webサーバーとして標準的な動作
- HTMLコンテンツを返す

**アクセス例:**
```bash
curl -H "Host: nginx-demo.local" http://localhost/
# → カスタムHTMLページが表示される
```

### 2. **httpbin** - HTTP API モック・テスティングサービス
```yaml
# httpbin は HTTP リクエスト/レスポンステスト用のAPIサービス
image: kennethreitz/httpbin:latest
```

> **💡 httpbin とは？**
> 
> [httpbin.org](https://httpbin.org/) は Kenneth Reitz 氏によって開発された **HTTP API のモック・テスティングツール** です。
> 
> **主な用途:**
> - **API開発時のテスト**: 実際のAPIを開発する前のプロトタイピング
> - **HTTP通信の検証**: リクエスト/レスポンスの内容確認
> - **ネットワーク設定のテスト**: プロキシ、ロードバランサー等の動作確認
> - **CI/CDパイプラインでのテスト**: 外部APIに依存しないテスト環境

**動作特性:**
- **API エンドポイント**を提供する動的サービス
- 各エンドポイントが異なる機能を持つ
- JSON レスポンスを返す
- **実際のAPIの代替** として機能（モックAPI）

**利用可能なエンドポイント:**
```bash
# /get - HTTPリクエスト情報をJSON形式で返す
curl -H "Host: httpbin.local" http://localhost/get

# /post - POSTデータのテスト
curl -X POST -H "Host: httpbin.local" http://localhost/post

# /status/200 - 指定したHTTPステータスを返す
curl -H "Host: httpbin.local" http://localhost/status/200

# /headers - リクエストヘッダー情報を表示
curl -H "Host: httpbin.local" http://localhost/headers

# /json - サンプルJSONデータを返す
curl -H "Host: httpbin.local" http://localhost/json
```

### /get エンドポイントの詳細

httpbinの `/get` エンドポイントは以下の情報を JSON 形式で返します：

```json
{
  "args": {},                    # URL クエリパラメータ
  "headers": {                   # リクエストヘッダー
    "Accept": "*/*",
    "Host": "httpbin.local",
    "User-Agent": "curl/8.5.0",
    "X-Forwarded-Host": "httpbin.local",
    "X-Forwarded-Scheme": "http"
  },
  "origin": "172.18.0.1",        # クライアントIP
  "url": "http://httpbin.local/get"  # リクエストURL
}
```

### パスベースルーティングでの使用例

`demo.local` を使ったパスベースルーティングの場合：

```bash
# nginx アプリケーションへのアクセス
curl -H "Host: demo.local" http://localhost/nginx/
# → /nginx/(.*) パターンにマッチ → nginx-demo サービス → HTMLページ

# httpbin アプリケーションのAPIテスト
curl -H "Host: demo.local" http://localhost/httpbin/get  
# → /httpbin/(.*) パターンにマッチ → httpbin サービス → /get API
```

### 学習のポイント

**1. アプリケーションタイプの理解**
- **静的コンテンツ配信** (nginx): `/` でindex.htmlを配信
- **API モックサービス** (httpbin): 特定エンドポイントで機能提供

**2. Ingress でのパス処理**
```yaml
nginx.ingress.kubernetes.io/rewrite-target: /$1
# /nginx/(.*)  → /$1 → / (nginxのルート)
# /httpbin/(.*) → /$1 → /get (httpbinのAPIエンドポイント)
```

**3. 実用的なテストパターン**
- **nginx**: Webアプリケーションの動作確認
- **httpbin**: API通信の詳細な検証（モックAPIとして）

**4. 実際の開発現場での応用**
- **フロントエンド開発**: nginxでSPAアプリケーション配信
- **バックエンド開発**: httpbinでAPI設計・テストの初期段階
- **マイクロサービス**: 複数の異なるサービスタイプの組み合わせ

### なぜモックAPIが重要なのか？

**開発フローでの活用例:**
```
1. API設計段階    → httpbin でエンドポイント設計
2. フロントエンド開発 → httpbin をモックAPIとして使用
3. バックエンド開発  → 実際のAPIを開発
4. 統合テスト     → nginx + 実API の組み合わせテスト
```

**Ingress Controller学習での意義:**
- **現実的なシナリオ**: 実際のマイクロサービス環境を模擬
- **異なるプロトコル**: HTTP/HTTPS、静的/動的コンテンツの混在
- **運用パターン**: 単一エントリーポイントでの複数サービス管理

この違いにより、Ingress Controller を通じた **実際のマイクロサービス環境** でのルーティング学習ができます。

**クリーンアップ**
```bash
# アプリケーションリソースの削除
kubectl delete -f 05-ingress-controller/ingress-demo.yaml
kubectl delete -f 05-ingress-controller/sample-app.yaml

# Ingress Controllerの削除
kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.3/deploy/static/provider/baremetal/deploy.yaml

# kindクラスタの削除
kind delete cluster --name nginx-demo
```

### 課題1-3: カスタムアプリケーションの作成
**目標**: 独自のDockerイメージを使ったアプリケーションデプロイ

**学習内容の解説**:

### 現実的なアプリケーション開発フロー
**企業でのコンテナ化プロセス**:
```
1. 従来のアプリ → VM上で動作
2. Docker化     → コンテナで動作
3. K8s化       → オーケストレーション
```

### Node.jsアプリケーション設計の重要ポイント
**本番を意識したAPI設計**:
```javascript
// 基本エンドポイント
app.get('/')           # メインページ
app.get('/health')     # ヘルスチェック（K8s必須）
app.get('/ready')      # 準備完了チェック
app.get('/metrics')    # 監視メトリクス（将来拡張）
```

**環境対応の考え方**:
```javascript
// 環境別設定
const config = {
  development: { port: 3000, log: 'debug' },
  production:  { port: 3000, log: 'error' },
  test:        { port: 3001, log: 'silent' }
}
```

### kindにおけるイメージ管理の実際
**なぜ `kind load` が必要なのか**:
```
Docker Hub → kubectl apply → ❌ ローカルイメージが見つからない
Local Build → kind load → kubectl apply → ✅ 正常動作
```

**実際の開発ワークフロー**:
```bash
# 1. コード変更
vim app.js

# 2. イメージリビルド
docker build -t myapp:v1.1.0 .

# 3. kindにロード  
kind load docker-image myapp:v1.1.0 --name learning-cluster

# 4. マニフェスト更新
# image: myapp:v1.0.0 → myapp:v1.1.0

# 5. デプロイ
kubectl apply -f deployment.yaml

# 6. 動作確認
kubectl port-forward svc/myapp 8080:80
```

### ヘルスチェックの重要性とベストプラクティス
**なぜヘルスチェックが必要なのか**:
```
アプリ起動時:  Ready Check → トラフィック受け入れ開始
運用中:      Liveness Check → 異常時の自動再起動
```

**実際の障害シナリオ**:
```javascript
// 悪い例: シンプルすぎるヘルスチェック
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// 良い例: 実際の依存関係をチェック
app.get('/health', async (req, res) => {
  try {
    // データベース接続確認
    await db.ping();
    // 外部API確認
    await externalAPI.ping();
    
    res.status(200).json({ 
      status: 'healthy',
      uptime: process.uptime(),
      database: 'connected',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(503).json({ 
      status: 'unhealthy',
      error: error.message 
    });
  }
});
```

### K8sプローブの詳細設定
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 30  # アプリ起動待ち
  periodSeconds: 10        # チェック間隔
  timeoutSeconds: 5        # タイムアウト
  failureThreshold: 3      # 3回失敗で再起動

readinessProbe:
  httpGet:
    path: /ready
    port: 3000
  initialDelaySeconds: 5   # 準備確認開始
  periodSeconds: 5         # チェック間隔
  successThreshold: 1      # 1回成功でトラフィック開始
```

### 本番運用での考慮事項
**imagePullPolicy の理解**:
```yaml
# 開発環境
imagePullPolicy: Never    # ローカルイメージのみ使用

# 本番環境  
imagePullPolicy: Always   # 常に最新をプル
imagePullPolicy: IfNotPresent # なければプル
```

**リソース制限の設定**:
```yaml
resources:
  requests:           # 保証されるリソース
    memory: "64Mi"
    cpu: "250m"
  limits:            # 上限リソース
    memory: "128Mi"
    cpu: "500m"
```

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

**学習内容の解説**:

### 本格的な運用監視の基礎
**企業運用での監視項目**:
```
Infrastructure Level:
├── Cluster Health   (ノード状態、API Server応答)
├── Resource Usage   (CPU、メモリ、ディスク)
└── Network Health   (Pod間通信、DNS解決)

Application Level:
├── Pod Status      (Running、Pending、Failed)
├── Service Health  (エンドポイント疎通)
└── Application Logs (アプリケーション固有のログ)
```

### metrics-serverによるリソース監視
**なぜmetrics-serverが必要なのか**:
```bash
# metrics-server なし
kubectl top nodes
# → error: Metrics API not available

# metrics-server あり  
kubectl top nodes
# → 実際のCPU/メモリ使用率表示
```

**kind環境での特別設定が必要な理由**:
```bash
# 通常のクラスター
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# kind環境では追加設定が必要
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
```
→ kind環境ではkubelet証明書の検証をスキップする必要

### 実践的なトラブルシューティング手順
**Pod が起動しない場合の診断フロー**:
```bash
# 1. Pod状態の基本確認
kubectl get pods
# STATUS: Pending, CrashLoopBackOff, ImagePullBackOff

# 2. 詳細情報の確認
kubectl describe pod [POD_NAME]
# Events セクションで具体的なエラー確認

# 3. ログの確認
kubectl logs [POD_NAME]
kubectl logs [POD_NAME] --previous  # 前回のコンテナのログ

# 4. リソース状況の確認
kubectl top nodes
kubectl top pods
```

**一般的なエラーパターンと対処法**:

| Status | 原因 | 対処法 |
|--------|------|--------|
| ImagePullBackOff | イメージが見つからない | イメージ名・タグの確認 |
| CrashLoopBackOff | アプリケーションエラー | ログ確認、設定見直し |
| Pending | リソース不足 | ノードリソース確認 |
| Init:0/1 | initContainer失敗 | initContainerのログ確認 |

### 実際の障害対応シナリオ
**シナリオ1: メモリ不足による Pod 強制終了**
```bash
# 症状確認
kubectl get pods
# NAME        READY   STATUS      RESTARTS
# myapp-xxx   0/1     OOMKilled   3

# 原因調査
kubectl describe pod myapp-xxx
# Last State: Terminated
# Reason: OOMKilled
# Exit Code: 137

# 対処法: リソース制限の調整
resources:
  requests:
    memory: "64Mi"   # 最小保証
  limits:
    memory: "256Mi"  # ← 増加
```

**シナリオ2: ネットワーク疎通問題**
```bash
# サービス間通信が失敗
kubectl get endpoints
# → backends が 0 の場合は Pod セレクターの問題

# DNS 解決テスト
kubectl exec -it [POD_NAME] -- nslookup kubernetes.default
kubectl exec -it [POD_NAME] -- nslookup [SERVICE_NAME]

# ポート疎通テスト  
kubectl exec -it [POD_NAME] -- wget -qO- http://[SERVICE_NAME]:[PORT]
```

### ログ管理のベストプラクティス
**構造化ログの重要性**:
```javascript
// 悪い例
console.log("User login failed");

// 良い例  
console.log(JSON.stringify({
  level: "error",
  message: "User login failed",
  userId: "12345",
  timestamp: new Date().toISOString(),
  component: "auth-service"
}));
```

**kubectl logs の効果的な使い方**:
```bash
# 複数Pod の集約ログ
kubectl logs -l app=nginx --tail=100 -f

# 特定時間以降のログ
kubectl logs [POD_NAME] --since=1h

# 前回crash したコンテナのログ
kubectl logs [POD_NAME] --previous

# JSON形式での出力（ログ解析ツール用）
kubectl logs [POD_NAME] -o json
```

### クラスター健全性チェックリスト
**日次確認項目**:
```bash
# 1. ノード状態
kubectl get nodes

# 2. システムPod状態  
kubectl get pods -n kube-system

# 3. リソース使用状況
kubectl top nodes
kubectl top pods --all-namespaces

# 4. イベント確認（直近1時間）
kubectl get events --sort-by=.metadata.creationTimestamp | tail -20

# 5. ストレージ状況
kubectl get pv,pvc
```

**緊急時対応手順**:
```bash
# 1. 全体状況の把握
kubectl cluster-info dump > cluster-dump.txt

# 2. 問題Podの緊急復旧
kubectl delete pod [PROBLEMATIC_POD]  # Deployment管理下では自動再作成

# 3. サービス続行確認
kubectl get endpoints [SERVICE_NAME]

# 4. ログ収集（後日分析用）
kubectl logs [POD_NAME] > pod-logs-$(date +%Y%m%d-%H%M%S).txt
```

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

## レベル3: 実用的な運用機能

### 課題3-1: ConfigMapとSecretsの活用
**目標**: 設定情報とシークレット情報の適切な管理

**学習内容の解説**:

### 12 Factor App における設定管理
**なぜ設定を外部化するのか**:
```
悪い例:
├── config/development.json
├── config/staging.json  
└── config/production.json
→ アプリケーションコード内に環境依存設定

良い例:
├── アプリケーション (環境非依存)
└── 環境変数/ConfigMap (環境依存設定)
→ 同じイメージを全環境で使用可能
```

### ConfigMap vs Secrets の使い分け
**ConfigMap (非機密情報)**:
```yaml
# アプリケーション設定
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  database_host: "postgres.example.com"  # OK: 公開情報
  database_port: "5432"                  # OK: 公開情報
  log_level: "info"                      # OK: 公開情報
  feature_flags: "A:true,B:false"        # OK: 公開情報
```

**Secrets (機密情報)**:
```yaml
# 認証情報
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  database_username: bXl1c2Vy    # base64エンコード済み
  database_password: bXlwYXNz    # base64エンコード済み
  api_key: YWJjZGVmZ2g=          # base64エンコード済み
```

### 実際の企業での設定管理パターン
**環境別ConfigMap管理**:
```bash
# 開発環境
k8s/overlays/development/
├── kustomization.yaml
└── configmap.yaml
  data:
    database_host: "dev-db.internal"
    log_level: "debug"

# 本番環境  
k8s/overlays/production/
├── kustomization.yaml
└── configmap.yaml
  data:
    database_host: "prod-db.internal"
    log_level: "error"
```

### 設定注入の3つの方法と用途
**1. 環境変数としての注入**:
```yaml
containers:
- name: app
  env:
  - name: DATABASE_HOST
    valueFrom:
      configMapKeyRef:
        name: app-config
        key: database_host
```
→ **用途**: アプリケーション起動時の基本設定

**2. ファイルマウントとしての注入**:
```yaml
containers:
- name: app
  volumeMounts:
  - name: config-volume
    mountPath: /etc/config
volumes:
- name: config-volume
  configMap:
    name: app-config
```
→ **用途**: 設定ファイル形式が必要な場合（nginx.conf、logback.xml等）

**3. initContainer での設定前処理**:
```yaml
initContainers:
- name: config-merger
  image: busybox
  command: ['sh', '-c', 'merge_configs.sh']
  volumeMounts:
  - name: base-config
  - name: env-config  
  - name: merged-config
```
→ **用途**: 複数設定ファイルのマージが必要な場合

### Secrets のセキュリティ考慮事項
**base64エンコーディングの限界**:
```bash
# base64は暗号化ではない！
echo "mysecretpassword" | base64
# → bXlzZWNyZXRwYXNzd29yZAo=

echo "bXlzZWNyZXRwYXNzd29yZAo=" | base64 -d  
# → mysecretpassword (簡単にデコード可能)
```

**本格的なSecrets管理**:
```yaml
# AWS Secrets Manager 統合
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-secrets
spec:
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: app-secrets
  data:
  - secretKey: password
    remoteRef:
      key: /prod/database/password
```

### 設定変更時の自動リロード
**Deployment による強制再起動**:
```bash
# ConfigMap更新後、Deploymentを再起動
kubectl rollout restart deployment/myapp

# または、ConfigMapのバージョニング
metadata:
  name: app-config-v2  # バージョンを変更
```

**Reloader による自動再起動**:
```yaml
# Stakater Reloader使用
metadata:
  annotations:
    reloader.stakater.com/match: "true"
spec:
  template:
    metadata:
      annotations:
        reloader.stakater.com/auto: "true"
```
→ ConfigMap/Secret変更時に自動でDeployment再起動

### 実践的な設定管理戦略
**階層化設定アプローチ**:
```yaml
# 1. 基本設定 (全環境共通)
apiVersion: v1
kind: ConfigMap
metadata:
  name: base-config
data:
  app_name: "my-application"
  version: "1.0.0"

# 2. 環境固有設定
apiVersion: v1  
kind: ConfigMap
metadata:
  name: env-config
data:
  environment: "production"
  database_host: "prod-db.cluster.local"

# 3. 機密設定
apiVersion: v1
kind: Secret  
metadata:
  name: secret-config
type: Opaque
data:
  database_password: <encrypted>
```

**設定検証の仕組み**:
```javascript
// アプリケーション起動時の設定検証
const config = {
  database: {
    host: process.env.DATABASE_HOST || 'localhost',
    port: parseInt(process.env.DATABASE_PORT) || 5432,
    user: process.env.DATABASE_USER,
    password: process.env.DATABASE_PASSWORD
  }
};

// 必須設定の検証
if (!config.database.user || !config.database.password) {
  console.error('Database credentials not configured');
  process.exit(1);
}
```

### トラブルシューティング
**設定が反映されない場合**:
```bash
# 1. ConfigMap確認
kubectl get configmap app-config -o yaml

# 2. Pod内での設定確認
kubectl exec -it pod-name -- env | grep DATABASE
kubectl exec -it pod-name -- cat /etc/config/app.conf

# 3. 設定変更の反映確認
kubectl describe pod pod-name | grep -A 10 "Environment"
```

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

**学習内容の解説**:
- **StatefulSetの概念**: ステートフルなアプリケーション（データベース等）の管理
- **Persistent Volume**: クラスター内での永続ストレージ抽象化
- **Storage Class**: 動的ボリュームプロビジョニングと異なるストレージタイプ
- **データベース運用**: レプリケーション、バックアップ、復旧の基本概念
- **AWS EBS統合**: EBSボリュームとKubernetesの統合

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

**学習内容の解説**:
- **ヘルスチェック設計**: liveness、readiness、startup probesの適切な使い分け
- **観測可能性**: メトリクス、ログ、トレースの3つの柱
- **Prometheus**: メトリクス収集システムの基本概念とservice discovery
- **Grafana**: 可視化ダッシュボードの作成と運用
- **アラート**: 異常検知と通知システムの構築

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

**学習内容の解説**:
- **GitOpsの概念**: Gitを単一の情報源とした宣言的インフラ管理
- **ArgoCD**: GitOpsを実現するための継続的デプロイメントツール
- **同期戦略**: 自動同期、手動同期、sync waveの使い分け
- **マニフェスト管理**: 環境別設定の管理とKustomizeの活用
- **ロールバック**: Gitベースの簡単かつ確実なロールバック機能

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

**学習内容の解説**:
- **CI/CDパイプライン**: 継続的インテグレーションと継続的デプロイメントの統合
- **GitHub Actions**: コードベースワークフローの自動化
- **セキュリティ**: シークレット管理、コンテナイメージスキャン、SAST/DAST
- **環境管理**: 複数環境（dev/staging/prod）の効率的な管理
- **承認フロー**: 本番環境への安全なデプロイメント承認プロセス

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

**学習内容の解説**:
- **マイクロサービス設計**: ドメイン駆動設計(DDD)に基づくサービス分割
- **サービスメッシュ**: Istioを使ったサービス間通信の高度な制御
- **分散トレーシング**: Jaegerによるマイクロサービス間のリクエスト追跡
- **API Gateway**: 単一エントリーポイントによるサービス統合
- **データ管理**: 各サービス専用データベースとデータ整合性の課題

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

**学習内容の解説**:
- **Zero Trust Architecture**: 「信頼せず、常に検証する」セキュリティモデル
- **RBAC**: ロールベースアクセス制御によるきめ細かい権限管理
- **Network Policy**: Pod間通信の制御とマイクロセグメンテーション
- **Pod Security Standards**: コンテナランタイムセキュリティの強化
- **シークレット管理**: AWS Secrets Manager、HashiCorp Vaultとの統合
- **コンプライアンス**: CIS Benchmark、SOC2等のセキュリティ基準への対応

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

## 📊 学習進捗管理

### 推定学習時間とマイルストーン
- **レベル1**: 1-2週間 (基礎固め)
- **レベル2**: 2-3週間 (クラウド実践)
- **レベル3**: 3-4週間 (運用技術)
- **レベル4**: 2-3週間 (自動化)
- **レベル5**: 4-6週間 (本格運用)

**合計: 12-18週間**

### 📋 学習進捗チェックリスト

#### レベル1: Kubernetes基礎
- [ ] **課題1-0**: kindクラスターセットアップ完了
- [ ] **課題1-1**: 初回Pod作成・操作完了
- [ ] **課題1-2**: Deployment/Service理解・実装完了
- [ ] **課題1-2.5**: 複数アプリケーション管理完了
- [ ] **課題1-2.6**: Ingress Controller構築完了
- [ ] **課題1-3**: カスタムアプリケーション作成完了
- [ ] **課題1-4**: 運用・デバッグ技術習得完了

**レベル1完了目安**: kubectl基本操作、YAML記述、基本トラブルシューティングができる

#### レベル2: AWS EKS入門
- [ ] **課題2-1**: EKSクラスター作成完了
- [ ] **課題2-2**: ECR連携・プライベートレジストリ活用完了
- [ ] **課題2-3**: AWS Load Balancer Controller設定完了

**レベル2完了目安**: AWS上でKubernetesクラスターを運用できる

#### レベル3: 実用的な運用機能
- [ ] **課題3-1**: ConfigMap/Secrets管理完了
- [ ] **課題3-2**: 永続ストレージ・StatefulSet実装完了
- [ ] **課題3-3**: ヘルスチェック・モニタリング構築完了

**レベル3完了目安**: 本番相当の運用設定ができる

#### レベル4: 自動化とCI/CD
- [ ] **課題4-1**: GitOpsパイプライン構築完了
- [ ] **課題4-2**: 完全自動化パイプライン実装完了

**レベル4完了目安**: 自動化されたデプロイメントパイプラインを構築できる

#### レベル5: 本格運用課題
- [ ] **課題5-1**: マイクロサービスアーキテクチャ実装完了
- [ ] **課題5-2**: セキュリティ強化実装完了

**レベル5完了目安**: エンタープライズレベルのKubernetes運用ができる

### 🎖️ 達成度バッジシステム

#### 🥉 ブロンズレベル (レベル1-2完了)
**取得スキル**: Kubernetes基礎、AWS EKS基本操作
**活用可能場面**: 開発環境構築、基本的なコンテナデプロイ

#### 🥈 シルバーレベル (レベル1-3完了)  
**取得スキル**: 実用的運用機能、設定管理、監視
**活用可能場面**: ステージング環境運用、チーム開発支援

#### 🥇 ゴールドレベル (レベル1-4完了)
**取得スキル**: 自動化、CI/CD、GitOps
**活用可能場面**: 本番環境構築、DevOps実践

#### 💎 プラチナレベル (全レベル完了)
**取得スキル**: エンタープライズ運用、セキュリティ、アーキテクチャ設計
**活用可能場面**: 大規模システム設計・運用、技術リーダーシップ

### 週次レビューテンプレート
```markdown
## 学習週次レビュー - Week [X]

### 今週完了した課題
- [ ] 課題名1
- [ ] 課題名2

### 学んだ重要な概念
1. 
2. 
3. 

### 躓いた箇所と解決方法
- 問題: 
- 解決策: 

### 来週の学習計画
- 目標課題: 
- 重点学習項目: 

### 理解度自己評価 (1-5)
- 概念理解: /5
- 実装能力: /5  
- 運用判断: /5
```

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

## 学習後のクリーンアップ

### ローカル環境（kind）のクリーンアップ

**レベル1学習後の推奨クリーンアップ手順**

```bash
# 1. アプリケーションリソースの削除（課題完了後）
kubectl delete deployment --all
kubectl delete service --all --ignore-not-found
kubectl delete configmap --all --ignore-not-found
kubectl delete ingress --all --ignore-not-found

# 2. クラスター全体の削除（学習終了時）
kind delete cluster --name [CLUSTER_NAME]

# 例：マルチノードクラスターの削除
kind delete cluster --name multi-node-cluster

# 3. 削除確認
kind get clusters
docker ps --filter name=kind
```

**段階的クリーンアップ（課題ごと）**

```bash
# 課題1-2.5完了後
kubectl delete -f 04-web-application/test-apps.yaml
kubectl delete -f 04-web-application/simple-ingress-demo.yaml

# 課題1-2.6完了後  
kubectl delete -f 05-ingress-controller/ingress-demo.yaml
kubectl delete -f 05-ingress-controller/sample-app.yaml
kubectl delete -f 05-ingress-controller/nginx-ingress-controller.yaml

# またはHelmでインストールした場合
helm uninstall ingress-nginx -n ingress-nginx
kubectl delete namespace ingress-nginx
```

### AWS環境のクリーンアップ

**レベル2以降（AWS EKS）の学習後**

```bash
# EKSクラスターの削除
eksctl delete cluster --name my-first-cluster --region ap-northeast-1

# ECRリポジトリの削除
aws ecr delete-repository --repository-name my-node-app --region ap-northeast-1 --force

# CloudFormationスタックの確認・削除
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE
```

### 注意事項

- **kindクラスター**: ローカルリソースのみ使用、削除は安全
- **AWS EKS**: **課金が発生**するため、学習完了後は必ず削除
- **段階的削除**: 各課題完了後にアプリケーションリソースのみ削除し、クラスターは次の課題で再利用可能
- **完全削除**: 学習終了時にクラスター全体を削除

### クリーンアップ確認

```bash
# ローカル環境の確認
kind get clusters
kubectl config get-contexts
docker ps --filter name=kind

# AWS環境の確認
aws eks list-clusters --region ap-northeast-1
aws ecr describe-repositories --region ap-northeast-1
```

## 🔧 よくある質問とトラブルシューティング

### Q1: kind クラスター作成時のエラー
**Q**: `kind create cluster` でエラーが発生する
**A**: 以下を確認：
```bash
# Dockerが起動しているか確認
docker ps

# 既存のkindクラスターが残っていないか確認
kind get clusters
kind delete cluster --name [古いクラスター名]

# ポート競合の確認
lsof -i :80  # macOS/Linux
netstat -ano | findstr :80  # Windows
```

### Q2: kubectl コマンドが認識されない
**Q**: `kubectl: command not found`
**A**: kubectl のインストールと設定：
```bash
# macOS (Homebrew)
brew install kubectl

# Windows (Chocolatey)
choco install kubernetes-cli

# 設定確認
kubectl config current-context
kubectl config get-contexts
```

### Q3: AWS認証エラー
**Q**: EKS課題で認証エラーが発生
**A**: AWS認証の確認：
```bash
# 認証情報確認
aws sts get-caller-identity

# 必要な権限
# - EKS Full Access
# - EC2 Full Access  
# - IAM Limited Access
# - CloudFormation Access

# プロファイル設定
aws configure list
export AWS_PROFILE=your-profile
```

### Q4: イメージプルエラー
**Q**: `ImagePullBackOff` エラーが発生
**A**: 原因別の対処法：
```bash
# 1. イメージ名の確認
kubectl describe pod [POD_NAME]

# 2. kindでのローカルイメージ
kind load docker-image [IMAGE_NAME] --name [CLUSTER_NAME]

# 3. プライベートレジストリの認証
kubectl create secret docker-registry regcred \
  --docker-server=[REGISTRY_URL] \
  --docker-username=[USERNAME] \
  --docker-password=[PASSWORD]
```

### Q5: ネットワーク接続問題
**Q**: Pod間通信ができない
**A**: ネットワーク診断手順：
```bash
# DNS確認
kubectl exec -it [POD_NAME] -- nslookup kubernetes.default

# Service確認
kubectl get endpoints [SERVICE_NAME]

# Pod IPの確認
kubectl get pods -o wide

# ファイアウォール確認（企業ネットワーク）
telnet [SERVICE_IP] [PORT]
```

## 📚 参考資料とさらなる学習

### 公式ドキュメント
- [Kubernetes公式ドキュメント](https://kubernetes.io/docs/)
- [AWS EKS ユーザーガイド](https://docs.aws.amazon.com/eks/)
- [Docker公式ドキュメント](https://docs.docker.com/)

### 推奨書籍
- 「Kubernetes完全ガイド」青山真也著
- 「Kubernetes実践ガイド」磯賢大著  
- 「SRE サイトリライアビリティエンジニアリング」Google SREチーム著

### オンライン学習リソース
- [Kubernetes Academy](https://kube.academy/)
- [AWS Training and Certification](https://aws.amazon.com/training/)
- [CNCF Certification](https://www.cncf.io/certification/cka/)

### コミュニティ
- [Kubernetes Slack](https://slack.k8s.io/)
- [CNCF Events](https://events.cncf.io/)
- [AWS User Groups](https://aws.amazon.com/developer/community/usergroups/)

## 🏆 次のステップ

### 認定試験への挑戦
- **CKA (Certified Kubernetes Administrator)**: Kubernetes管理者認定
- **CKAD (Certified Kubernetes Application Developer)**: Kubernetes開発者認定
- **AWS Certified DevOps Engineer**: AWS DevOps実践認定

### 実践プロジェクト案
1. **個人ブログのKubernetes化**: 既存アプリケーションの移行体験
2. **マイクロサービスECサイト**: フルスタック開発でのKubernetes活用
3. **オープンソースプロジェクト貢献**: Kubernetes関連ツールの開発参加

---

**サポート情報**: 各課題で困ったことがあれば、具体的なエラーメッセージや状況と併せて以下の情報を収集してお問い合わせください：
- OS とバージョン
- Kubernetes バージョン (`kubectl version`)
- Docker バージョン (`docker version`)
- エラーが発生した具体的な手順