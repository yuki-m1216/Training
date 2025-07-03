#!/bin/bash

# Helm インストールスクリプト

echo "=== Helm インストール開始 ==="

# OS検出
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Linux環境でのHelmインストール"
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "macOS環境でのHelmインストール"
    if command -v brew &> /dev/null; then
        brew install helm
    else
        echo "Homebrewが見つかりません。手動でHelmをインストールしてください。"
        exit 1
    fi
else
    echo "サポートされていないOS: $OSTYPE"
    exit 1
fi

# インストール確認
echo "=== Helmバージョン確認 ==="
helm version

echo "=== Helm インストール完了 ==="