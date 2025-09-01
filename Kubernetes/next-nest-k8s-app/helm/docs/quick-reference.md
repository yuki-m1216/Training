# Helm クイックリファレンス

## 今回のプロジェクトで使用した主要コマンド

### セットアップ
```bash
# 1. kindクラスターの作成
kind create cluster --config k8s/kind-config.yaml

# 2. NGINX Ingress Controllerのインストール
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# 3. Ingress Controller起動確認
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

# 4. Dockerイメージのビルド
docker build -t next-nest-k8s-app-backend:latest ./backend
docker build -t next-nest-k8s-app-frontend:latest ./frontend

# 5. kindへイメージをロード
kind load docker-image next-nest-k8s-app-backend:latest
kind load docker-image next-nest-k8s-app-frontend:latest

# 6. PostgreSQLのデプロイ（外部）
kubectl apply -f k8s/postgres-config.yaml
kubectl apply -f k8s/postgres.yaml
```

### Helmの基本操作
```bash
# インストール
helm install my-app ./next-nest-app \
  --set postgresql.enabled=false \
  --set backend.image.pullPolicy=Never \
  --set frontend.image.pullPolicy=Never

# 状態確認
helm list
helm status my-app

# アップグレード
helm upgrade my-app ./next-nest-app --reuse-values

# アンインストール
helm uninstall my-app
```

### トラブルシューティング用コマンド
```bash
# Pod状態確認
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>

# サービス確認
kubectl get svc
kubectl get endpoints

# Ingress確認
kubectl get ingress
kubectl describe ingress

# 生成されたマニフェスト確認
helm get manifest my-app

# Dry-runでデバッグ
helm install my-app ./next-nest-app --dry-run --debug
```

## values.yaml 主要設定項目

```yaml
# PostgreSQL設定（外部利用時はenabled: false）
postgresql:
  enabled: false  # 外部PostgreSQL使用
  auth:
    username: nestjs_user
    password: nestjs_password
    database: nestjs_app

# バックエンド設定
backend:
  enabled: true
  replicaCount: 2
  image:
    repository: next-nest-k8s-app-backend
    tag: latest
    pullPolicy: Never  # kindではNever、本番はAlways

# フロントエンド設定
frontend:
  enabled: true
  replicaCount: 2
  image:
    repository: next-nest-k8s-app-frontend
    tag: latest
    pullPolicy: Never

# Ingress設定
ingress:
  enabled: true
  className: nginx
```

## ファイル構造

```
helm/
├── next-nest-app/
│   ├── Chart.yaml              # チャート情報
│   ├── values.yaml             # デフォルト値
│   ├── README.md              # チャートドキュメント
│   └── templates/
│       ├── _helpers.tpl        # ヘルパー関数
│       ├── backend-deployment.yaml
│       ├── backend-service.yaml
│       ├── frontend-deployment.yaml
│       ├── frontend-service.yaml
│       ├── ingress.yaml        # デュアルIngress構成
│       └── NOTES.txt          # インストール後メッセージ
└── docs/
    ├── helm-tutorial-for-beginners.md  # 初学者向けガイド
    ├── helm-troubleshooting-guide.md   # トラブルシューティング
    └── quick-reference.md              # このファイル
```

## 重要な設定ポイント

### 1. DATABASE_URL環境変数
```yaml
# backend-deployment.yaml
env:
- name: DATABASE_URL
  value: "postgresql://{{ .Values.postgresql.auth.username }}:{{ .Values.postgresql.auth.password }}@{{ include "next-nest-app.postgresql.servicename" . }}:{{ .Values.postgresql.service.port }}/{{ .Values.postgresql.auth.database }}"
```

### 2. デュアルIngress構成
- **メインIngress**: 静的ファイル配信用（rewriteなし）
- **API Ingress**: バックエンドAPI用（rewrite-target使用）

### 3. imagePullPolicy
- **kind環境**: `Never`（ローカルイメージ使用）
- **本番環境**: `Always`（最新イメージ取得）

## アクセスURL

| コンポーネント | URL |
|-------------|-----|
| アプリケーション | http://localhost/ |
| API | http://localhost/api/users |
| ヘルスチェック | http://localhost/api/users |