# Project 02: リアルタイムチャットアプリ

Socket.ioを使用したリアルタイムメッセージングアプリケーションのKubernetesデプロイ

## 技術スタック

- **Frontend**: Next.js 15 + TypeScript + Socket.io-client
- **Backend**: NestJS + Socket.io + Redis Adapter
- **Database**: Redis (StatefulSet)
- **Orchestration**: Kubernetes (Kind)
- **Configuration**: Kustomize

## アーキテクチャ

```
┌─────────────┐
│   Ingress   │ (nginx-ingress-controller)
└──────┬──────┘
       │
       ├──────────────┬───────────────┬──────────────┐
       │              │               │              │
   /socket.io       /api           /health          /
       │              │               │              │
       ▼              ▼               ▼              ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│   Backend    │ │   Backend    │ │   Backend    │ │  Frontend    │
│  (NestJS)    │ │  (NestJS)    │ │  (NestJS)    │ │  (Next.js)   │
│   Port:3000  │ │   Port:3000  │ │   Port:3000  │ │   Port:3001  │
└──────┬───────┘ └──────┬───────┘ └──────┬───────┘ └──────────────┘
       │                │                │
       └────────────────┴────────────────┘
                        │
                        ▼
                ┌──────────────┐
                │    Redis     │
                │ (StatefulSet)│
                │   Port:6379  │
                └──────────────┘
```

## ディレクトリ構成

```
project-02-chat-app/
├── frontend/                    # Next.js フロントエンド
│   ├── app/                    # App Router
│   ├── hooks/                  # useSocket カスタムフック
│   ├── types/                  # TypeScript型定義
│   ├── Dockerfile              # 本番用
│   └── Dockerfile.dev          # 開発用
├── backend/                     # NestJS バックエンド
│   ├── src/
│   │   ├── chat/              # WebSocketゲートウェイ
│   │   └── app.controller.ts  # HTTPエンドポイント
│   ├── Dockerfile              # 本番用
│   └── Dockerfile.dev          # 開発用
├── k8s/                        # Kubernetes マニフェスト
│   ├── base/                   # 基本リソース
│   │   ├── backend-deployment.yaml
│   │   ├── backend-service.yaml
│   │   ├── frontend-deployment.yaml
│   │   ├── frontend-service.yaml
│   │   ├── redis-statefulset.yaml
│   │   ├── redis-service.yaml
│   │   ├── configmap.yaml
│   │   ├── secret.yaml
│   │   ├── ingress.yaml
│   │   └── kustomization.yaml
│   └── overlays/               # 環境別設定
│       └── dev/
│           ├── kustomization.yaml
│           └── patches/
│               ├── configmap-patch.yaml
│               ├── backend-resources.yaml
│               └── frontend-resources.yaml
├── docker-compose.yaml         # ローカル開発用
├── kind-config.yaml            # Kindクラスタ設定
└── README.md
```

## 実装フェーズ

### ✅ Phase 1: ローカル環境でのアプリケーション開発

#### 実施内容
- NestJSでWebSocketゲートウェイ実装
- Next.js 15でチャットUI実装
- Socket.io-clientでリアルタイム通信
- Redisアダプター統合（水平スケーリング対応）

#### コマンド
```bash
# ローカル起動
docker-compose up --build

# 動作確認
# Frontend: http://localhost:3001
# Backend: http://localhost:3000
# Redis: localhost:6379
```

#### 遭遇した問題と解決
- **TypeScript設定エラー**: `backend/tsconfig.json`の`ignoreDeprecations: "6.0"`を削除
- **メッセージ履歴が保持されない**: `frontend/app/chat/page.tsx`のjoinRoom時の`setMessages([])`をコメントアウト

---

### ✅ Phase 2-1: Kubernetesマニフェスト作成

#### 実施内容
- Deployment, Service, ConfigMap, Secret, StatefulSetの作成
- Redisは StatefulSet + Headless Service で永続化
- Backend/Frontendは Deployment + ClusterIP Service

#### 重要な設定

**Redis StatefulSet**
```yaml
# PersistentVolumeClaimで永続化
volumeClaimTemplates:
  - metadata:
      name: redis-data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 1Gi
```

**Backend Service (WebSocket用)**
```yaml
# SessionAffinityでスティッキーセッション
spec:
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 3600
```

#### 遭遇した問題と解決
- **Redis イメージタグの空白**: `image: redis: 7-alpine` → `image: redis:7-alpine`
- **command vs commands**: `commands:` → `command:` (単数形が正しい)
- **Frontend Serviceポート不一致**: 3000 → 3001に修正

---

### ✅ Phase 2-2: Kustomize環境別設定

#### 実施内容
- base/overlays構造の構築
- Dev環境用の設定オーバーライド
- リソース制限とレプリカ数の調整

#### ディレクトリ構成
```
k8s/
├── base/              # 共通設定
└── overlays/
    └── dev/           # Dev環境
        ├── kustomization.yaml
        └── patches/   # 差分設定
```

#### Dev環境の設定
```yaml
# k8s/overlays/dev/kustomization.yaml
namePrefix: dev-
namespace: chat-app-dev
replicas:
  - name: backend
    count: 1
  - name: frontend
    count: 1
```

#### 遭遇した問題と解決
- **commonLabels非推奨警告**: `commonLabels` → `labels` + `pairs`形式に変更

---

### ✅ Phase 2-3: Kustomize検証

#### 実施内容
- Kustomizeビルドの検証
- YAMLファイルの構文チェック

#### コマンド
```bash
# Kustomizeビルド確認
cd k8s/overlays/dev
kubectl kustomize . > /tmp/kustomize-output.yaml

# 構文チェック
kubectl kustomize . | kubectl apply --dry-run=client -f -
```

---

### ✅ Phase 2-4: Kubernetesへのデプロイ

#### 実施内容
- Kindクラスタへのデプロイ
- Dockerイメージのビルドとロード
- 動作確認

#### コマンド
```bash
# Namespaceの作成
kubectl create namespace chat-app-dev

# イメージのビルド
docker-compose build

# イメージをKindにロード
kind load docker-image project-02-chat-app-frontend:latest --name chat-app
kind load docker-image project-02-chat-app-backend:latest --name chat-app

# デプロイ
kubectl apply -k k8s/overlays/dev

# 確認
kubectl get all -n chat-app-dev
```

#### 遭遇した問題と解決

**1. Redis接続タイムアウト**
- **原因**: ConfigMapの`REDIS_URL`が`redis://redis:6379`だが、実際のService名は`dev-redis`
- **解決**: `k8s/overlays/dev/patches/configmap-patch.yaml`で`REDIS_URL: "redis://dev-redis:6379"`を追加

**2. WebSocket接続エラー**
- **原因**: Frontendのみport-forward、Backendへの接続がない
- **解決**: Backendもport-forward
```bash
# Frontend
kubectl port-forward -n chat-app-dev service/dev-frontend 3001:3001

# Backend (別ターミナル)
kubectl port-forward -n chat-app-dev service/dev-backend 3000:3000
```

**3. Backend Health Checkでcurlが見つからない**
- **原因**: Alpineイメージにcurlが含まれていない
- **解決**: 一時Podでテスト
```bash
kubectl run test-curl --image=curlimages/curl:latest --rm -it --restart=Never \
  -- curl http://dev-backend.chat-app-dev:3000/health
```

---

### ✅ Phase 3-2: Ingress設定

#### 実施内容
- nginx-ingress-controllerのインストール
- ホスト名なしのIngress設定（localhost直接アクセス）
- WebSocket通信のIngress経由での実現
- Kindクラスタのポートマッピング設定

#### Kindクラスタの再構築

**kind-config.yaml**
```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: chat-app
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 80
  - containerPort: 30443
    hostPort: 443
```

**クラスタ再作成**
```bash
# 既存クラスタ削除
kind delete cluster --name chat-app

# ポートマッピング付きで再作成
kind create cluster --config kind-config.yaml
```

#### Ingress Controllerのインストール

```bash
# Kind専用版をインストール
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# NodePortを明示的に指定
kubectl patch service ingress-nginx-controller -n ingress-nginx --type='json' -p='[
  {"op": "replace", "path": "/spec/ports/0/nodePort", "value": 30080},
  {"op": "replace", "path": "/spec/ports/1/nodePort", "value": 30443}
]'

# 準備完了を待機
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

#### Ingress設定

**k8s/base/ingress.yaml**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: chat-ingress
  annotations:
    nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
    nginx.ingress.kubernetes.io/websocket-services: backend
spec:
  ingressClassName: nginx
  rules:
    - http:  # ホスト名なし
        paths:
        - path: /socket.io
          pathType: Prefix
          backend:
            service:
              name: backend
              port:
                number: 3000
        - path: /api
          pathType: Prefix
          backend:
            service:
              name: backend
              port:
                number: 3000
        - path: /health
          pathType: Prefix
          backend:
            service:
              name: backend
              port:
                number: 3000
        - path: /
          pathType: Prefix
          backend:
            service:
              name: frontend
              port:
                number: 3001
```

#### フロントエンドのビルド修正

**問題**: Next.jsの`NEXT_PUBLIC_*`環境変数はビルド時に埋め込まれるため、Kubernetes環境用のイメージが必要

**frontend/Dockerfile修正**
```dockerfile
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# ビルド時の環境変数を受け取る
ARG NEXT_PUBLIC_SOCKET_URL
ARG NEXT_PUBLIC_API_URL

# 環境変数を設定
ENV NEXT_TELEMETRY_DISABLED=1
ENV NEXT_PUBLIC_SOCKET_URL=${NEXT_PUBLIC_SOCKET_URL}
ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}

RUN npm run build
```

**イメージのビルドとデプロイ**
```bash
# 本番用イメージをビルド
cd frontend
docker build \
  --build-arg NEXT_PUBLIC_SOCKET_URL=http://localhost \
  --build-arg NEXT_PUBLIC_API_URL=http://localhost/api \
  -t project-02-chat-app-frontend:latest \
  .

# Kindにロード
kind load docker-image project-02-chat-app-frontend:latest --name chat-app

# デプロイ
cd ..
kubectl apply -k k8s/overlays/dev

# Frontendを再起動
kubectl rollout restart deployment/dev-frontend -n chat-app-dev
```

#### 遭遇した問題と解決

**1. NodePortでアクセスできない**
- **原因**: Kindクラスタがポートマッピングなしで作成されていた
- **解決**: `kind-config.yaml`でポートマッピングを設定し、クラスタを再作成

**2. WebSocket 502エラー**
- **原因**: `nginx.ingress.kubernetes.io/rewrite-target: /`が全パスに適用され、`/socket.io`が`/`に書き換えられた
- **解決**: `rewrite-target`アノテーションを削除

**3. フロントエンドが古い環境変数を使用**
- **原因**: Next.jsのビルドキャッシュに古い`NEXT_PUBLIC_SOCKET_URL`が残っていた
- **解決**: 本番用Dockerfileで`ARG`と`ENV`を追加し、ビルド時に環境変数を埋め込み

#### 動作確認

```bash
# HTTPアクセス
curl http://localhost/              # Frontend
curl http://localhost/api           # Backend API
curl http://localhost/health        # Backend Health

# ブラウザでアクセス
http://localhost
```

**成功確認**:
- ✅ WebSocket接続成功
- ✅ チャットルーム参加
- ✅ メッセージ送受信
- ✅ Redisアダプター有効化

---

### ✅ Phase 3-1: HPA (Horizontal Pod Autoscaler)

#### 実施内容
- Metrics Serverのインストールと設定
- Backend/Frontend用のHPA作成
- 負荷テストによる自動スケーリング検証
- 複数ポッド間でのRedis Adapter動作確認

#### Metrics Serverのインストール

**Kind環境用の設定**
```bash
# Metrics Serverをインストール
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Kind環境ではTLS検証を無効化する必要がある
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/args/-",
    "value": "--kubelet-insecure-tls"
  }
]'

# 準備完了を待機
kubectl wait --for=condition=available --timeout=60s deployment/metrics-server -n kube-system

# メトリクス確認
kubectl top nodes
kubectl top pods -n chat-app-dev
```

#### HPA設定

**Backend HPA** ([k8s/base/backend-hpa.yaml](k8s/base/backend-hpa.yaml)):
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend
  minReplicas: 1
  maxReplicas: 5
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 60
      policies:
        - type: Percent
          value: 50
          periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
        - type: Percent
          value: 100
          periodSeconds: 30
        - type: Pods
          value: 2
          periodSeconds: 30
      selectPolicy: Max
```

**Frontend HPA** ([k8s/base/frontend-hpa.yaml](k8s/base/frontend-hpa.yaml)):
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: frontend-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: frontend
  minReplicas: 1
  maxReplicas: 3
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
```

**設定のポイント**:
- `minReplicas: 1`: 通常時は1ポッドで動作（コスト効率）
- `maxReplicas: 5/3`: Backend最大5、Frontend最大3
- `averageUtilization: 50`: CPU使用率50%を超えるとスケールアウト
- `scaleUp behavior`: 即座にスケールアウト、最大100%または2ポッド増
- `scaleDown behavior`: 60秒の安定化期間後、50%ずつスケールイン

#### デプロイと確認

```bash
# kustomization.yamlにHPAを追加済み
kubectl apply -k k8s/overlays/dev

# HPA状態確認
kubectl get hpa -n chat-app-dev
kubectl describe hpa -n chat-app-dev
```

#### 負荷テストの実施

**Podを使った負荷生成**:
```bash
# 監視用（別ターミナル）
watch -n 2 'kubectl get hpa -n chat-app-dev && echo "---" && kubectl get pods -n chat-app-dev'

# 負荷生成
kubectl run load-generator \
  --image=jordi/ab \
  --rm -it --restart=Never \
  -- -n 5000 -c 50 http://dev-backend.chat-app-dev:3000/health
```

**観察された動作**:
1. 負荷開始 → CPU使用率が50%超過
2. 約30秒後 → Backend Podが 1 → 3 にスケールアウト
3. 負荷停止 → CPU使用率低下
4. 60秒安定化期間後 → Backend Podが 3 → 1 にスケールイン

#### Redis Adapterの動作確認

**複数ポッド間でのWebSocket通信テスト**:

```bash
# テスト用にminReplicasを2に設定
kubectl patch hpa dev-backend-hpa -n chat-app-dev --type='json' \
  -p='[{"op": "replace", "path": "/spec/minReplicas", "value": 2}]'

# 両ポッドでRedis Adapterが有効か確認
kubectl logs -n chat-app-dev -l app=backend --tail=50 | grep -E "(Redis adapter|Failed to setup)"
```

**期待される結果**:
```
Redis adapter enabled for WebSocket scaling
Redis adapter enabled for WebSocket scaling
```

**ブラウザテスト結果**:
- User1がPod1に接続: `dev-backend-77b4996559-pd9l5`
- User2がPod2に接続: `dev-backend-77b4996559-rwxh8`
- User2がメッセージ送信 → Redis Pub/Sub経由でPod1に配信 → User1が受信
- ✅ 複数ポッド間でのWebSocket通信が正常に動作

**接続先の確認方法**:
```bash
# 各ポッドのログで接続履歴を確認
kubectl logs -n chat-app-dev <pod-name> | grep -E "(Client connected|joined room)"
```

#### 遭遇した問題と解決

**1. 古いポッドでRedis接続エラー**
- **問題**: 4日前に起動した古いポッドでRedis接続タイムアウトが残っていた
- **原因**: 以前のRedis設定ミス時のポッドがそのまま稼働
- **解決**: 古いポッドを削除して再起動
```bash
kubectl delete pod <old-pod-name> -n chat-app-dev
```

**2. SessionAffinityの影響**
- **発見**: Backend ServiceにはsessionAffinity: ClientIPが設定されている
- **動作**: Playwrightで2つのタブを開くと、異なるWebSocketコネクションとして扱われ、異なるポッドに振り分けられた
- **結果**: テストに影響なく、Redis Adapterの動作を確認できた

#### クリーンアップ

```bash
# minReplicasを元に戻す
kubectl patch hpa dev-backend-hpa -n chat-app-dev --type='json' \
  -p='[{"op": "replace", "path": "/spec/minReplicas", "value": 1}]'
```

---

## 現在の状態

### デプロイ済みリソース

```bash
# 確認コマンド
kubectl get all -n chat-app-dev
kubectl get ingress -n chat-app-dev
```

### アクセス方法

**Ingress経由（推奨）**
```
http://localhost/          # チャットアプリ
http://localhost/api       # バックエンドAPI
http://localhost/health    # ヘルスチェック
```

**Port Forward（デバッグ用）**
```bash
# Frontend
kubectl port-forward -n chat-app-dev service/dev-frontend 3001:3001

# Backend
kubectl port-forward -n chat-app-dev service/dev-backend 3000:3000
```

---

## 学習ポイント

### WebSocket + Kubernetes
- SessionAffinityによるスティッキーセッション
- Redisアダプターによる水平スケーリング対応
- Ingress経由でのWebSocket通信

### Next.js + Kubernetes
- `NEXT_PUBLIC_*`環境変数のビルド時埋め込み
- 本番用Dockerfileでの`ARG`/`ENV`の使い分け
- 開発モードと本番モードのイメージの違い

### Kustomize
- base/overlays構造による環境管理
- patchesによる差分適用
- namePrefix/namespaceによる環境分離

### Ingress
- Kind環境でのポートマッピング設定
- WebSocket通信のための特殊設定
- rewrite-targetの注意点

### StatefulSet
- PersistentVolumeClaimによる永続化
- Headless Serviceとの組み合わせ
- Redisのデータ永続性確保

### HPA (Horizontal Pod Autoscaler)
- Metrics Serverによるリソースメトリクス収集
- CPU使用率ベースの自動スケーリング
- スケールアウト/スケールインのbehavior設定
- 複数ポッド環境でのWebSocket接続管理

---

## プロジェクト完了状況

このプロジェクトで完了した内容：
- ✅ **Phase 1**: ローカル環境でのアプリケーション開発
- ✅ **Phase 2-1**: Kubernetesマニフェスト作成
- ✅ **Phase 2-2**: Kustomize環境別設定
- ✅ **Phase 2-3**: Kustomize検証
- ✅ **Phase 2-4**: Kubernetesへのデプロイ
- ✅ **Phase 3-1**: HPA (Horizontal Pod Autoscaler)
- ✅ **Phase 3-2**: Ingress設定

**Note**: Prometheus/GrafanaなどのMonitoring、EFK StackなどのLoggingは、より高度な学習項目として **Project 6: データ分析ダッシュボード** で実施します。このプロジェクトでは、WebSocketアプリケーションの水平スケーリングとIngress設定に焦点を当てました。

---

## トラブルシューティング

### Podが起動しない

```bash
# ログ確認
kubectl logs -n chat-app-dev <pod-name>

# イベント確認
kubectl describe pod -n chat-app-dev <pod-name>

# イメージの確認
docker images | grep project-02-chat-app
```

### WebSocketが接続できない

1. ブラウザの開発者ツールでコンソールエラーを確認
2. Backend Podのログを確認
```bash
kubectl logs -n chat-app-dev deployment/dev-backend
```
3. Ingress設定を確認
```bash
kubectl describe ingress -n chat-app-dev dev-chat-ingress
```

### Redisに接続できない

```bash
# Redisの動作確認
kubectl exec -n chat-app-dev dev-redis-0 -- redis-cli ping

# ConfigMapの確認
kubectl get configmap -n chat-app-dev dev-chat-config -o yaml
```

### HPAが動作しない

```bash
# Metrics Serverが動作しているか確認
kubectl get deployment -n kube-system metrics-server

# メトリクスが取得できるか確認
kubectl top nodes
kubectl top pods -n chat-app-dev

# HPAの状態確認
kubectl describe hpa -n chat-app-dev

# Kind環境の場合、TLS検証無効化が必要
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[
  {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}
]'
```

---

## 参考リンク

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kustomize Documentation](https://kubectl.docs.kubernetes.io/references/kustomize/)
- [Ingress-NGINX Controller](https://kubernetes.github.io/ingress-nginx/)
- [Kind Documentation](https://kind.sigs.k8s.io/)
- [Next.js Documentation](https://nextjs.org/docs)
- [NestJS Documentation](https://docs.nestjs.com/)
- [Socket.io Documentation](https://socket.io/docs/)
