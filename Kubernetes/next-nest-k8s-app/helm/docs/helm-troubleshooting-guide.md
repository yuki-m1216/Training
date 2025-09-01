# Helmトラブルシューティングガイド

## このプロジェクトで実際に発生した問題と解決方法

### 1. Docker イメージ名の不一致

#### 症状
```bash
kubectl get pods
NAME                                          READY   STATUS             RESTARTS   AGE
my-app-next-nest-app-backend-5d4f8b9f5-8xkzq   0/1     ImagePullBackOff   0          2m
```

#### 原因
values.yamlのイメージ名と実際のDockerイメージ名が異なる

#### 診断方法
```bash
# Podの詳細を確認
kubectl describe pod my-app-next-nest-app-backend-5d4f8b9f5-8xkzq

# エラーメッセージ例
Failed to pull image "next-nest-frontend:latest": 
rpc error: code = Unknown desc = failed to pull and unpack image
```

#### 解決方法
```bash
# 1. ローカルのDockerイメージを確認
docker images | grep next-nest

# 出力例
next-nest-k8s-app-frontend   latest   abc123   2 hours ago   500MB
next-nest-k8s-app-backend    latest   def456   2 hours ago   300MB

# 2. values.yamlを修正
backend:
  image:
    repository: next-nest-k8s-app-backend  # 正しい名前に修正
    
frontend:
  image:
    repository: next-nest-k8s-app-frontend  # 正しい名前に修正

# 3. Helmをアップグレード
helm upgrade my-app ./next-nest-app --reuse-values
```

---

### 2. CreateContainerConfigError - Secret not found

#### 症状
```bash
kubectl get pods
NAME                                          READY   STATUS                       RESTARTS   AGE
my-app-next-nest-app-backend-5d4f8b9f5-8xkzq   0/1     CreateContainerConfigError   0          1m
```

#### 原因
PostgreSQLのSecretが存在しない、または名前が間違っている

#### 診断方法
```bash
# Podのイベントを確認
kubectl describe pod my-app-next-nest-app-backend-5d4f8b9f5-8xkzq

# エラーメッセージ例
Error: secret "my-app-next-nest-app-postgresql" not found
```

#### 解決方法

##### 方法1: Secretを手動で作成
```bash
kubectl create secret generic my-app-next-nest-app-postgresql \
  --from-literal=postgres-password=postgres_password \
  --from-literal=password=nestjs_password
```

##### 方法2: テンプレートにSecretを追加
```yaml
# templates/postgresql-secret.yaml
{{- if not .Values.postgresql.existingSecret }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "next-nest-app.fullname" . }}-postgresql
type: Opaque
stringData:
  postgres-password: {{ .Values.postgresql.auth.postgresPassword }}
  password: {{ .Values.postgresql.auth.password }}
{{- end }}
```

---

### 3. CrashLoopBackOff - データベース接続エラー

#### 症状
```bash
kubectl get pods
NAME                                          READY   STATUS             RESTARTS   AGE
my-app-next-nest-app-backend-5d4f8b9f5-8xkzq   0/1     CrashLoopBackOff   5          10m
```

#### 原因
バックエンドがPostgreSQLに接続できない

#### 診断方法
```bash
# Podのログを確認
kubectl logs my-app-next-nest-app-backend-5d4f8b9f5-8xkzq

# エラーメッセージ例
Error: connect ECONNREFUSED 10.96.100.50:5432
# または
Error: getaddrinfo ENOTFOUND postgres
```

#### 解決方法

##### 1. PostgreSQLサービス名を確認
```bash
# サービス一覧を確認
kubectl get svc

# 出力例
NAME                              TYPE        CLUSTER-IP      PORT(S)
postgres-service                  ClusterIP   10.96.100.50    5432/TCP
my-app-next-nest-app-backend     ClusterIP   10.96.200.10    3001/TCP
```

##### 2. _helpers.tplでサービス名を修正
```yaml
{{- define "next-nest-app.postgresql.servicename" -}}
{{- if .Values.postgresql.enabled }}
{{- .Release.Name }}-postgresql
{{- else }}
postgres-service  {{/* 実際のサービス名に合わせる */}}
{{- end }}
{{- end }}
```

##### 3. DATABASE_URL環境変数を確認
```bash
# デプロイされたPodの環境変数を確認
kubectl exec my-app-next-nest-app-backend-xxx -- env | grep DATABASE

# 正しい形式
DATABASE_URL=postgresql://nestjs_user:nestjs_password@postgres-service:5432/nestjs_app
```

---

### 4. 静的ファイルが404 - Ingress設定の問題

#### 症状
- ブラウザで「Loading...」と表示される
- JavaScriptファイルが404エラー
- コンソールに「Unexpected token '<'」エラー

#### 原因
Ingressのrewrite-targetがすべてのパスに適用され、静的ファイルのパスも書き換えられる

#### 診断方法
```bash
# ブラウザの開発者ツールで確認
# Network タブで _next/static/*.js が404または HTMLを返している

# curlで確認
curl http://localhost/_next/static/chunks/main.js
# HTMLが返ってくる場合は設定ミス
```

#### 解決方法: デュアルIngress構成

```yaml
# templates/ingress.yaml
---
# メインIngress（静的ファイル用 - rewriteなし）
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "next-nest-app.fullname" . }}-ingress
spec:
  ingressClassName: nginx
  rules:
    - host: localhost
      http:
        paths:
        - path: /api
          pathType: Prefix
          backend:
            service:
              name: {{ include "next-nest-app.fullname" . }}-backend
              port:
                number: 3001
        - path: /
          pathType: Prefix
          backend:
            service:
              name: {{ include "next-nest-app.fullname" . }}-frontend
              port:
                number: 3000
---
# API専用Ingress（rewriteあり）
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "next-nest-app.fullname" . }}-ingress-api
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  ingressClassName: nginx
  rules:
    - host: localhost
      http:
        paths:
        - path: /api(/|$)(.*)
          pathType: ImplementationSpecific
          backend:
            service:
              name: {{ include "next-nest-app.fullname" . }}-backend
              port:
                number: 3001
```

---

### 5. ヘルスチェック失敗

#### 症状
```bash
# Podが定期的に再起動する
kubectl get pods
NAME                                          READY   STATUS    RESTARTS   AGE
my-app-next-nest-app-backend-5d4f8b9f5-8xkzq   1/1     Running   3          10m
```

#### 原因
ヘルスチェックのパスが存在しない

#### 診断方法
```bash
# イベントを確認
kubectl describe pod my-app-next-nest-app-backend-xxx

# エラーメッセージ例
Liveness probe failed: HTTP probe failed with statuscode: 404
```

#### 解決方法
```yaml
# values.yaml
backend:
  healthCheck:
    liveness:
      path: /users  # 存在するエンドポイントを使用
    readiness:
      path: /users  # 存在するエンドポイントを使用
```

---

## デバッグのベストプラクティス

### 1. Dry-runで事前確認
```bash
# インストール前に生成されるマニフェストを確認
helm install my-app ./next-nest-app --dry-run --debug > debug.yaml

# 問題を探す
grep -n "ERROR\|WARNING" debug.yaml
```

### 2. 段階的なデプロイ
```bash
# まずPostgreSQLだけデプロイ
helm install my-app ./next-nest-app \
  --set backend.enabled=false \
  --set frontend.enabled=false

# PostgreSQLが正常に起動したらバックエンドを追加
helm upgrade my-app ./next-nest-app \
  --set backend.enabled=true \
  --set frontend.enabled=false

# 最後にフロントエンドを追加
helm upgrade my-app ./next-nest-app --reuse-values \
  --set frontend.enabled=true
```

### 3. ログの確認方法
```bash
# Pod一覧を確認
kubectl get pods

# 特定のPodのログを確認
kubectl logs <pod-name>

# 前回のコンテナのログ（再起動した場合）
kubectl logs <pod-name> --previous

# リアルタイムでログを追跡
kubectl logs -f <pod-name>

# 複数のPodのログを同時に確認
kubectl logs -l app=backend --tail=50
```

### 4. Pod内部での確認
```bash
# Pod内部でシェルを起動
kubectl exec -it <pod-name> -- /bin/sh

# 環境変数を確認
kubectl exec <pod-name> -- env

# ネットワーク接続を確認
kubectl exec <pod-name> -- nc -zv postgres-service 5432

# DNSを確認
kubectl exec <pod-name> -- nslookup postgres-service
```

### 5. サービスの疎通確認
```bash
# サービスのエンドポイントを確認
kubectl get endpoints

# サービスにアクセスできるか確認
kubectl run test-pod --image=busybox -it --rm -- wget -qO- http://backend-service:3001/users
```

---

## よくあるHelmのエラーメッセージ

### "Error: INSTALLATION FAILED: rendered manifests contain a resource that already exists"

#### 原因
同じ名前のリソースが既に存在する

#### 解決方法
```bash
# オプション1: 既存のリリースを削除
helm uninstall my-app

# オプション2: 別の名前でインストール
helm install my-app-v2 ./next-nest-app

# オプション3: --forceフラグを使用（注意が必要）
helm upgrade my-app ./next-nest-app --force
```

### "Error: template: next-nest-app/templates/backend.yaml:10:20: executing..."

#### 原因
テンプレート構文エラー

#### 解決方法
```bash
# テンプレートをデバッグモードで確認
helm template ./next-nest-app --debug

# よくある構文エラー
# 誤: {{ .Values.backend.image.repository }}:{{ .Values.backend.image.tag }}
# 正: "{{ .Values.backend.image.repository }}:{{ .Values.backend.image.tag }}"
```

### "Error: validation failed"

#### 原因
Kubernetesリソースの検証エラー

#### 解決方法
```bash
# 生成されたマニフェストを検証
helm install my-app ./next-nest-app --dry-run --debug | kubectl apply --dry-run=client -f -
```

---

## パフォーマンスの最適化

### 1. リソース制限の適切な設定
```yaml
# values.yaml
backend:
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "512Mi"
      cpu: "500m"
```

### 2. Horizontal Pod Autoscaler (HPA)の有効化
```yaml
# values.yaml
backend:
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 80
```

```bash
# HPAの状態確認
kubectl get hpa
```

### 3. Pod Disruption Budget (PDB)の設定
```yaml
# templates/pdb.yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ include "next-nest-app.fullname" . }}-backend
spec:
  minAvailable: 1
  selector:
    matchLabels:
      {{- include "next-nest-app.backend.selectorLabels" . | nindent 6 }}
```

---

## まとめ

Helmのトラブルシューティングの基本：

1. **症状を正確に把握**: `kubectl get pods`, `kubectl describe pod`
2. **ログを確認**: `kubectl logs`
3. **設定を確認**: `helm get values`, `helm get manifest`
4. **段階的に問題を切り分け**: 一つずつコンポーネントを有効化
5. **dry-runで事前確認**: 本番環境では必須

このガイドの問題と解決方法は、実際にこのプロジェクトで発生したものです。同様の問題に遭遇した場合の参考にしてください。