# 課題1-0: kindクラスターのセットアップ

## ファイル一覧

- `kind-config.yaml`: マルチノードクラスター設定ファイル

## 使用方法

```bash
# マルチノードクラスター作成
kind create cluster --config kind-config.yaml --name multi-node-cluster

# ノード確認
kubectl get nodes -o wide
```

## 学習のポイント

- kindクラスターの基本設定
- マルチノード構成の理解
- ingress-readyラベルの重要性