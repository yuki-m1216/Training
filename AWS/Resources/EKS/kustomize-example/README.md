# EKS + Kustomize サンプル

このディレクトリには、TerraformでEKSクラスターを作成し、kustomizeを使用してKubernetesアプリケーションをデプロイするサンプルが含まれています。

## 構成

```
kustomize-example/
├── main.tf                    # EKSクラスター定義
├── data.tf                    # データソース
├── outputs.tf                 # 出力値
├── variables.tf               # 変数定義
├── provider.tf                # プロバイダー設定
├── versions.tf                # バージョン制約
├── README.md                  # このファイル
└── k8s/                       # Kubernetesマニフェスト
    ├── base/                  # ベースマニフェスト
    │   ├── namespace.yaml
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   └── kustomization.yaml
    └── overlays/              # 環境別設定
        ├── dev/
        │   ├── kustomization.yaml
        │   └── deployment-patch.yaml
        ├── staging/
        │   ├── kustomization.yaml
        │   └── deployment-patch.yaml
        └── prod/
            ├── kustomization.yaml
            └── deployment-patch.yaml
```

## デプロイ手順

### 1. EKSクラスターの作成

```bash
# 環境変数の設定
export TF_VAR_access_key="AKIAXXXXXXXXXXXXXXXXXX"
export TF_VAR_secret_key="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

# Terraformでクラスター作成
terraform init
terraform plan
terraform apply
```

### 2. kubectlの設定

```bash
# クラスター情報をkubeconfigに追加
aws eks update-kubeconfig --region ap-northeast-1 --name kustomize-example-cluster

# 接続確認
kubectl get nodes
```

### 3. kustomizeを使用したアプリケーションデプロイ

```bash
# 開発環境にデプロイ
kubectl apply -k k8s/overlays/dev

# ステージング環境にデプロイ
kubectl apply -k k8s/overlays/staging

# 本番環境にデプロイ
kubectl apply -k k8s/overlays/prod
```

### 4. デプロイの確認

```bash
# ポッドの確認
kubectl get pods -n app-namespace

# サービスの確認
kubectl get services -n app-namespace

# デプロイメントの確認
kubectl get deployments -n app-namespace
```

## kustomizeの使用法

### デプロイ前の設定確認

```bash
# 開発環境の設定内容を確認
kubectl kustomize k8s/overlays/dev

# ステージング環境の設定内容を確認
kubectl kustomize k8s/overlays/staging

# 本番環境の設定内容を確認
kubectl kustomize k8s/overlays/prod
```

### 環境別の設定

- **開発環境**: 1レプリカ、リソース制限少、nginx:1.21-alpine
- **ステージング環境**: 2レプリカ、標準リソース制限、nginx:1.22
- **本番環境**: 5レプリカ、高リソース制限、nginx:1.22-alpine

## クリーンアップ

```bash
# Kubernetesリソースの削除
kubectl delete -k k8s/overlays/dev
kubectl delete -k k8s/overlays/staging
kubectl delete -k k8s/overlays/prod

# EKSクラスターの削除
terraform destroy
```

## トラブルシューティング

### よくある問題

1. **kubectlがクラスターに接続できない**
   ```bash
   aws eks update-kubeconfig --region ap-northeast-1 --name kustomize-example-cluster
   ```

2. **ポッドが起動しない**
   ```bash
   kubectl describe pod <pod-name> -n app-namespace
   kubectl logs <pod-name> -n app-namespace
   ```

3. **ノードが起動しない**
   ```bash
   kubectl get nodes
   kubectl describe node <node-name>
   ```