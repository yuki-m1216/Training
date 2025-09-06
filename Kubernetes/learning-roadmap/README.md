# Kubernetes学習ロードマップ

## 概要
TypeScriptとPythonを活用した実践的なKubernetes学習計画。プロジェクトベースで段階的にKubernetesのスキルを習得します。

## 学習方針
- **実践重視**: 実際に動くアプリケーションを作りながら学習
- **言語選択**: TypeScriptとPythonの特性を活かした適材適所の実装
- **段階的学習**: 基礎から高度な機能まで順次習得

## 言語選択の指針

### TypeScriptを選ぶ場合
- Webアプリケーション（フロント・バックエンド）
- リアルタイム通信（WebSocket）
- 型安全性が重要なAPI
- フロントエンドとの型共有が必要

### Pythonを選ぶ場合
- データ処理・分析
- 機械学習・AI処理
- 科学計算・数値処理
- 非同期タスク処理（Celery）

## プロジェクト一覧

### 🚀 プロジェクト1: シンプル天気APIアプリ (2-3日)
**言語**: TypeScript  
**学習ポイント**: 基本的なDeployment、Service、ConfigMap

```
weather-app/
├── frontend/     # React + TypeScript (Vite)
├── backend/      # Express + TypeScript
└── k8s/         # マニフェスト
```

**実装内容**:
- TypeScriptで型安全なAPI実装
- React + Viteで高速な開発環境
- ConfigMapでAPI設定管理
- ServiceのタイプをClusterIP→NodePort→LoadBalancerと変更して違いを体験
- レプリカ数を変更してロードバランシングを確認

---

### 🎮 プロジェクト2: リアルタイムチャットアプリ (3-4日)
**言語**: TypeScript  
**学習ポイント**: WebSocket、SessionAffinity、水平スケーリング

```
chat-app/
├── frontend/     # Next.js 15 + TypeScript
├── backend/      # NestJS + Socket.io
├── redis/        # セッション管理
└── k8s/         # マニフェスト
```

**実装内容**:
- NestJSで構造化されたWebSocketサーバー
- TypeScriptの型定義でイベント管理
- Redisアダプタでスケーリング対応
- HPAで自動スケーリング実装

---

### 📝 プロジェクト3: マイクロサービスTODOアプリ (1週間)
**言語**: 混合（サービスの特性に応じて使い分け）  
**学習ポイント**: マイクロサービス、Service Mesh基礎、分散トレーシング

```
todo-microservices/
├── api-gateway/      # TypeScript (NestJS) - HTTPルーティング
├── auth-service/     # Python (FastAPI) - JWT認証・暗号化処理
├── todo-service/     # TypeScript (NestJS) - CRUD API
├── notification/     # Python (Celery) - 非同期処理
├── mongodb/         # データストア
└── k8s/
    ├── base/        # 基本マニフェスト
    └── overlays/    # Kustomize環境別設定
```

**実装内容**:
- FastAPIで高速な認証サービス
- NestJSで型安全なCRUD API
- Celeryで非同期タスク処理
- サービス間通信の実装
- Kustomizeで環境別デプロイ

---

### 🖼️ プロジェクト4: AI画像処理パイプライン (1週間)
**言語**: Python  
**学習ポイント**: Job、CronJob、PersistentVolume、Queue処理

```
image-processor/
├── uploader/        # Python (FastAPI) - アップロードAPI
├── processor/       # Python (Pillow/OpenCV) - 画像処理Worker
├── ml-service/      # Python (TensorFlow/PyTorch) - AI処理
├── storage/         # MinIO (S3互換)
├── rabbitmq/        # メッセージキュー
└── k8s/
```

**実装内容**:
- FastAPIで高速アップロードAPI
- OpenCVで画像処理
- TensorFlowで画像分類
- Celeryでタスクキュー管理
- Jobで画像処理タスク
- CronJobで定期的なクリーンアップ
- PVCでデータ永続化

---

### 🎯 プロジェクト5: フルスタックブログプラットフォーム (1週間)
**言語**: TypeScript  
**学習ポイント**: GitOps、自動デプロイ、Blue-Greenデプロイ

```
blog-platform/
├── frontend/        # Next.js 15 + TypeScript (App Router)
├── backend/         # NestJS + Prisma + TypeScript
├── postgres/        # データベース
├── k8s/
├── .github/         # GitHub Actions
└── argocd/         # ArgoCD設定
```

**実装内容**:
- Prismaで型安全なORM
- tRPCで型安全なAPI通信
- GitHub ActionsでTypeScriptビルド&テスト
- ArgoCDで自動デプロイ
- Blue-Greenデプロイメント戦略
- Rollback演習

---

### 📊 プロジェクト6: データ分析ダッシュボード (4-5日)
**言語**: Python  
**学習ポイント**: Observability、メトリクス、ログ集約

```
analytics-platform/
├── collector/       # Python (FastAPI) - データ収集API
├── processor/       # Python (Pandas/NumPy) - データ処理
├── dashboard/       # Python (Streamlit/Dash) - 可視化
├── prometheus/      # メトリクス収集
├── grafana/        # システムダッシュボード
└── k8s/
```

**実装内容**:
- FastAPIでメトリクス収集エンドポイント
- Pandasでデータ処理パイプライン
- Streamlitでインタラクティブダッシュボード
- PrometheusクライアントでカスタムメトリクスExport
- Grafanaダッシュボード作成
- アラート設定

---

### 🎪 プロジェクト7: イベント駆動ECシステム (1週間)
**言語**: 混合（ドメインに応じて最適化）  
**学習ポイント**: Kafka、イベントソーシング、StatefulSet

```
event-driven-shop/
├── order-service/   # TypeScript (NestJS) - 注文管理
├── payment/        # Python (FastAPI) - 決済処理・暗号化
├── inventory/      # TypeScript (NestJS) - 在庫管理
├── analytics/      # Python (Faust) - ストリーム処理
├── kafka/          # イベントストリーム
└── k8s/
```

**実装内容**:
- NestJSでCQRS/Event Sourcingパターン
- FastAPIで決済サービス（暗号化処理）
- FaustでKafkaストリーム処理
- TypeScript/Pythonでスキーマ共有（Protocol Buffers）
- Kafkaクラスタ構築（StatefulSet）
- Sagaパターンの実装

## 使用する主要フレームワーク

### TypeScript系
- **Frontend**: Next.js 15, React + Vite
- **Backend**: NestJS, Express + TypeScript
- **ORM**: Prisma, TypeORM
- **Validation**: Zod, class-validator

### Python系
- **Web**: FastAPI, Django, Flask
- **非同期**: Celery, asyncio
- **データ処理**: Pandas, NumPy
- **ML**: TensorFlow, PyTorch, scikit-learn
- **可視化**: Streamlit, Dash, Plotly

## 各プロジェクトで共通して学ぶこと

### 1. 開発フロー
- ローカル開発 → Docker化 → K8sデプロイ
- 段階的な複雑性の追加

### 2. デバッグスキル
- kubectl logs/describe/exec の活用
- トラブルシューティング実践
- ImagePullBackOff、CrashLoopBackOffなどのエラー解決

### 3. ベストプラクティス
- 12-Factor Appの原則
- セキュリティ（Secret管理、NetworkPolicy）
- リソース管理（Limits/Requests）

### 4. 型安全性の活用
- TypeScript: Interface, Type, Generic
- Python: Type Hints, Pydantic

### 5. テスト駆動開発
- TypeScript: Jest, Vitest
- Python: pytest, unittest

## 推奨スケジュール

| 週 | プロジェクト | 内容 |
|---|------------|-----|
| 1-2 | プロジェクト1-2 | TypeScript基礎、K8s基本概念 |
| 3-4 | プロジェクト3 | マイクロサービス（混合言語） |
| 5 | プロジェクト4 | Python・AI処理、Job/CronJob |
| 6 | プロジェクト5 | TypeScriptフルスタック、GitOps |
| 7 | プロジェクト6 | Python・データ分析、監視 |
| 8 | プロジェクト7 | 混合・イベント駆動、Kafka |

## 学習を加速するコツ

### 1. エラーを楽しむ
- わざとエラーを起こして動作を理解
- エラーメッセージから学ぶ

### 2. ドキュメント作成
- 各プロジェクトにREADME作成
- つまずきポイントを記録
- 解決方法を文書化

### 3. コミュニティ活用
- 作ったものをGitHubで公開
- ブログ記事を書く
- 質問と回答の共有

### 4. 段階的な複雑性
- まず動くものを作る
- 徐々に機能を追加
- リファクタリングで改善

## 初学者向け基礎固めステップ

Kubernetesマニフェストとコマンドに不安がある場合は、各プロジェクト実施前に以下を確認：

### kubectl基本コマンド習熟
```bash
# 基本操作
kubectl get/describe/logs/exec/port-forward
kubectl apply/delete/edit
kubectl rollout status/history/undo

# デバッグ
kubectl get events
kubectl top nodes/pods
```

### マニフェスト基本要素の理解
- **Deployment**: レプリカ管理、ローリングアップデート
- **Service**: ネットワーク公開、ロードバランシング
- **ConfigMap/Secret**: 設定の外部化
- **Ingress**: 外部アクセス管理
- **PersistentVolume**: データ永続化

### Helm基礎
- Chart構造の理解
- values.yamlの役割
- テンプレート変数の基本
- helm install/upgrade/rollback

## 進捗管理

各プロジェクト完了時にチェック：

- [ ] アプリケーションが正常に動作する
- [ ] Kubernetesで正常にデプロイできる
- [ ] 学習ポイントを理解した
- [ ] READMEを作成した
- [ ] エラーと解決方法を記録した

## リソース

- [Kubernetes公式ドキュメント](https://kubernetes.io/docs/)
- [TypeScript公式ドキュメント](https://www.typescriptlang.org/docs/)
- [Python公式ドキュメント](https://docs.python.org/3/)
- [NestJS公式ドキュメント](https://nestjs.com/)
- [FastAPI公式ドキュメント](https://fastapi.tiangolo.com/)

---

*このロードマップは随時更新され、学習進捗に応じて調整されます。*