---
name: note
description: マージ済み PR から再利用できる学びを抽出し、Obsidian Vault（tech-notes）にノートとして書き出す
disable-model-invocation: true
argument-hint: "[PR番号]"
---

マージ済み PR の作業から、プロジェクトを横断して再利用できる学びを抽出し、Obsidian Vault にノートとして書き出します。

- 引数に PR 番号が指定された場合: その PR を対象にする
- 引数なしの場合: 直近のマージ済み PR を対象にする

Vault の場所: `/mnt/c/Users/Yuki Mitsuyama/obsidian-vaults/tech-notes`

## 手順

### 1. Vault のルールを読む

- Vault 直下の `CLAUDE.md` を読む。ノートの書き方（ファイル名、frontmatter の `type`／`tags`／`source`、マスク規則、置き場所の分担）は**この CLAUDE.md を正とし**、本スキルには重ねて書かない

### 2. 対象 PR の特定

- 引数ありの場合: `gh pr view <number> --json number,title,url,state,mergedAt`
  - `state` が `MERGED` でなければ、その旨を伝えて続けるかユーザーに確認する
- 引数なしの場合: `gh pr list --state merged --limit 5 --json number,title,mergedAt` で直近の PR を一覧表示し、ユーザーにどの PR を対象にするか確認する

### 3. 材料の収集

- `gh pr view <number> --json title,body,url,files` で概要と変更ファイルを確認
- `gh pr diff <number>` で差分を確認
- 変更ファイルに docs（検証ログ・整理・ランブック等）が含まれていれば、該当ファイルを読む
- 会話中にこの PR の作業経緯（試行錯誤、詰まった点、判断の理由）があれば材料に含める

### 4. 学びの候補を抽出

Vault の `CLAUDE.md` の判断基準（「別のプロジェクトでもまた使うか？」）で候補を選ぶ。

- **対象にする**: ハマりどころと原因、公式ドキュメントに無く実測で分かった挙動、設計判断とその理由、再利用できる手順・設定
- **対象にしない**: プロジェクト固有の進捗・現在地、PR の作業内容の要約そのもの、公式ドキュメントを読めば済む一般論

候補ごとに既存ノートを検索し、新規か追記かを決める:

- `grep -ril "<キーワード>" "<Vault>" --include="*.md"` で同じトピックのノートを探す
- frontmatter の `tags` も確認する（`grep -rl "tags:.*<tag>" "<Vault>" --include="*.md"`）

### 5. 候補の提示と承認

候補が 0 件の場合は「この PR から Vault に書き出す学びはありませんでした」と報告して終了する。

候補を以下の形式で提示し、ユーザーが承認したものだけを書く:

```
### ノート候補

| # | 新規／追記 | ファイル名 | type | tags | 要点（1 行） |
|---|---|---|---|---|---|
| 1 | 新規 | `xxx-yyy.md` | pitfall | aws, cdk | … |
| 2 | 追記 → `zzz.md` | — | insight | … | … |
```

### 6. ノートを書く

- Vault の `CLAUDE.md` のルールに従う
- `source` に PR の URL を入れる。詳細は PR・Training のファイルへのリンクで示し、内容をコピーしない
- 追記する場合は対象ノートを読んでから編集し、`source` に PR の URL を足す
- 関連ノートがあれば `[[ノート名]]` で相互にリンクする
- ノートの削除・リネームが必要になった場合は、実行前にユーザーに確認する

### 7. 秘匿情報のスキャン

書いた（追記した）ノートに秘匿情報が無いか確認する:

```bash
grep -nE '[0-9]{12}|[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}|eyJ[A-Za-z0-9_-]{10,}|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}|(ap|us|eu)-[a-z]+-[0-9]_[A-Za-z0-9]+' <書いたノート>
```

- ヒットした場合は内容を確認し、Vault の `CLAUDE.md` のマスク規則に従って置き換える（URL 中の数字など誤検知は残してよい）

### 8. 報告

- 作成・更新したノートの一覧（ファイル名、新規／追記、要点）を報告する
- Vault は Git 管理していないため、コミットは不要
