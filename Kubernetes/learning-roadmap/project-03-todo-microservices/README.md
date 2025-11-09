# Project 03: マイクロサービスTODOアプリ

TypeScript (NestJS) + Python (FastAPI) によるマイクロサービスアーキテクチャの学習プロジェクト

## 技術スタック

- **Auth Service**: Python 3.13 + FastAPI + JWT認証
- **TODO Service**: Node.js 20 + NestJS + Mongoose
- **API Gateway**: Node.js 20 + NestJS + HTTP Proxy
- **Notification Service**: Python 3.13 + Celery
- **Database**: MongoDB 8.0
- **Cache/Broker**: Redis 8.0
- **Orchestration**: Kubernetes (Kind)
- **Configuration**: Kustomize

## アーキテクチャ

```
┌─────────────────────┐
│   API Gateway       │ (NestJS - Port 3000)
│  リバースプロキシ    │
└──────────┬──────────┘
           │
           ├─────────────────┬──────────────────┐
           │                 │                  │
       /auth/*           /todos/*           /health
           │                 │                  │
           ▼                 ▼                  ▼
    ┌─────────────┐   ┌─────────────┐    ┌─────────────┐
    │Auth Service │   │TODO Service │    │Notification │
    │  (FastAPI)  │   │  (NestJS)   │    │  (Celery)   │
    │  Port: 8000 │   │  Port: 3000 │    │   Worker    │
    └──────┬──────┘   └──────┬──────┘    └──────┬──────┘
           │                 │                  │
           │                 │                  │
           ▼                 ▼                  ▼
       ┌────────┐       ┌──────────┐       ┌────────┐
       │ Redis  │       │ MongoDB  │       │ Redis  │
       │(Cache) │       │  (Data)  │       │(Queue) │
       └────────┘       └──────────┘       └────────┘
```

### サービス間通信フロー

1. **ユーザー登録・ログイン**:
   - Client → API Gateway → Auth Service
   - Auth Service: JWT トークン生成
   - Response: アクセストークン

2. **TODO操作**:
   - Client → API Gateway → TODO Service
   - TODO Service: Auth Service にトークン検証依頼
   - TODO Service: MongoDB に CRUD操作
   - Notification Service: 非同期で通知タスク実行

## ディレクトリ構成

```
project-03-todo-microservices/
├── auth-service/           # 認証サービス (FastAPI)
│   ├── app/
│   │   ├── main.py        # FastAPIアプリケーション
│   │   ├── auth.py        # JWT認証ロジック
│   │   ├── models.py      # Pydanticモデル
│   │   └── database.py    # Redis接続
│   ├── requirements.txt    # Python依存関係
│   ├── Dockerfile          # 本番用
│   └── Dockerfile.dev      # 開発用
├── todo-service/           # TODOサービス (NestJS)
│   ├── src/
│   │   ├── app.module.ts
│   │   ├── todos/         # TODOモジュール
│   │   │   ├── todos.controller.ts
│   │   │   ├── todos.service.ts
│   │   │   ├── todos.schema.ts
│   │   │   └── todos.module.ts
│   │   └── auth/          # 認証ガード
│   │       ├── auth.guard.ts
│   │       └── auth.module.ts
│   ├── package.json
│   ├── tsconfig.json
│   ├── Dockerfile
│   └── Dockerfile.dev
├── api-gateway/            # APIゲートウェイ (NestJS)
│   ├── src/
│   │   ├── app.module.ts
│   │   ├── proxy/         # プロキシモジュール
│   │   │   ├── proxy.controller.ts
│   │   │   ├── proxy.service.ts
│   │   │   └── proxy.module.ts
│   │   └── health/        # ヘルスチェック
│   ├── package.json
│   ├── tsconfig.json
│   ├── Dockerfile
│   └── Dockerfile.dev
├── notification-service/   # 通知サービス (Celery)
│   ├── app/
│   │   ├── celery_app.py  # Celeryアプリケーション
│   │   └── tasks.py       # 非同期タスク
│   ├── requirements.txt
│   ├── Dockerfile
│   └── Dockerfile.dev
├── k8s/                    # Kubernetesマニフェスト
│   ├── base/              # 基本リソース
│   │   ├── namespace.yaml
│   │   ├── mongodb-statefulset.yaml
│   │   ├── redis-deployment.yaml
│   │   ├── auth-service-deployment.yaml
│   │   ├── todo-service-deployment.yaml
│   │   ├── api-gateway-deployment.yaml
│   │   ├── notification-deployment.yaml
│   │   ├── services.yaml
│   │   ├── configmap.yaml
│   │   ├── secret.yaml
│   │   ├── ingress.yaml
│   │   └── kustomization.yaml
│   └── overlays/          # 環境別設定
│       └── dev/
│           ├── kustomization.yaml
│           └── patches/
├── docker-compose.yaml     # ローカル開発用
└── README.md
```

## 学習フェーズ

### ✅ Phase 1-1: プロジェクト構造作成とdocker-compose.yaml (完了)

#### 実施内容
- プロジェクトディレクトリ構造の作成
- docker-compose.yamlの作成
- 5つのサービス定義（MongoDB, Redis, Auth, TODO, API Gateway, Notification）

#### 作成したファイル
- `docker-compose.yaml` - ローカル開発環境の定義
- ディレクトリ構造

---

### ⏳ Phase 1-2: Auth Service (FastAPI + JWT) 実装

#### 実装予定
- [ ] FastAPIプロジェクトのセットアップ
- [ ] ユーザー登録エンドポイント (`POST /auth/register`)
- [ ] ログインエンドポイント (`POST /auth/login`)
- [ ] トークン検証エンドポイント (`GET /auth/verify`)
- [ ] パスワードハッシュ化 (passlib + bcrypt)
- [ ] JWT トークン生成・検証 (python-jose)
- [ ] Redis でユーザーキャッシュ
- [ ] Dockerfile.dev作成

#### 学習ポイント
- FastAPIの基本的な使い方
- JWT認証の仕組み
- Pythonでの暗号化処理
- Pydanticによるバリデーション

---

### ⏳ Phase 1-3: TODO Service (NestJS + MongoDB) 実装

#### 実装予定
- [ ] NestJSプロジェクトのセットアップ
- [ ] MongooseスキーマとDTO定義
- [ ] CRUD API実装
  - `GET /todos` - TODO一覧取得
  - `POST /todos` - TODO作成
  - `GET /todos/:id` - TODO詳細取得
  - `PUT /todos/:id` - TODO更新
  - `DELETE /todos/:id` - TODO削除
- [ ] 認証ガード実装（Auth Serviceと連携）
- [ ] Dockerfile.dev作成

#### 学習ポイント
- NestJSのモジュール構造
- TypeScriptの型安全性
- MongoDBのスキーマ設計
- ガードによる認証・認可

---

### ⏳ Phase 1-4: API Gateway (NestJS) 実装

#### 実装予定
- [ ] NestJSプロジェクトのセットアップ
- [ ] HTTPプロキシモジュール実装
- [ ] ルーティング設定
  - `/auth/*` → Auth Service
  - `/todos/*` → TODO Service
- [ ] ヘルスチェックエンドポイント
- [ ] エラーハンドリング
- [ ] Dockerfile.dev作成

#### 学習ポイント
- API Gatewayパターン
- HTTPプロキシの実装
- リバースプロキシの仕組み
- 認証の一元管理

---

### ⏳ Phase 1-5: Notification Service (Celery) 実装

#### 実装予定
- [ ] Celeryワーカーのセットアップ
- [ ] タスクキュー実装
  - メール通知タスク
  - ログ記録タスク
- [ ] Redis連携（ブローカー＆バックエンド）
- [ ] Dockerfile.dev作成

#### 学習ポイント
- 非同期タスク処理
- Celeryの基本概念
- メッセージキューの仕組み
- バックグラウンドジョブ

---

### ⏳ Phase 1-6: ローカル動作確認

#### 確認項目
- [ ] docker-compose upで全サービス起動
- [ ] ユーザー登録 → ログイン → TODO作成の一連の流れ
- [ ] サービス間通信のログ確認
- [ ] エラーハンドリングの確認

---

### Phase 2: Kubernetesマニフェスト作成 (1-2日)

#### 実装予定
- [ ] Namespace作成
- [ ] ConfigMap/Secret作成（各サービス用）
- [ ] MongoDB StatefulSet + Service
- [ ] Redis Deployment + Service
- [ ] Auth Service Deployment + Service
- [ ] TODO Service Deployment + Service
- [ ] API Gateway Deployment + Service
- [ ] Notification Deployment (Celery Worker)
- [ ] サービスディスカバリー設定

#### 学習ポイント
- 複数サービスのマニフェスト管理
- 環境変数の外部化
- サービス間の依存関係
- Kubernetes DNSの仕組み

---

### Phase 3: Kustomize設定とデプロイ (1-2日)

#### 実装予定
- [ ] `k8s/base/` に共通マニフェスト配置
- [ ] `k8s/overlays/dev/` 作成
- [ ] namePrefix、namespace設定
- [ ] リソース制限のパッチ作成
- [ ] レプリカ数の環境別設定
- [ ] Kindクラスタへのデプロイ
- [ ] Ingress設定
- [ ] 動作検証

#### 学習ポイント
- KustomizeのpatchesStrategicMerge
- 環境別の設定管理
- マイクロサービスのIngress設計

---

### Phase 4: Service Mesh基礎学習 (オプション: 1-2日)

#### 実装予定
- [ ] Istioまたはlinkerdの調査
- [ ] サービスメッシュの必要性理解
- [ ] サイドカープロキシの仕組み
- [ ] 基本的なService Mesh導入
- [ ] トラフィック管理の基本設定
- [ ] 分散トレーシング (Jaeger)

#### 学習ポイント
- サービスメッシュの基本概念
- サイドカーパターン
- トラフィックルーティング
- マイクロサービスのデバッグ手法

---

## 使用する主要ライブラリ

### Python (Auth Service, Notification Service)
```txt
fastapi==0.115.13          # Webフレームワーク
uvicorn[standard]          # ASGIサーバー
python-jose[cryptography]  # JWT処理
passlib[bcrypt]            # パスワードハッシュ化
redis                      # Redisクライアント
celery                     # タスクキュー
pydantic                   # バリデーション
```

### TypeScript (TODO Service, API Gateway)
```json
{
  "@nestjs/core": "^11.x",
  "@nestjs/common": "^11.x",
  "@nestjs/mongoose": "^10.x",
  "mongoose": "^8.x",
  "@nestjs/axios": "^3.x",
  "axios": "^1.x",
  "class-validator": "^0.14.x",
  "class-transformer": "^0.5.x"
}
```

## ローカル開発環境のセットアップ

### 前提条件

- Docker & Docker Compose
- Node.js 20.x (ローカル開発用)
- Python 3.13 (ローカル開発用)

### クイックスタート

```bash
# プロジェクトルートに移動
cd project-03-todo-microservices

# 全サービスをビルド
docker-compose build

# 全サービスを起動
docker-compose up

# バックグラウンドで起動
docker-compose up -d

# ログ確認
docker-compose logs -f

# 特定のサービスのログ確認
docker-compose logs -f auth-service

# 停止
docker-compose down

# ボリュームも削除
docker-compose down -v
```

### 個別サービスの起動

```bash
# MongoDBとRedisのみ起動
docker-compose up mongodb redis

# Auth Serviceのみ起動
docker-compose up auth-service
```

## APIエンドポイント

### API Gateway経由 (Port 3000)

#### 認証
```bash
# ユーザー登録
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "password": "password123", "email": "test@example.com"}'

# ログイン
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "password": "password123"}'

# レスポンス例
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

#### TODO操作
```bash
# TODO一覧取得
curl -X GET http://localhost:3000/todos \
  -H "Authorization: Bearer <access_token>"

# TODO作成
curl -X POST http://localhost:3000/todos \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"title": "Learn Kubernetes", "description": "Complete project 03", "completed": false}'

# TODO更新
curl -X PUT http://localhost:3000/todos/<todo_id> \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"title": "Learn Kubernetes", "completed": true}'

# TODO削除
curl -X DELETE http://localhost:3000/todos/<todo_id> \
  -H "Authorization: Bearer <access_token>"
```

### 直接アクセス（開発・デバッグ用）

- **API Gateway**: http://localhost:3000
- **Auth Service**: http://localhost:8001
- **TODO Service**: http://localhost:3001
- **MongoDB**: mongodb://admin:password@localhost:27017
- **Redis**: redis://localhost:6379

## データベース接続

### MongoDB

```bash
# MongoDBコンテナに接続
docker exec -it todo-mongodb mongosh -u admin -p password

# データベース確認
use todo_db
db.todos.find()
db.users.find()
```

### Redis

```bash
# Redisコンテナに接続
docker exec -it todo-redis redis-cli

# キー確認
KEYS *

# 特定のキー取得
GET user:testuser
```

## トラブルシューティング

### サービスが起動しない

```bash
# コンテナのステータス確認
docker-compose ps

# ログ確認
docker-compose logs <service-name>

# コンテナ再起動
docker-compose restart <service-name>

# イメージ再ビルド
docker-compose build --no-cache <service-name>
```

### MongoDBに接続できない

- `MONGO_INITDB_ROOT_USERNAME` と `MONGO_INITDB_ROOT_PASSWORD` が正しいか確認
- MongoDB コンテナが起動しているか確認: `docker-compose ps mongodb`
- 接続文字列の `authSource=admin` が含まれているか確認

### Redisに接続できない

- Redis コンテナが起動しているか確認: `docker-compose ps redis`
- `REDIS_URL` の形式が正しいか確認: `redis://redis:6379/0`

### ポートが既に使用されている

```bash
# ポート使用状況確認
sudo lsof -i :3000
sudo lsof -i :8001
sudo lsof -i :27017
sudo lsf -i :6379

# プロセスを停止
kill -9 <PID>
```

## 学習のポイント

### プロジェクト1-2との違い

| 項目 | プロジェクト1-2 | プロジェクト3 |
|------|----------------|--------------|
| サービス数 | 2-3個 | 5個 |
| 言語 | TypeScriptのみ | TypeScript + Python |
| 通信方法 | WebSocket/HTTP | HTTP + メッセージキュー |
| データストア | Redis | MongoDB + Redis |
| 複雑度 | 単一アプリ | マイクロサービス |
| 新規要素 | Ingress, HPA | API Gateway, 非同期処理, サービス間通信 |

### 重要な学習項目

1. **マイクロサービスアーキテクチャ**
   - サービスの分割方法
   - サービス間通信パターン
   - データの一貫性管理

2. **混合言語環境**
   - TypeScriptとPythonの使い分け
   - 各言語の特性を活かした設計
   - 共通インターフェースの定義

3. **API Gateway パターン**
   - 単一エントリーポイント
   - ルーティングとプロキシ
   - 認証の一元化

4. **非同期処理**
   - Celeryによるタスクキュー
   - バックグラウンドジョブ
   - メッセージブローカー

5. **サービスディスカバリー**
   - Kubernetes DNS
   - Service間の名前解決
   - 環境変数による設定管理

## 参考リンク

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [NestJS Documentation](https://docs.nestjs.com/)
- [Celery Documentation](https://docs.celeryproject.org/)
- [MongoDB Documentation](https://docs.mongodb.com/)
- [Redis Documentation](https://redis.io/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kustomize Documentation](https://kubectl.docs.kubernetes.io/references/kustomize/)

---

## 進捗管理

### Phase 1: ローカル開発環境でアプリケーション実装
- [x] Phase 1-1: プロジェクト構造作成とdocker-compose.yaml
- [ ] Phase 1-2: Auth Service (FastAPI + JWT) 実装
- [ ] Phase 1-3: TODO Service (NestJS + MongoDB) 実装
- [ ] Phase 1-4: API Gateway (NestJS) 実装
- [ ] Phase 1-5: Notification Service (Celery) 実装
- [ ] Phase 1-6: ローカル動作確認

### Phase 2: Kubernetesマニフェスト作成
- [ ] 基本マニフェスト作成
- [ ] サービスディスカバリー設定

### Phase 3: Kustomize設定とデプロイ
- [ ] Kustomize構造構築
- [ ] Kindクラスタへのデプロイ
- [ ] Ingress設定
- [ ] 動作検証

### Phase 4: Service Mesh基礎学習 (オプション)
- [ ] Service Meshの概念理解
- [ ] 基本的なService Mesh導入
- [ ] 分散トレーシング

---

*最終更新: 2025-11-09*
