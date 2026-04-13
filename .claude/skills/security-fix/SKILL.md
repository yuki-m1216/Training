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
3. `gh api repos/<owner>/<repo>/dependabot/alerts --paginate -q '.[] | select(.state=="open")'` で open アラート全件を取得し、Issue のタイトル・本文・コメント記載の件数と突き合わせる。差分があればその分も修正対象に含める
4. Issue 本文およびコメントに記載されたファイルパス、および手順3で検出した追加アラートのファイルパスから対象プロジェクトを特定
5. `git checkout main` で main ブランチに切り替え、`git pull origin main` で最新の状態にする
6. ブランチを作成してチェックアウト（複数 Issue の場合は Issue ごとに手順5〜9を繰り返す）
7. 各プロジェクトで修正を実施:
   - **npm**:
     - 直接依存の場合: package.json のバージョンを直接更新
     - 間接依存の場合: package.json の overrides に修正バージョンを追加
     - overrides のキーは常にメジャーバージョンスコープで指定する（例: `"picomatch@2": "~2.3.2"`）。スコープなしの `"picomatch"` は将来別メジャーバージョンが追加された場合に意図しない影響を与えるため使わない
     - overrides のバージョンはメジャーバージョンアップを防ぐため、固定バージョン（例: `"4.2.6"`）またはパッチ範囲（例: `"~4.2.6"`）で指定する。`>=` のようなオープンレンジは使わない
     - 修正手順（段階的に実施すること）:
       1. 既存の `package-lock.json` を保持したまま `npm install` を実行
       2. `npm ls <package>` で対象パッケージが修正バージョンに更新されたか確認
       3. `npm view <package>@<version> dist` で `attestations.provenance`（SLSA provenance）が付与されていることを確認する。provenance がない場合はサプライチェーン攻撃リスクを検討し、広く使われる直接依存の場合は直近の compromise 情報を確認する
       4. 古いバージョンが残っている場合**のみ** `package-lock.json` を削除して `npm install` で再生成
       5. `git diff -- package-lock.json` で差分が対象パッケージの更新のみであることを確認する。npm バージョン差等により無関係な変更（`"dev": true` の追加等）が混入した場合は、以下のフォールバック手順で churn を最小化する:
          1. `git checkout main -- package-lock.json` でロックファイルを復元
          2. 対象パッケージの全エントリ（version, resolved, integrity, dependencies, funding 等のメタデータを含む）を手動で更新する。同一パッケージが複数箇所に出現する場合はすべて更新すること
          3. `npm ci` でロックファイルの整合性を検証
   - **Python/Poetry**: pyproject.toml を更新 → `poetry lock` → `poetry export -f requirements.txt --without-hashes` で requirements.txt を生成。`requires-python` が特定バージョン固定（例: `"3.10.5"`）の場合、出力に `python_full_version == "3.10.5"` マーカーが全行に付与されるため、以下の後処理でマーカーを除去してからファイルに書き出す:
     ```bash
     poetry export -f requirements.txt --without-hashes | \
       sed 's/[[:space:]]*;[[:space:]]*python_full_version == "[^"]*" and /; /g' | \
       sed 's/[[:space:]]*;[[:space:]]*python_full_version == "[^"]*"//g' > requirements.txt
     ```
     後処理後、`git diff main -- <path>/requirements.txt` で main と比較し、意図した変更（バージョン更新）のみであることを確認する
   - **GitHub Actions**: アクションバージョンを更新
8. 修正の検証:
   - `npm ls <package>` でバージョンが更新されていることを確認
   - `npm audit` で対象の CVE が解消されていることを確認（他の脆弱性は対象外）
   - requirements.txt: sed で除去対象とした `python_full_version == "..."` マーカーが残っていないことを確認する（`python_full_version` を用いた `< "3.12"` などの通常のバージョン条件や `platform_python_implementation` 等の通常のプラットフォームマーカーは正常であり、除去不要）
   - `git diff` で意図しない変更がないことを確認
9. コミット・push・PR作成

## Issue ごとに PR を分ける

複数の Issue がある場合は、Issue ごとに別ブランチ・別 PR を作成すること。

## ブランチ・コミット規約

- ブランチ: `fix-sec/security-fix-YYYYMMDD`（同日に複数の場合は末尾に連番）
- コミットメッセージ: `fix(security): <CVE-ID> の脆弱性を修正`
- PR body には以下を含める（Issue 本文の記載有無に関わらず PR body は自己完結させる）:
  - 本 PR で対応する CVE / Dependabot アラート ID の明示リスト
  - Issue へのリンク:
    - PR が Issue の全アラートを修正する場合: `Fixes #<issue-number>`（マージ時に Issue が自動クローズされる）
    - 一部のアラートのみ修正する場合: `Related #<issue-number>`（Issue はオープンのまま残す）
    - Issue 本文に記載がないが Dependabot で検出されたアラートを修正する場合: `Related #<issue-number>` とした上で、該当アラートが Issue 本文未記載である旨を PR body に明記する
