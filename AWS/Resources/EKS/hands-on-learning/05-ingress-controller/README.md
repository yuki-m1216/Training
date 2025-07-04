# 05-ingress-controller: Nginx Ingress Controller

このディレクトリには、kindを使ったNginx Ingress Controllerの包括的な学習ファイルが含まれています。

## ファイル一覧

### 基本ファイル（マニフェストベース）
- `kind-cluster.yaml`: Ingress用ポートマッピング設定のkindクラスタ設定
- `nginx-ingress-controller.yaml`: 完全なマニフェストベースのIngress Controller
- `sample-app.yaml`: 高度なサンプルアプリケーション（nginx、httpbin）
- `ingress-demo.yaml`: 複数種類のIngressリソース

### Helmファイル（上級者向け）
- `helmfile-ingress-nginx.yaml`: Helmfile設定
- `advanced-ingress.yaml`: 高度なIngressリソース定義
- `install-helm.sh`: Helm自動インストールスクリプト

### 自動化
- `quick-start.sh`: 自動セットアップスクリプト（manifest/helm選択可能）

## 使用方法

メインのハンズオンガイドを参照してください: `../aws_k8s_roadmap_fixed.md` の「課題1-2.6」セクション

### クイックスタート
```bash
# マニフェストベースアプローチ
./quick-start.sh

# Helmベースアプローチ
METHOD=helm ./quick-start.sh
```