# タスク完了時のワークフロー

## 基本的なタスク完了チェックリスト

### Terraformタスクの場合
1. **コード品質確認**
   ```bash
   terraform fmt      # コードフォーマット
   terraform validate # 構文検証
   terraform plan     # 実行プランの確認
   ```

2. **ファイル構造確認**
   - 必要なファイルが揃っているか（main.tf、variables.tf、outputs.tf、versions.tf、provider.tf）
   - 命名規約に従っているか
   - 適切なディレクトリに配置されているか

3. **セキュリティチェック**
   - ハードコーディングされた認証情報がないか
   - 適切な権限設定がされているか
   - 機密情報が適切に保護されているか

### TypeScript/JavaScript Lambda関数タスクの場合
1. **ビルドとテスト**
   ```bash
   npm run build      # TypeScriptコンパイル確認
   npm run lint       # ESLintチェック（利用可能な場合）
   ```

2. **ファイル構造確認**
   - package.json、tsconfig.json、webpack.config.jsが適切に設定されているか
   - ソースコードがlambda/src/ディレクトリに配置されているか

### Next.jsフロントエンドタスクの場合
1. **ビルドとリント**
   ```bash
   npm run build      # プロダクションビルド確認
   npm run lint       # ESLintチェック
   ```

2. **開発サーバー確認**
   ```bash
   npm run dev        # 開発サーバーが正常に起動するか確認
   ```

### Pythonタスクの場合
1. **依存関係とビルド**
   ```bash
   poetry install --no-root                    # 依存関係インストール
   poetry run pip install -r requirements.txt # Lambda用パッケージ確認
   ```

2. **Pythonバージョン確認**
   ```bash
   pyenv local 3.10.5  # 適切なPythonバージョンが設定されているか
   ```

## RAGシステム特有のワークフロー

RAGシステムのデプロイは特定の順序で実行する必要があります：

1. **embed_doc** - ドキュメント埋め込みサービス
2. **vector_database** - ベクターデータベースセットアップ  
3. **answer_user_query** - クエリ処理サービス
4. **fe** - フロントエンドアプリケーション

各段階で以下を確認：
```bash
terraform plan && terraform apply
```

## Git関連の最終確認

1. **ステータス確認**
   ```bash
   git status         # 変更ファイルの確認
   git diff          # 変更内容の確認
   ```

2. **コミット前チェック**
   - .gitignoreが適切に設定されているか
   - 機密情報がコミットされていないか
   - コミットメッセージが適切か

## ドキュメント更新

必要に応じて以下のドキュメントを更新：
- README.mdの更新
- CLAUDE.mdの更新（新しいパターンや規約がある場合）
- 変更ログの記録

## 最終確認事項

- [ ] すべてのテストが通過している
- [ ] ビルドエラーがない
- [ ] セキュリティ要件を満たしている
- [ ] 命名規約に準拠している
- [ ] 適切なディレクトリ構造になっている
- [ ] 必要なドキュメントが更新されている
- [ ] gitignoreが適切に設定されている