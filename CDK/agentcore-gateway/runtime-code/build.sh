#!/usr/bin/env bash
# AgentCore Runtime 直接コードデプロイ用の依存バンドルを build/ に生成する。
# Runtime の実行基盤は linux/arm64 + Python 3.13 のため、手元の環境(x86)ではなく
# ターゲット向けの wheel を取得する必要がある(取り違えるとデプロイ後に import エラー)。
set -euo pipefail

# スクリプトの置き場所を基準に動く(どのディレクトリから叩いても同じ結果にする)
cd "$(dirname "$0")"

# 前回の残骸(削除済み依存など)が混入しないよう毎回作り直す
rm -rf build
mkdir build

# --python-platform/--python-version: Runtime(linux/arm64, Python 3.13)向けの wheel を指定
# --only-binary=:all:  : arm64 wheel が無いパッケージはソースビルドせずエラーにする
#                        (黙って x86 バイナリが混入するのが最悪パターンのため)
uv pip install \
  --python-platform aarch64-manylinux2014 \
  --python-version 3.13 \
  --only-binary=:all: \
  --target build \
  -r requirements.txt

# エントリポイントは zip のルートに置く必要がある(CDK は build/ ごと zip 化する)
cp agent.py build/

# x86 でコンパイルされたバイトコードの混入防止(公式の明記事項)
find build -type d -name '__pycache__' -exec rm -rf {} +

# POSIX 権限の正規化: ディレクトリ 755 / ファイル 644 (公式の要求)
find build -type d -exec chmod 755 {} +
find build -type f -exec chmod 644 {} +

echo "OK: $(du -sh build | cut -f1) bundled into runtime-code/build/"
