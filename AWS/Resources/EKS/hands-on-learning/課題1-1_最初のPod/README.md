# 課題1-1: 最初のPodを作成しよう

## ファイル一覧

- `nginx-pod.yaml`: 基本的なnginx Podの定義

## 使用方法

```bash
# Podを作成
kubectl apply -f nginx-pod.yaml

# Pod状態確認
kubectl get pods -o wide
kubectl describe pod nginx-pod

# ポートフォワードでアクセス
kubectl port-forward nginx-pod 8080:80
# ブラウザで http://localhost:8080 にアクセス
```

## 学習のポイント

- Kubernetes最小単位のPodの理解
- YAMLマニフェストの基本構造
- port-forwardによるアクセス方法