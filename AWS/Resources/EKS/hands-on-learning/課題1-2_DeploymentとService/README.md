# 課題1-2: DeploymentとServiceを作成しよう

## ファイル一覧

- `nginx-deployment.yaml`: nginx Deploymentの定義（3レプリカ）
- `nginx-service.yaml`: LoadBalancer Serviceの定義

## 使用方法

```bash
# DeploymentとServiceを作成
kubectl apply -f nginx-deployment.yaml
kubectl apply -f nginx-service.yaml

# 状態確認
kubectl get deployments
kubectl get services
kubectl get pods -o wide

# スケーリングテスト
kubectl scale deployment nginx-deployment --replicas=5

# アクセステスト
kubectl port-forward service/nginx-service 8080:80
# ブラウザで http://localhost:8080 にアクセス
```

## 学習のポイント

- Deploymentによる宣言的な管理
- Serviceによるロードバランシング
- レプリカ数の動的変更
- Podの分散配置