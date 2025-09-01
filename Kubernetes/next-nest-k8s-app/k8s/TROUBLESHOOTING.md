# Kubernetes環境でのトラブルシューティングガイド

## 目次
1. [よくある問題と解決方法](#よくある問題と解決方法)
2. [デバッグコマンド集](#デバッグコマンド集)
3. [環境別の注意事項](#環境別の注意事項)

## よくある問題と解決方法

### 1. ImagePullBackOffエラー

**症状**
```bash
kubectl get pods
# STATUS が ImagePullBackOff または ErrImagePull
```

**原因**
- kindクラスターがDockerレジストリからイメージをプルしようとしている
- ローカルイメージがkindクラスターにロードされていない

**解決方法**
```yaml
# Deploymentマニフェストに追加
spec:
  containers:
    - name: app
      imagePullPolicy: Never  # ローカルイメージを使用
```

```bash
# イメージをkindクラスターにロード
kind load docker-image <image-name>:latest
```

### 2. フロントエンドでJavaScriptエラー（Unexpected token '<'）

**症状**
- ブラウザコンソールに「Unexpected token '<'」エラー
- Next.jsの静的ファイルが読み込めない

**原因**
- Ingressのrewrite-targetがすべてのパスに適用されている
- 静的ファイル（/_next/static/*）のパスが書き換えられる

**解決方法**
```yaml
# 2つの別々のIngressを作成
# 1. フロントエンド用（rewriteなし）
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
spec:
  rules:
    - host: localhost
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend-service
                port:
                  number: 3000

---
# 2. API用（rewriteあり）
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$1
spec:
  rules:
    - host: localhost
      http:
        paths:
          - path: /api/(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: backend-service
                port:
                  number: 3001
```

### 3. Next.jsハイドレーションエラー

**症状**
- Reactコンポーネントが正しくマウントされない
- useEffectが実行されない
- 初期データが読み込まれない

**原因**
- SSR/SSGとクライアントサイドの不整合
- 環境変数の扱いの違い（ビルド時vs実行時）

**解決方法**
```typescript
// クライアントサイド専用レンダリング
export const dynamic = 'force-dynamic';

export default function Page() {
  const [isClient, setIsClient] = useState(false);
  
  useEffect(() => {
    setIsClient(true);
  }, []);
  
  if (!isClient) {
    return <div>Loading...</div>;
  }
  
  // 実際のコンポーネント
  return <div>...</div>;
}
```

### 4. ヘルスチェック失敗

**症状**
```bash
kubectl describe pod <pod-name>
# Liveness probe failed: HTTP probe failed with statuscode: 404
```

**原因**
- デフォルトの/healthエンドポイントが存在しない
- アプリケーションの起動が遅い

**解決方法**
```yaml
# 既存のエンドポイントを使用
livenessProbe:
  httpGet:
    path: /users  # 実在するエンドポイント
    port: 3001
  initialDelaySeconds: 30  # 起動時間を考慮
```

### 5. PostgreSQL接続エラー

**症状**
- バックエンドがデータベースに接続できない
- `Connection refused`エラー

**原因**
- PostgreSQLポッドがまだ起動していない
- 接続文字列が間違っている

**解決方法**
```bash
# PostgreSQLポッドの状態確認
kubectl get pods | grep postgres
kubectl logs postgres-<pod-id>

# 接続文字列の確認
kubectl get configmap backend-config -o yaml
```

## デバッグコマンド集

### ポッドの状態確認
```bash
# 全ポッドの状態
kubectl get pods

# 特定ポッドの詳細
kubectl describe pod <pod-name>

# ポッドのログ
kubectl logs <pod-name>
kubectl logs -f <pod-name>  # リアルタイム

# 前のコンテナのログ（再起動後）
kubectl logs <pod-name> --previous
```

### ネットワーク診断
```bash
# サービスの確認
kubectl get svc

# エンドポイントの確認
kubectl get endpoints

# Ingressの確認
kubectl get ingress
kubectl describe ingress <ingress-name>

# ポッド内からの接続テスト
kubectl exec -it <pod-name> -- curl http://backend-service:3001/users
```

### リソース使用状況
```bash
# CPU/メモリ使用量
kubectl top nodes
kubectl top pods

# リソース制限の確認
kubectl describe pod <pod-name> | grep -A 5 "Limits:"
```

### 設定の確認
```bash
# ConfigMapの内容
kubectl get configmap <name> -o yaml

# Secretの内容（base64エンコード）
kubectl get secret <name> -o yaml

# 環境変数の確認
kubectl exec <pod-name> -- env
```

## 環境別の注意事項

### kind（ローカル開発）
- `imagePullPolicy: Never`を使用
- `kind load docker-image`でイメージをロード
- localhost経由でアクセス

### 本番環境
- `imagePullPolicy: Always`を使用
- 適切なリソース制限を設定
- Secretを使用して認証情報を管理
- 専用の/healthエンドポイントを実装
- ログ収集とモニタリングを設定

### Docker Compose vs Kubernetes
| 項目 | Docker Compose | Kubernetes |
|------|---------------|------------|
| API URL | http://localhost:3001 | /api |
| ネットワーク | ブリッジネットワーク | Service経由 |
| ボリューム | Docker volumes | PVC |
| 環境変数 | .envファイル | ConfigMap/Secret |
| ロードバランサ | なし | Ingress |

## よく使うコマンドのエイリアス

```bash
# ~/.bashrc or ~/.zshrc に追加
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgi='kubectl get ingress'
alias kaf='kubectl apply -f'
alias kdel='kubectl delete'
alias klog='kubectl logs'
alias kexec='kubectl exec -it'
```

## リカバリー手順

### 全体の再起動
```bash
# 1. 全リソースの削除
kubectl delete -f k8s/

# 2. イメージの再ビルド
docker build -t next-nest-k8s-app-backend:latest ./backend
docker build -t next-nest-k8s-app-frontend:latest ./frontend --build-arg NEXT_PUBLIC_API_URL=/api

# 3. kindクラスターへのロード
kind load docker-image next-nest-k8s-app-backend:latest
kind load docker-image next-nest-k8s-app-frontend:latest

# 4. リソースの再作成
kubectl apply -f k8s/postgres-config.yaml
kubectl apply -f k8s/postgres.yaml
# PostgreSQLの起動を待つ
kubectl wait --for=condition=ready pod -l app=postgres --timeout=60s
kubectl apply -f k8s/backend.yaml
kubectl apply -f k8s/frontend.yaml
kubectl apply -f k8s/ingress.yaml
```

### kindクラスターの再作成
```bash
# 1. 既存クラスターの削除
kind delete cluster

# 2. 新規クラスターの作成
kind create cluster --config k8s/kind-config.yaml

# 3. Ingress Controllerのインストール
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# 4. Ingress Controllerの起動待ち
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

## 参考リンク

- [kind Documentation](https://kind.sigs.k8s.io/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug/)
- [Next.js Deployment](https://nextjs.org/docs/deployment)