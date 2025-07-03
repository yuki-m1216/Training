# 課題1-2.6: Helm を使った本格的な Ingress Controller 体験（上級者向け）

## 概要
Helmパッケージマネージャーを使って、本格的なNGINX Ingress Controllerを構築し、企業環境に近いIngress運用を学習します。

## ファイル一覧

- `helmfile-ingress-nginx.yaml`: Helmfile設定（推奨）
- `advanced-ingress.yaml`: 本格的なIngressリソース定義
- `install-helm.sh`: Helm自動インストールスクリプト
- `README.md`: この説明ファイル

## 前提条件

1. **基本課題の完了**: 課題1-2.5までが正常に動作していること
2. **Helmのインストール**: パッケージマネージャーが必要
3. **十分な学習時間**: エラー対応を含めて1-2時間程度

## クイックスタート

### 1. Helmのインストール
```bash
# 自動インストールスクリプトを使用
./install-helm.sh

# または手動インストール
# macOS: brew install helm
# Linux: curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### 2. Ingress Controllerのインストール
```bash
# Helmリポジトリ追加
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# インストール実行
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.hostPort.enabled=true \
  --set controller.service.type=NodePort

# インストール完了まで待機
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

### 3. Ingressリソースの作成
```bash
# 前提: 課題1-2.5のアプリケーションがデプロイ済み
kubectl get pods
kubectl get services

# Ingressリソースをデプロイ
kubectl apply -f advanced-ingress.yaml

# 動作確認
kubectl get ingress
kubectl describe ingress web-ingress
```

### 4. アクセステスト
```bash
# コマンドラインでのテスト
curl http://localhost/
curl http://localhost/app1
curl http://localhost/app2

# ブラウザでのテスト
# http://localhost/
# http://localhost/app1
# http://localhost/app2
```

## トラブルシューティング

### よくある問題と解決方法

1. **Helmのインストールエラー**
```bash
# バージョン確認
helm version
# エラーの場合は再インストール
```

2. **Ingress Controller起動失敗**
```bash
# Pod状態確認
kubectl get pods -n ingress-nginx
kubectl describe pods -n ingress-nginx

# ログ確認
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

3. **アクセスできない（404エラー）**
```bash
# Ingressリソース確認
kubectl get ingress
kubectl describe ingress web-ingress

# サービス確認
kubectl get endpoints
kubectl get services
```

4. **Permission Denied エラー**
```bash
# hostPortのアクセス権限問題の場合
kubectl get nodes -o wide
kubectl describe nodes
```

## 学習効果

### 習得できるスキル
- **Helm**: Kubernetesパッケージマネージャーの実践的活用
- **Ingress Controller**: 企業レベルのトラフィック制御
- **NGINX設定**: アノテーションを使った高度な設定
- **デバッグ技術**: 複雑なシステムのトラブルシューティング

### 実際の企業環境との関連
- Production環境でのIngress Controller運用方法
- Helmを使った継続的デプロイメント（CD）
- 監視とログ管理の基礎
- SSL/TLS設定の準備

## 注意事項

- この課題は **上級者向け** です
- エラーが多発する場合は、課題1-2.5の基本的な方法に戻ることを推奨
- 学習目的のため、SSL設定は無効化しています
- 本番環境では追加のセキュリティ設定が必要

## 次のステップ

成功した場合：
- AWS EKS環境でのALB Ingress Controller学習
- SSL/TLS設定の追加
- Prometheus監視の導入

## 参考資料

- [NGINX Ingress Controller公式ドキュメント](https://kubernetes.github.io/ingress-nginx/)
- [Helm公式ドキュメント](https://helm.sh/docs/)
- [Kubernetes Ingress概念](https://kubernetes.io/docs/concepts/services-networking/ingress/)