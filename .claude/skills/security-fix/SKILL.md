---
name: security-fix
description: GitHub セキュリティ Issue を修正し PR を作成する
disable-model-invocation: true
---

security ラベル付きのオープン Issue を修正して PR を作成してください。

## 手順

1. `gh issue list --label security --state open --limit 100` でセキュリティ Issue を取得
   - 0件の場合は「オープンなセキュリティ Issue はありません」と報告して終了
2. 各 Issue の詳細を `gh issue view <number> --comments` で確認（本文だけでなくコメントにも追加アラート情報がある場合がある）
3. Issue 本文およびコメントに記載されたファイルパスから対象プロジェクトを特定
4. `git checkout main` で main ブランチに切り替え、`git pull origin main` で最新の状態にする
5. ブランチを作成してチェックアウト（複数 Issue の場合は Issue ごとに手順4〜8を繰り返す）
6. 各プロジェクトで修正を実施:
   - **npm**:
     - 直接依存の場合: package.json のバージョンを直接更新
     - 間接依存の場合: package.json の overrides に修正バージョンを追加
     - overrides のバージョンはメジャーバージョンアップを防ぐため、固定バージョン（例: `"4.2.6"`）またはパッチ範囲（例: `"~4.2.6"`）で指定する。`>=` のようなオープンレンジは使わない
     - 修正手順（段階的に実施すること）:
       1. 既存の `package-lock.json` を保持したまま `npm install` を実行
       2. `npm ls <package>` で対象パッケージが修正バージョンに更新されたか確認
       3. 古いバージョンが残っている場合**のみ** `package-lock.json` を削除して `npm install` で再生成
   - **Python/Poetry**: pyproject.toml を更新 → `poetry lock` → `poetry export -f requirements.txt --output requirements.txt --without-hashes` で requirements.txt 再生成
   - **GitHub Actions**: アクションバージョンを更新
7. 修正の検証:
   - `npm ls <package>` でバージョンが更新されていることを確認
   - `npm audit` で対象の CVE が解消されていることを確認（他の脆弱性は対象外）
   - 生成ファイル（requirements.txt, package-lock.json 等）の内容を確認し、特定環境に依存するマーカーや不要な情報が混入していないことを検証する
   - `git diff` で意図しない変更がないことを確認
8. コミット・push・PR作成

## Issue ごとに PR を分ける

複数の Issue がある場合は、Issue ごとに別ブランチ・別 PR を作成すること。

## ブランチ・コミット規約

- ブランチ: `fix-sec/security-fix-YYYYMMDD`（同日に複数の場合は末尾に連番）
- コミットメッセージ: `fix(security): <CVE-ID> の脆弱性を修正`
- PR body に `Fixes #<issue-number>` を含める
