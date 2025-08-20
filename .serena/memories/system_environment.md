# システム環境情報

## 利用可能なツールとバージョン

### 開発ツール
- **Terraform**: `/home/linuxbrew/.linuxbrew/bin/terraform` - インフラストラクチャ管理
- **AWS CLI**: `/snap/bin/aws` - AWSサービス操作
- **Node.js**: `/home/linux/.nvm/versions/node/v22.17.0/bin/node` - JavaScript/TypeScriptランタイム
- **npm**: `/home/linux/.nvm/versions/node/v22.17.0/bin/npm` - Node.jsパッケージ管理
- **Python**: `python3` (v3.13.5) - Pythonランタイム（`python`コマンドは利用不可）
- **pyenv**: `/home/linuxbrew/.linuxbrew/bin/pyenv` - Pythonバージョン管理
- **Poetry**: `/home/linuxbrew/.linuxbrew/bin/poetry` - Pythonパッケージ管理

### オペレーティングシステム
- **Platform**: Linux
- **Environment**: WSL2 (Windows Subsystem for Linux)

### Git環境
- **Current branch**: refactor-directory
- **Main branch**: main
- **Status**: clean（変更なし）

## パッケージ管理

### Node.js/TypeScript
- **Node.js管理**: nvm使用
- **パッケージ管理**: npm
- **主要フレームワーク**: 
  - Next.js 15.2.4（Turbopack対応）
  - React 19
  - TypeScript 5.x
  - webpack 5.x
  - TailwindCSS v4

### Python
- **バージョン管理**: pyenv
- **パッケージ管理**: Poetry
- **推奨Pythonバージョン**: 3.10.5（RAGシステム用）
- **現在のシステムPython**: 3.13.5

## 認証設定

### AWS
```bash
# 推奨方法（プロファイル使用）
export AWS_PROFILE="your-profile"

# 直接認証情報（テスト用のみ）
export TF_VAR_access_key="AKIAXXXXXXXXXXXXXXXXXX"
export TF_VAR_secret_key="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
```

### New Relic
```bash
export NEW_RELIC_ACCOUNT_ID="<your-account-id>"
export NEW_RELIC_API_KEY="<your-api-key>"
export TF_VAR_NEW_RELIC_ACCOUNT_ID="<your-account-id>"
```

## 基本的なLinuxコマンド

### ファイル操作
- `ls` - ファイル一覧表示
- `cd` - ディレクトリ移動
- `mkdir` - ディレクトリ作成
- `cp` - ファイルコピー
- `mv` - ファイル移動/リネーム
- `rm` - ファイル削除

### テキスト処理
- `grep` - テキスト検索
- `find` - ファイル検索
- `cat` - ファイル内容表示
- `less` - ファイル内容ページ表示
- `head` - ファイル先頭表示
- `tail` - ファイル末尾表示

### Git操作
- `git status` - 作業ディレクトリの状態確認
- `git add` - ファイルをステージング
- `git commit` - コミット作成
- `git push` - リモートリポジトリへプッシュ
- `git pull` - リモートから更新取得
- `git branch` - ブランチ操作

## ディレクトリ構造の特徴

### 現在の作業ディレクトリ
- **Location**: `/home/linux/git/Training`
- **Main directory**: `Terraform/` - すべてのプロジェクトファイルを含む
- **Structure**: モジュラー構造（AWS/NewRelic分離、modules/Resources分離）

### 注意事項
- プロジェクトのルートは`Terraform/`ディレクトリ
- すべての作業は`Terraform/`ディレクトリ以下で実行
- ファイルパスは`Terraform/`からの相対パスで指定