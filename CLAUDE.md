# CLAUDE.md

## Git Workflow

- **mainブランチへの直接コミット・プッシュは禁止**
- コード修正時は必ずフィーチャーブランチを作成すること
- ブランチ命名規則: `fix/`, `feat/`, `chore/`, `docs/` などのプレフィックスを使用
- 修正完了後はプルリクエストを作成し、mainへのマージはPR経由で行うこと

## Security Fix Workflow

セキュリティ修正（security ラベルの Issue や Dependabot アラートへの対応）を頼まれたら、ユーザーに `/security-fix` の実行を案内する（push・PR 作成まで行うため、スキルは手動起動に限定している）。
Git Workflowのルール（ブランチ作成・PR経由マージ）はセキュリティ修正にも適用されます。
