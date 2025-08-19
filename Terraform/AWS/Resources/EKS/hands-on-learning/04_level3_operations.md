# レベル3: 実用的な運用機能

**[← レベル2: AWS EKS入門](03_level2_eks.md) | [次のレベル: 自動化とCI/CD →](05_level4_automation.md)**

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

