# Next.js + Nest.js Kubernetes Application

## 概要

このプロジェクトは、Next.js（フロントエンド）、Nest.js（バックエンド）、PostgreSQL（データベース）を使用したフルスタックアプリケーションです。Docker ComposeとKubernetesの両環境で動作するように設計されています。

## アーキテクチャ

```
┌─────────────┐     ┌─────────────┐     ┌──────────────┐
│   Frontend  │────▶│   Backend   │────▶│  PostgreSQL  │
│  (Next.js)  │     │  (Nest.js)  │     │   Database   │
└─────────────┘     └─────────────┘     └──────────────┘
     Port:3000          Port:3001           Port:5432
```

## 技術スタック

- **Frontend**: Next.js 15.5.0, React 19, TypeScript, Tailwind CSS
- **Backend**: Nest.js, TypeORM, PostgreSQL, RESTful API
- **Database**: PostgreSQL 17
- **Container**: Docker, Docker Compose
- **Orchestration**: Kubernetes (kind), Helm
- **Ingress**: NGINX Ingress Controller

## プロジェクト構造

```
next-nest-k8s-app/
├── frontend/               # Next.jsフロントエンド
│   ├── src/app/           # Appルーター
│   ├── Dockerfile         # Dockerイメージ定義
│   └── package.json       # 依存関係
├── backend/               # Nest.jsバックエンド
│   ├── src/              # ソースコード
│   ├── Dockerfile        # Dockerイメージ定義
│   └── package.json      # 依存関係
├── k8s/                  # Kubernetesマニフェスト
│   ├── postgres-config.yaml  # PostgreSQL設定
│   ├── postgres.yaml         # PostgreSQLデプロイメント
│   ├── backend.yaml          # バックエンドデプロイメント
│   ├── frontend.yaml         # フロントエンドデプロイメント
│   ├── ingress.yaml          # Ingress設定
│   └── kind-config.yaml      # kind cluster設定
└── docker-compose.yaml    # Docker Compose設定
```

## セットアップ手順

### 前提条件

- Docker Desktop
- kubectl
- kind (Kubernetes in Docker)
- Node.js 22+ (ローカル開発用)

### 1. Docker Compose環境

```bash
# イメージのビルドと起動
docker-compose up --build -d

# アクセス（nginxプロキシ経由）
# アプリケーション: http://localhost:8080/
# API: http://localhost:8080/api/users

# 開発環境（各サービスに直接アクセス可能）
docker-compose -f docker-compose.dev.yaml up -d
# Frontend: http://localhost:3000
# Backend API: http://localhost:3001
# 統合アクセス: http://localhost/
```

### 2. Kubernetes環境（kind）

```bash
# kindクラスターの作成（Ingress有効）
kind create cluster --config k8s/kind-config.yaml

# NGINX Ingress Controllerのインストール
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Ingress Controllerの起動確認
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

# Dockerイメージのビルド
docker build -t next-nest-k8s-app-backend:latest ./backend
docker build -t next-nest-k8s-app-frontend:latest ./frontend --build-arg NEXT_PUBLIC_API_URL=/api

# kindクラスターへイメージをロード
kind load docker-image next-nest-k8s-app-backend:latest
kind load docker-image next-nest-k8s-app-frontend:latest

# Kubernetesマニフェストの適用
kubectl apply -f k8s/postgres-config.yaml
kubectl apply -f k8s/postgres.yaml
kubectl apply -f k8s/backend.yaml
kubectl apply -f k8s/frontend.yaml
kubectl apply -f k8s/ingress.yaml

# ポッドの確認
kubectl get pods

# アクセス
# アプリケーション: http://localhost/
# API: http://localhost/api/users
```

## 環境変数設定

### Backend環境変数
- `DATABASE_URL`: PostgreSQL接続文字列
- `NODE_ENV`: 実行環境（development/production）

### Frontend環境変数
- `NEXT_PUBLIC_API_URL`: APIエンドポイント
  - **統一設定**: `/api`（Docker Compose・Kubernetes共通）
  - nginxリバースプロキシ/Ingressが適切にルーティング
- `NODE_ENV`: 実行環境（development/production）

## アクセスURL

| 環境 | アプリケーション | API | ポート |
|------|------------------|-----|--------|
| Kubernetes | http://localhost/ | http://localhost/api/* | 80 |
| Docker Compose | http://localhost:8080/ | http://localhost:8080/api/* | 8080 |
| 開発環境 | http://localhost:3000 | http://localhost:3001/* | 3000/3001 |

## トラブルシューティング

### 1. ImagePullBackOffエラー

**症状**: ポッドが`ImagePullBackOff`状態になる

**原因**: kindクラスターがローカルイメージを認識できない

**解決方法**:
```yaml
# Deploymentマニフェストに追加
imagePullPolicy: Never
```

### 2. Ingress Rewriteの問題

**症状**: 静的ファイル（JavaScript/CSS）が404エラーになる

**原因**: Ingress rewrite-targetがすべてのパスに適用される

**解決方法**: APIとフロントエンド用に別々のIngressを作成
```yaml
# app-ingress: フロントエンド用（rewriteなし）
# api-ingress: API用（rewriteあり）
```

### 3. Next.jsハイドレーション問題

**症状**: Reactコンポーネントが正しくマウントされない

**原因**: SSR/SSGとクライアントサイドの不整合

**解決方法**: 
- クライアントサイド専用レンダリングを使用
- `useEffect`でクライアントサイドのみで初期化
- `dynamic = 'force-dynamic'`でSSGを無効化

### 4. ヘルスチェック失敗

**症状**: バックエンドポッドが再起動を繰り返す

**原因**: `/health`エンドポイントが存在しない

**解決方法**: 既存のエンドポイント（`/users`）をヘルスチェックに使用

## API仕様

### ユーザー管理API

| メソッド | エンドポイント | 説明 |
|---------|---------------|------|
| GET | /users | 全ユーザー取得 |
| GET | /users/:id | 特定ユーザー取得 |
| POST | /users | 新規ユーザー作成 |
| PUT | /users/:id | ユーザー更新 |
| DELETE | /users/:id | ユーザー削除 |

### リクエスト/レスポンス例

```json
// POST /users
{
  "name": "John Doe",
  "email": "john@example.com"
}

// Response
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "avatar": null,
  "createdAt": "2025-08-31T11:33:43.810Z"
}
```

## 開発ガイドライン

### コミット規約
- feat: 新機能
- fix: バグ修正
- docs: ドキュメント変更
- style: コードスタイル変更
- refactor: リファクタリング
- test: テスト追加/修正
- chore: ビルドプロセス/補助ツール変更

### ブランチ戦略
- `main`: 本番環境
- `develop`: 開発環境
- `feature/*`: 機能開発
- `hotfix/*`: 緊急修正

## 注意事項

1. **環境変数の管理**: 本番環境では必ずSecretを使用してください
2. **imagePullPolicy**: kindではNever、本番環境ではAlwaysを使用
3. **リソース制限**: 本番環境では必ずrequests/limitsを設定
4. **データ永続化**: PostgreSQLデータはPVCで永続化されます

## ライセンス

MIT

## 作成者

[あなたの名前]

## 更新履歴

- 2025-08-31: 初版作成
- Kubernetes環境の構築とトラブルシューティング完了
- Docker ComposeとKubernetes両環境での動作確認済み