# 課題1-2.5: kindでWebアプリケーションとルーティングを体験しよう

## ファイル一覧

- `test-apps.yaml`: 2つのテストアプリケーション（app1、app2）
- `simple-ingress-demo.yaml`: ConfigMapを使ったWebサーバー

## 使用方法

```bash
# アプリケーションをデプロイ
kubectl apply -f test-apps.yaml
kubectl apply -f simple-ingress-demo.yaml

# Pod状態を確認
kubectl get pods -o wide
kubectl get services

# Webサーバーにアクセス
kubectl port-forward svc/web-server-service 8000:80
# ブラウザで http://localhost:8000 にアクセス

# 個別サービスのテスト
kubectl port-forward svc/app1-service 8001:80
kubectl port-forward svc/app2-service 8002:80
```

## 学習のポイント

- ConfigMapを使った設定管理
- 複数サービスの同時運用
- NodePortとClusterIPの違い
- HTMLコンテンツの動的配信
- UTF-8エンコーディングの重要性

## トラブルシューティング

- 文字化け: `<meta charset="UTF-8">`の設定確認
- 接続エラー: port-forwardプロセスの再起動
- Pod起動失敗: `kubectl describe pod`でイベント確認