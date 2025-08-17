# タスク完了時のチェックリスト

## 開発完了時に実行すべきコマンド

### TypeScript/JavaScript プロジェクト
1. **リンティング**:
   ```bash
   npm run lint          # ESLintチェック
   ```

2. **ビルド確認**:
   ```bash
   npm run build         # プロダクションビルド
   ```

3. **型チェック**:
   ```bash
   # TypeScriptプロジェクトの場合
   npx tsc --noEmit      # 型チェックのみ実行
   ```

### Python プロジェクト
1. **依存関係確認**:
   ```bash
   pip install -r requirements.txt
   ```

2. **テスト実行**:
   ```bash
   # テストファイルが存在する場合
   python -m pytest
   # または
   python test_main.py
   ```

### Terraform
1. **構文チェック**:
   ```bash
   terraform validate    # 構文検証
   terraform fmt         # フォーマット
   ```

2. **プラン確認**:
   ```bash
   terraform plan        # 実行計画の確認
   ```

## RAGシステム特有のデプロイ順序
RAGシステムの場合、以下の順序でデプロイする：
1. `embed_doc` - ドキュメント埋め込みサービス
2. `vector_database` - ベクターデータベースセットアップ
3. `answer_user_query` - クエリ処理サービス
4. `fe` - フロントエンドアプリケーション

## セキュリティチェック
- AWS認証情報がコードにハードコーディングされていないか確認
- 機密情報がcommitに含まれていないか確認
- IAMロールの権限が最小権限の原則に従っているか確認

## Git操作
- 変更をcommitする前に必ず上記チェックを実行
- commit前にコードレビューを実施