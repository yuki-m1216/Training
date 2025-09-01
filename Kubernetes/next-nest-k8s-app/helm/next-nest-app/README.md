# Next.js + Nest.js Helm Chart

## 概要

このHelmチャートは、Next.js（フロントエンド）とNest.js（バックエンド）で構成されるフルスタックアプリケーションをKubernetesにデプロイするためのものです。

## 学習用ドキュメント

Helmを初めて使う方は、以下のドキュメントをご参照ください：

- [Helm入門ガイド](../docs/helm-tutorial-for-beginners.md) - 初学者向けの詳細な解説
- [トラブルシューティングガイド](../docs/helm-troubleshooting-guide.md) - 実際に発生した問題と解決方法
- [クイックリファレンス](../docs/quick-reference.md) - よく使うコマンド集

## 前提条件

- Kubernetes 1.19+
- Helm 3.x
- NGINX Ingress Controller
- 事前にデプロイされたPostgreSQL（または内蔵PostgreSQLを使用）

## インストール

### 基本的なインストール

```bash
helm install my-app ./next-nest-app
```

### カスタム値を使用したインストール

```bash
helm install my-app ./next-nest-app \
  --set postgresql.enabled=false \
  --set backend.image.pullPolicy=Never \
  --set frontend.image.pullPolicy=Never
```

### values.yamlファイルを使用

```bash
helm install my-app ./next-nest-app -f custom-values.yaml
```

## 設定値

### グローバル設定

| パラメータ | 説明 | デフォルト値 |
|-----------|------|-------------|
| `global.environment` | 環境名 | `development` |
| `global.domain` | ドメイン名 | `localhost` |

### PostgreSQL設定

| パラメータ | 説明 | デフォルト値 |
|-----------|------|-------------|
| `postgresql.enabled` | 内蔵PostgreSQLを使用 | `true` |
| `postgresql.auth.username` | DBユーザー名 | `nestjs_user` |
| `postgresql.auth.password` | DBパスワード | `nestjs_password` |
| `postgresql.auth.database` | データベース名 | `nestjs_app` |

### バックエンド設定

| パラメータ | 説明 | デフォルト値 |
|-----------|------|-------------|
| `backend.enabled` | バックエンドのデプロイ | `true` |
| `backend.replicaCount` | レプリカ数 | `2` |
| `backend.image.repository` | イメージリポジトリ | `next-nest-k8s-app-backend` |
| `backend.image.tag` | イメージタグ | `latest` |
| `backend.image.pullPolicy` | イメージプルポリシー | `Never` |
| `backend.resources.limits.cpu` | CPU制限 | `500m` |
| `backend.resources.limits.memory` | メモリ制限 | `512Mi` |

### フロントエンド設定

| パラメータ | 説明 | デフォルト値 |
|-----------|------|-------------|
| `frontend.enabled` | フロントエンドのデプロイ | `true` |
| `frontend.replicaCount` | レプリカ数 | `2` |
| `frontend.image.repository` | イメージリポジトリ | `next-nest-k8s-app-frontend` |
| `frontend.image.tag` | イメージタグ | `latest` |
| `frontend.image.pullPolicy` | イメージプルポリシー | `Never` |
| `frontend.resources.limits.cpu` | CPU制限 | `500m` |
| `frontend.resources.limits.memory` | メモリ制限 | `512Mi` |

### Ingress設定

| パラメータ | 説明 | デフォルト値 |
|-----------|------|-------------|
| `ingress.enabled` | Ingressの有効化 | `true` |
| `ingress.className` | Ingressクラス | `nginx` |
| `ingress.hosts[0].host` | ホスト名 | `localhost` |

## アーキテクチャの特徴

### デュアルIngress構成

このチャートは2つのIngressリソースを作成します：

1. **メインIngress** (`my-app-next-nest-app-ingress`)
   - 静的ファイル（JavaScript、CSS）の配信
   - フロントエンドルーティング
   - リライトなし

2. **API Ingress** (`my-app-next-nest-app-ingress-api`)
   - `/api`パスのリライト処理
   - バックエンドAPIへのルーティング
   - `rewrite-target: /$2`によるパス変換

この構成により、Next.jsの静的ファイルとAPIの両方が正しくルーティングされます。

### 環境変数の管理

- **DATABASE_URL**: PostgreSQL接続文字列として自動生成
- **NEXT_PUBLIC_API_URL**: `/api`に統一（環境間の差異を吸収）

## トラブルシューティング

### Podが起動しない

```bash
# Pod状態の確認
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### データベース接続エラー

1. PostgreSQLが起動しているか確認
2. Secretが正しく作成されているか確認
3. DATABASE_URL環境変数が正しいか確認

### 静的ファイルが404エラー

Ingressの設定を確認し、2つのIngressリソースが作成されているか確認：

```bash
kubectl get ingress
```

## アップグレード

```bash
# 値を保持してアップグレード
helm upgrade my-app ./next-nest-app --reuse-values

# 特定の値を変更してアップグレード
helm upgrade my-app ./next-nest-app \
  --reuse-values \
  --set backend.replicaCount=3
```

## アンインストール

```bash
helm uninstall my-app
```

## 開発のヒント

### ローカル開発（kind使用時）

1. `imagePullPolicy: Never`を使用してローカルイメージを使用
2. `kind load docker-image`でイメージをクラスターにロード
3. PostgreSQLは外部デプロイメント（`postgresql.enabled=false`）

### 本番環境

1. `imagePullPolicy: Always`を使用
2. 適切なリソース制限を設定
3. HPAを有効化（`autoscaling.enabled=true`）
4. TLSを設定（`ingress.tls`）

## ライセンス

MIT