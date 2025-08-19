# レベル5: 本格運用課題

**[← レベル4: 自動化とCI/CD](05_level4_automation.md) | [リファレンス・サポート →](07_reference.md)**

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

