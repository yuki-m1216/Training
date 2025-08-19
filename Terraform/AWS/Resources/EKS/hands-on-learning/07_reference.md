# リファレンス・サポート

**[← レベル5: 本格運用課題](06_level5_production.md) | [メインページに戻る →](README.md)**

## 学習の進め方

1. **各課題を順番に実施** - 前の課題で作成したリソースを活用
2. **エラーログを確認** - 問題が発生したら必ずログを確認
3. **クリーンアップ** - 各課題完了後はリソースを削除してコスト管理
4. **ドキュメント化** - 学んだことをメモして知識を定着

## 📊 学習進捗管理

### 推定学習時間とマイルストーン
- **レベル1**: 1-2週間 (基礎固め)
- **レベル2**: 2-3週間 (クラウド実践)
- **レベル3**: 3-4週間 (運用技術)
- **レベル4**: 2-3週間 (自動化)
- **レベル5**: 4-6週間 (本格運用)

**合計: 12-18週間**

### 📋 学習進捗チェックリスト

#### レベル1: Kubernetes基礎
- [ ] **課題1-0**: kindクラスターセットアップ完了
- [ ] **課題1-1**: 初回Pod作成・操作完了
- [ ] **課題1-2**: Deployment/Service理解・実装完了
- [ ] **課題1-2.5**: 複数アプリケーション管理完了
- [ ] **課題1-2.6**: Ingress Controller構築完了
- [ ] **課題1-3**: カスタムアプリケーション作成完了
- [ ] **課題1-4**: 運用・デバッグ技術習得完了

**レベル1完了目安**: kubectl基本操作、YAML記述、基本トラブルシューティングができる

#### レベル2: AWS EKS入門
- [ ] **課題2-1**: EKSクラスター作成完了
- [ ] **課題2-2**: ECR連携・プライベートレジストリ活用完了
- [ ] **課題2-3**: AWS Load Balancer Controller設定完了

**レベル2完了目安**: AWS上でKubernetesクラスターを運用できる

#### レベル3: 実用的な運用機能
- [ ] **課題3-1**: ConfigMap/Secrets管理完了
- [ ] **課題3-2**: 永続ストレージ・StatefulSet実装完了
- [ ] **課題3-3**: ヘルスチェック・モニタリング構築完了

**レベル3完了目安**: 本番相当の運用設定ができる

#### レベル4: 自動化とCI/CD
- [ ] **課題4-1**: GitOpsパイプライン構築完了
- [ ] **課題4-2**: 完全自動化パイプライン実装完了

**レベル4完了目安**: 自動化されたデプロイメントパイプラインを構築できる

#### レベル5: 本格運用課題
- [ ] **課題5-1**: マイクロサービスアーキテクチャ実装完了
- [ ] **課題5-2**: セキュリティ強化実装完了

**レベル5完了目安**: エンタープライズレベルのKubernetes運用ができる

### 🎖️ 達成度バッジシステム

#### 🥉 ブロンズレベル (レベル1-2完了)
**取得スキル**: Kubernetes基礎、AWS EKS基本操作
**活用可能場面**: 開発環境構築、基本的なコンテナデプロイ

#### 🥈 シルバーレベル (レベル1-3完了)  
**取得スキル**: 実用的運用機能、設定管理、監視
**活用可能場面**: ステージング環境運用、チーム開発支援

#### 🥇 ゴールドレベル (レベル1-4完了)
**取得スキル**: 自動化、CI/CD、GitOps
**活用可能場面**: 本番環境構築、DevOps実践

#### 💎 プラチナレベル (全レベル完了)
**取得スキル**: エンタープライズ運用、セキュリティ、アーキテクチャ設計
**活用可能場面**: 大規模システム設計・運用、技術リーダーシップ

### 週次レビューテンプレート
```markdown
## 学習週次レビュー - Week [X]

### 今週完了した課題
- [ ] 課題名1
- [ ] 課題名2

### 学んだ重要な概念
1. 
2. 
3. 

### 躓いた箇所と解決方法
- 問題: 
- 解決策: 

### 来週の学習計画
- 目標課題: 
- 重点学習項目: 

### 理解度自己評価 (1-5)
- 概念理解: /5
- 実装能力: /5  
- 運用判断: /5
```

## kubectl コマンドリファレンス

### 基本操作
```bash
# クラスター情報
kubectl cluster-info
kubectl config current-context
kubectl config get-contexts
kubectl config use-context [CONTEXT_NAME]

# ノード確認
kubectl get nodes
kubectl get nodes -o wide
kubectl describe node [NODE_NAME]
```

### リソース操作
```bash
# リソース確認（基本）
kubectl get pods
kubectl get services
kubectl get deployments
kubectl get ingress
kubectl get pv,pvc

# 詳細表示
kubectl get pods -o wide
kubectl get pods -o yaml [POD_NAME]
kubectl describe pod [POD_NAME]
kubectl describe service [SERVICE_NAME]

# 全ネームスペース
kubectl get pods --all-namespaces
kubectl get pods -A

# ラベルでフィルタ
kubectl get pods -l app=nginx
kubectl get pods -l environment=production

# リアルタイム監視
kubectl get pods -w
kubectl get events -w
```

### リソース作成・更新・削除
```bash
# 作成・更新
kubectl apply -f [FILE_NAME].yaml
kubectl apply -f ./manifests/
kubectl apply -k ./kustomize/

# 削除
kubectl delete -f [FILE_NAME].yaml
kubectl delete pod [POD_NAME]
kubectl delete deployment [DEPLOYMENT_NAME]
kubectl delete service [SERVICE_NAME]

# 強制削除
kubectl delete pod [POD_NAME] --force --grace-period=0

# ラベルで一括削除
kubectl delete pods,services -l app=nginx
```

### スケーリング
```bash
# Deploymentのスケール
kubectl scale deployment [DEPLOYMENT_NAME] --replicas=5

# 自動スケーリング
kubectl autoscale deployment [DEPLOYMENT_NAME] --cpu-percent=70 --min=1 --max=10

# スケール状況確認
kubectl get hpa
```

### ログとデバッグ
```bash
# ログ確認
kubectl logs [POD_NAME]
kubectl logs [POD_NAME] -c [CONTAINER_NAME]  # 複数コンテナの場合
kubectl logs -f [POD_NAME]  # フォロー
kubectl logs --tail=50 [POD_NAME]  # 最新50行
kubectl logs -l app=nginx  # ラベルで一括取得

# 前回のコンテナのログ
kubectl logs [POD_NAME] --previous

# イベント確認
kubectl get events
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl get events --field-selector involvedObject.name=[POD_NAME]

# コンテナ内でコマンド実行
kubectl exec -it [POD_NAME] -- /bin/bash
kubectl exec -it [POD_NAME] -- sh
kubectl exec [POD_NAME] -- ls -la /app
```

### ポートフォワーディング
```bash
# Pod へのポートフォワード
kubectl port-forward [POD_NAME] 8080:80

# Service へのポートフォワード
kubectl port-forward service/[SERVICE_NAME] 8080:80

# Deployment へのポートフォワード
kubectl port-forward deployment/[DEPLOYMENT_NAME] 8080:80
```

### ConfigMap と Secret
```bash
# ConfigMap作成
kubectl create configmap [CONFIG_NAME] --from-file=config.properties
kubectl create configmap [CONFIG_NAME] --from-literal=key1=value1 --from-literal=key2=value2

# Secret作成
kubectl create secret generic [SECRET_NAME] --from-literal=username=admin --from-literal=password=secret
kubectl create secret docker-registry [SECRET_NAME] --docker-server=[SERVER] --docker-username=[USER] --docker-password=[PASSWORD]

# 内容確認
kubectl get configmap [CONFIG_NAME] -o yaml
kubectl get secret [SECRET_NAME] -o yaml
kubectl describe configmap [CONFIG_NAME]
```

### リソース監視
```bash
# リソース使用量（metrics-server必要）
kubectl top nodes
kubectl top pods
kubectl top pods --containers

# リソース情報
kubectl describe node [NODE_NAME]
kubectl get pods -o custom-columns=NAME:.metadata.name,CPU:.spec.containers[0].resources.requests.cpu,MEMORY:.spec.containers[0].resources.requests.memory
```

### トラブルシューティング
```bash
# Podの状態詳細確認
kubectl describe pod [POD_NAME]
kubectl get pod [POD_NAME] -o yaml

# ネットワーク確認
kubectl get endpoints
kubectl get networkpolicies

# Podにアクセスして診断
kubectl exec -it [POD_NAME] -- nslookup [SERVICE_NAME]
kubectl exec -it [POD_NAME] -- wget -qO- http://[SERVICE_NAME]:[PORT]

# ヘルスチェック状況
kubectl get pods --show-labels
kubectl describe pod [POD_NAME] | grep -A 10 "Conditions:"
```

### ショートハンド
```bash
# よく使うエイリアス
po = pods
svc = services  
deploy = deployments
rs = replicasets
ns = namespaces
cm = configmaps
ing = ingress
pv = persistentvolumes
pvc = persistentvolumeclaims
sa = serviceaccounts

# 使用例
kubectl get po
kubectl get svc
kubectl get deploy
kubectl describe ing
```

### ネームスペース操作
```bash
# ネームスペース作成
kubectl create namespace [NAMESPACE_NAME]

# 現在のネームスペース確認
kubectl config view --minify -o jsonpath='{..namespace}'

# デフォルトネームスペース変更
kubectl config set-context --current --namespace=[NAMESPACE_NAME]

# 特定ネームスペースで実行
kubectl get pods -n [NAMESPACE_NAME]
kubectl apply -f manifest.yaml -n [NAMESPACE_NAME]
```

### 便利なTips
```bash
# JSON Path でカスタム出力
kubectl get pods -o jsonpath='{.items[*].metadata.name}'
kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}'

# 複数リソースを一度に確認
kubectl get pods,services,deployments

# ドライラン（実際には実行せず確認のみ）
kubectl apply -f manifest.yaml --dry-run=client -o yaml

# マニフェスト生成
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml
kubectl expose deployment nginx --port=80 --target-port=8000 --dry-run=client -o yaml

# 設定差分確認
kubectl diff -f manifest.yaml
```

### kind特有のコマンド
```bash
# クラスター管理
kind create cluster --name [CLUSTER_NAME]
kind delete cluster --name [CLUSTER_NAME]
kind get clusters

# イメージのロード
kind load docker-image [IMAGE_NAME] --name [CLUSTER_NAME]

# kindノードのシェルアクセス
docker exec -it [CLUSTER_NAME]-control-plane bash
```

## 学習後のクリーンアップ

### ローカル環境（kind）のクリーンアップ

**レベル1学習後の推奨クリーンアップ手順**

```bash
# 1. アプリケーションリソースの削除（課題完了後）
kubectl delete deployment --all
kubectl delete service --all --ignore-not-found
kubectl delete configmap --all --ignore-not-found
kubectl delete ingress --all --ignore-not-found

# 2. クラスター全体の削除（学習終了時）
kind delete cluster --name [CLUSTER_NAME]

# 例：マルチノードクラスターの削除
kind delete cluster --name multi-node-cluster

# 3. 削除確認
kind get clusters
docker ps --filter name=kind
```

**段階的クリーンアップ（課題ごと）**

```bash
# 課題1-2.5完了後
kubectl delete -f 04-web-application/test-apps.yaml
kubectl delete -f 04-web-application/simple-ingress-demo.yaml

# 課題1-2.6完了後  
kubectl delete -f 05-ingress-controller/ingress-demo.yaml
kubectl delete -f 05-ingress-controller/sample-app.yaml
kubectl delete -f 05-ingress-controller/nginx-ingress-controller.yaml

# またはHelmでインストールした場合
helm uninstall ingress-nginx -n ingress-nginx
kubectl delete namespace ingress-nginx
```

### AWS環境のクリーンアップ

**レベル2以降（AWS EKS）の学習後**

```bash
# EKSクラスターの削除
eksctl delete cluster --name my-first-cluster --region ap-northeast-1

# ECRリポジトリの削除
aws ecr delete-repository --repository-name my-node-app --region ap-northeast-1 --force

# CloudFormationスタックの確認・削除
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE
```

### 注意事項

- **kindクラスター**: ローカルリソースのみ使用、削除は安全
- **AWS EKS**: **課金が発生**するため、学習完了後は必ず削除
- **段階的削除**: 各課題完了後にアプリケーションリソースのみ削除し、クラスターは次の課題で再利用可能
- **完全削除**: 学習終了時にクラスター全体を削除

### クリーンアップ確認

```bash
# ローカル環境の確認
kind get clusters
kubectl config get-contexts
docker ps --filter name=kind

# AWS環境の確認
aws eks list-clusters --region ap-northeast-1
aws ecr describe-repositories --region ap-northeast-1
```

## 🔧 よくある質問とトラブルシューティング

### Q1: kind クラスター作成時のエラー
**Q**: `kind create cluster` でエラーが発生する
**A**: 以下を確認：
```bash
# Dockerが起動しているか確認
docker ps

# 既存のkindクラスターが残っていないか確認
kind get clusters
kind delete cluster --name [古いクラスター名]

# ポート競合の確認
lsof -i :80  # macOS/Linux
netstat -ano | findstr :80  # Windows
```

### Q2: kubectl コマンドが認識されない
**Q**: `kubectl: command not found`
**A**: kubectl のインストールと設定：
```bash
# macOS (Homebrew)
brew install kubectl

# Windows (Chocolatey)
choco install kubernetes-cli

# 設定確認
kubectl config current-context
kubectl config get-contexts
```

### Q3: AWS認証エラー
**Q**: EKS課題で認証エラーが発生
**A**: AWS認証の確認：
```bash
# 認証情報確認
aws sts get-caller-identity

# 必要な権限
# - EKS Full Access
# - EC2 Full Access  
# - IAM Limited Access
# - CloudFormation Access

# プロファイル設定
aws configure list
export AWS_PROFILE=your-profile
```

### Q4: イメージプルエラー
**Q**: `ImagePullBackOff` エラーが発生
**A**: 原因別の対処法：
```bash
# 1. イメージ名の確認
kubectl describe pod [POD_NAME]

# 2. kindでのローカルイメージ
kind load docker-image [IMAGE_NAME] --name [CLUSTER_NAME]

# 3. プライベートレジストリの認証
kubectl create secret docker-registry regcred \
  --docker-server=[REGISTRY_URL] \
  --docker-username=[USERNAME] \
  --docker-password=[PASSWORD]
```

### Q5: ネットワーク接続問題
**Q**: Pod間通信ができない
**A**: ネットワーク診断手順：
```bash
# DNS確認
kubectl exec -it [POD_NAME] -- nslookup kubernetes.default

# Service確認
kubectl get endpoints [SERVICE_NAME]

# Pod IPの確認
kubectl get pods -o wide

# ファイアウォール確認（企業ネットワーク）
telnet [SERVICE_IP] [PORT]
```

## 📚 参考資料とさらなる学習

### 公式ドキュメント
- [Kubernetes公式ドキュメント](https://kubernetes.io/docs/)
- [AWS EKS ユーザーガイド](https://docs.aws.amazon.com/eks/)
- [Docker公式ドキュメント](https://docs.docker.com/)

### 推奨書籍
- 「Kubernetes完全ガイド」青山真也著
- 「Kubernetes実践ガイド」磯賢大著  
- 「SRE サイトリライアビリティエンジニアリング」Google SREチーム著

### オンライン学習リソース
- [Kubernetes Academy](https://kube.academy/)
- [AWS Training and Certification](https://aws.amazon.com/training/)
- [CNCF Certification](https://www.cncf.io/certification/cka/)

### コミュニティ
- [Kubernetes Slack](https://slack.k8s.io/)
- [CNCF Events](https://events.cncf.io/)
- [AWS User Groups](https://aws.amazon.com/developer/community/usergroups/)

## 🏆 次のステップ

### 認定試験への挑戦
- **CKA (Certified Kubernetes Administrator)**: Kubernetes管理者認定
- **CKAD (Certified Kubernetes Application Developer)**: Kubernetes開発者認定
- **AWS Certified DevOps Engineer**: AWS DevOps実践認定

### 実践プロジェクト案
1. **個人ブログのKubernetes化**: 既存アプリケーションの移行体験
2. **マイクロサービスECサイト**: フルスタック開発でのKubernetes活用
3. **オープンソースプロジェクト貢献**: Kubernetes関連ツールの開発参加

---

**サポート情報**: 各課題で困ったことがあれば、具体的なエラーメッセージや状況と併せて以下の情報を収集してお問い合わせください：
- OS とバージョン
- Kubernetes バージョン (`kubectl version`)
- Docker バージョン (`docker version`)
- エラーが発生した具体的な手順