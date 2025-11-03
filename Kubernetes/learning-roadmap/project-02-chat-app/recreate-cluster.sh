#!/bin/bash
set -e

echo "=== Kindクラスタの再作成 ==="

# 既存クラスタの削除
echo "1. 既存クラスタを削除中..."
kind delete cluster --name chat-app

# 新しいクラスタの作成（ポートマッピング付き）
echo "2. 新しいクラスタを作成中..."
kind create cluster --config kind-config.yaml

# クラスタの確認
echo "3. クラスタの状態確認..."
kubectl cluster-info --context kind-chat-app

# コンテナのポート確認
echo "4. ポートマッピングの確認..."
docker ps --filter "name=chat-app-control-plane" --format "table {{.Names}}\t{{.Ports}}"

echo ""
echo "✓ クラスタの再作成が完了しました"
echo ""
echo "次のステップ:"
echo "  1. Ingress Controllerのインストール: kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml"
echo "  2. リソースのデプロイ: kubectl apply -k k8s/overlays/dev"
