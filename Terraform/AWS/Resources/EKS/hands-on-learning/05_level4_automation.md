# レベル4: 自動化とCI/CD

**[← レベル3: 実用的な運用機能](04_level3_operations.md) | [次のレベル: 本格運用課題 →](06_level5_production.md)**

### 課題4-1: GitOpsパイプラインの構築
**目標**: ArgoCD使用したGitOps実装

**学習内容の解説**:
- **GitOpsの概念**: Gitを単一の情報源とした宣言的インフラ管理
- **ArgoCD**: GitOpsを実現するための継続的デプロイメントツール
- **同期戦略**: 自動同期、手動同期、sync waveの使い分け
- **マニフェスト管理**: 環境別設定の管理とKustomizeの活用
- **ロールバック**: Gitベースの簡単かつ確実なロールバック機能

**課題内容**
1. ArgoCD のインストール
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

2. Git リポジトリの準備
```
my-k8s-app/
├── src/           # アプリケーションソース
├── k8s/           # Kubernetesマニフェスト
│   ├── base/      # 基本設定
│   └── overlays/  # 環境別設定
└── .github/workflows/  # CI設定
```

3. 自動デプロイメントの設定
```yaml
# 課題: ArgoCD Applicationリソースを作成
# - 自動同期の設定
# - ヘルスチェック
# - 同期ポリシー
```

**チェックポイント**
- GitにPushするとアプリケーションが自動デプロイされるか
- ロールバックが正常に動作するか

### 課題4-2: 完全自動化パイプライン
**目標**: GitHub Actions + ArgoCD による完全自動化

**学習内容の解説**:
- **CI/CDパイプライン**: 継続的インテグレーションと継続的デプロイメントの統合
- **GitHub Actions**: コードベースワークフローの自動化
- **セキュリティ**: シークレット管理、コンテナイメージスキャン、SAST/DAST
- **環境管理**: 複数環境（dev/staging/prod）の効率的な管理
- **承認フロー**: 本番環境への安全なデプロイメント承認プロセス

**課題内容**
1. CI パイプラインの設定
```yaml
# .github/workflows/ci.yml
# 課題: 以下を含むCIパイプラインを作成
# - テスト実行
# - Dockerイメージビルド
# - ECRへのpush
# - マニフェストファイルの更新
```

2. 複数環境への対応
```
環境構成:
- development (feature branchのpush)
- staging (main branchのpush)  
- production (タグ作成時)
```

**チェックポイント**
- プルリクエスト作成時に自動テストが実行されるか
- 環境ごとに適切にデプロイされるか
- プロダクション環境へのデプロイに承認フローがあるか

