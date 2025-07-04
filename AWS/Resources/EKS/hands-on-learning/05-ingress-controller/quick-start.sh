#!/bin/bash

# Nginx Ingress Controller ハンズオン クイックスタートスクリプト

set -e

echo "=== Nginx Ingress Controller ハンズオン クイックスタート ==="

# 設定可能な変数
CLUSTER_NAME=${CLUSTER_NAME:-nginx-demo}
METHOD=${METHOD:-manifest}  # manifest または helm

echo "クラスタ名: $CLUSTER_NAME"
echo "デプロイ方法: $METHOD"

# 1. kindクラスタの作成
echo "1. kindクラスタを作成中..."
if kind get clusters | grep -q "^$CLUSTER_NAME$"; then
    echo "クラスタ '$CLUSTER_NAME' は既に存在します。"
else
    kind create cluster --config kind-cluster.yaml --name $CLUSTER_NAME
fi

# contextの確認
echo "Kubernetesコンテキストを確認中..."
kubectl config current-context

if [ "$METHOD" = "manifest" ]; then
    echo "=== マニフェストベースデプロイメント ==="
    
    # 2. Nginx Ingress Controllerのデプロイ
    echo "2. Nginx Ingress Controllerをデプロイ中..."
    kubectl apply -f nginx-ingress-controller.yaml
    
    # 3. サンプルアプリケーションのデプロイ
    echo "3. サンプルアプリケーションをデプロイ中..."
    kubectl apply -f sample-app.yaml
    
    # 4. Ingressリソースの作成
    echo "4. Ingressリソースを作成中..."
    kubectl apply -f ingress-demo.yaml
    
elif [ "$METHOD" = "helm" ]; then
    echo "=== Helmベースデプロイメント ==="
    
    # Helmのインストール確認
    if ! command -v helm &> /dev/null; then
        echo "Helmをインストール中..."
        chmod +x install-helm.sh
        ./install-helm.sh
    fi
    
    # 2. Ingress Controllerのインストール
    echo "2. Helm リポジトリを追加中..."
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update
    
    echo "3. Nginx Ingress Controllerをインストール中..."
    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --create-namespace \
        --set controller.hostPort.enabled=true \
        --set controller.service.type=NodePort
    
    # 04-web-applicationのアプリケーションをデプロイ
    echo "4. テストアプリケーションをデプロイ中..."
    kubectl apply -f ../04-web-application/test-apps.yaml
    kubectl apply -f ../04-web-application/simple-ingress-demo.yaml
    
    echo "5. Ingressリソースを作成中..."
    kubectl apply -f advanced-ingress.yaml
fi

# Pod起動待機
echo "5. Podの起動を待機中..."
kubectl wait --for=condition=ready pod --all --timeout=300s -n ingress-nginx || true
kubectl wait --for=condition=ready pod --all --timeout=300s || true

# ホスト設定の追加
echo "6. テスト用ホスト設定を追加中..."
if [ "$METHOD" = "manifest" ]; then
    sudo tee -a /etc/hosts > /dev/null <<EOF
127.0.0.1 nginx-demo.local
127.0.0.1 httpbin.local
127.0.0.1 demo.local
127.0.0.1 secure.local
EOF
fi

# 状態確認
echo "=== デプロイ状況確認 ==="
echo "Pods:"
kubectl get pods -A
echo ""
echo "Services:"
kubectl get svc -A
echo ""
echo "Ingress:"
kubectl get ingress
echo ""

# テストコマンドの提示
echo "=== テストコマンド ==="
if [ "$METHOD" = "manifest" ]; then
    echo "以下のコマンドでテストできます:"
    echo "curl -H \"Host: nginx-demo.local\" http://localhost/"
    echo "curl -H \"Host: httpbin.local\" http://localhost/"
    echo "curl -H \"Host: demo.local\" http://localhost/nginx/"
    echo "curl -H \"Host: demo.local\" http://localhost/httpbin/get"
else
    echo "以下のコマンドでテストできます:"
    echo "curl http://localhost/"
    echo "curl http://localhost/app1"
    echo "curl http://localhost/app2"
fi

echo ""
echo "=== セットアップ完了! ==="
echo "詳細な使用方法はREADME.mdを参照してください。"