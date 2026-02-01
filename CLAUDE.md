# CLAUDE.md

## Security Fix Workflow

セキュリティIssue（`security`ラベル付き）の修正手順:

### 1. Issueの確認
```bash
gh issue view <issue-number>
```

### 2. 修正作業

#### npm プロジェクト
対象ディレクトリ:
- `/Kubernetes/hello-k8s/`
- `/Kubernetes/learning-roadmap/project-01-weather-app/backend/`
- `/Kubernetes/learning-roadmap/project-02-chat-app/backend/`
- `/Kubernetes/learning-roadmap/project-02-chat-app/frontend/`
- `/Kubernetes/next-nest-k8s-app/backend/`
- `/Kubernetes/next-nest-k8s-app/frontend/`
- `/Terraform/AWS/Resources/APIGateway/synthetics_test_api/`
- `/Terraform/AWS/Resources/RAG/fe/src/`

```bash
cd <project-dir>
npm update <package-name>
# または package.json の overrides に追加
npm install
```

#### Python/Poetry プロジェクト
対象ディレクトリ:
- `/Terraform/AWS/Resources/RAG/be/src/embed_doc/`
- `/Terraform/AWS/Resources/RAG/be/src/answer_user_query/`
- `/Terraform/AWS/Resources/RAG/be/src/vector_database/`

```bash
cd <project-dir>
# pyproject.toml を編集して依存関係を更新
poetry lock
# requirements.txt がある場合は再生成
poetry export -f requirements.txt --output requirements.txt --without-hashes
```

#### GitHub Actions
対象: `.github/workflows/*.yml`

```bash
# アクションバージョンを更新（例: actions/checkout@v3 → @v4）
```

### 3. PR作成
```bash
git checkout -b fix-sec/security-fix-$(date +%Y%m%d)
git add -A
git commit -m "fix(security): <CVE-ID> の脆弱性を修正"
git push origin HEAD
gh pr create --title "fix(security): セキュリティ脆弱性の修正" --body "Fixes #<issue-number>"
```

### 簡易コマンド
```bash
claude "セキュリティIssue #<番号>を修正してPR作成して"
```
