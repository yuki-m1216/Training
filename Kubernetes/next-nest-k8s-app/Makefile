# Makefile for Next.js + Nest.js Kubernetes Application
# 使用方法: make [command]

.PHONY: help
help: ## ヘルプを表示
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

# ====================
# Docker Compose環境
# ====================

.PHONY: dc-build
dc-build: ## Docker Composeイメージをビルド
	docker-compose build

.PHONY: dc-up
dc-up: ## Docker Compose環境を起動（本番モード）
	docker-compose up -d

.PHONY: dc-up-dev
dc-up-dev: ## Docker Compose環境を起動（開発モード）
	docker-compose -f docker-compose.dev.yaml up -d

.PHONY: dc-down
dc-down: ## Docker Compose環境を停止
	docker-compose down

.PHONY: dc-logs
dc-logs: ## Docker Composeログを表示
	docker-compose logs -f

.PHONY: dc-clean
dc-clean: ## Docker Compose環境を完全削除（ボリューム含む）
	docker-compose down -v

# ====================
# Kubernetes環境
# ====================

.PHONY: k8s-cluster-create
k8s-cluster-create: ## kindクラスターを作成
	kind create cluster --config k8s/kind-config.yaml
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	@echo "Waiting for ingress controller..."
	kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s

.PHONY: k8s-cluster-delete
k8s-cluster-delete: ## kindクラスターを削除
	kind delete cluster

.PHONY: k8s-build
k8s-build: ## Kubernetesイメージをビルド
	docker build -t next-nest-k8s-app-backend:latest ./backend
	docker build -t next-nest-k8s-app-frontend:latest ./frontend --build-arg NEXT_PUBLIC_API_URL=/api

.PHONY: k8s-load
k8s-load: ## イメージをkindクラスターにロード
	kind load docker-image next-nest-k8s-app-backend:latest
	kind load docker-image next-nest-k8s-app-frontend:latest

.PHONY: k8s-deploy
k8s-deploy: ## Kubernetesマニフェストを適用
	kubectl apply -f k8s/postgres-config.yaml
	kubectl apply -f k8s/postgres.yaml
	@echo "Waiting for PostgreSQL..."
	kubectl wait --for=condition=ready pod -l app=postgres --timeout=60s
	kubectl apply -f k8s/backend.yaml
	kubectl apply -f k8s/frontend.yaml
	kubectl apply -f k8s/ingress.yaml

.PHONY: k8s-delete
k8s-delete: ## Kubernetesリソースを削除
	kubectl delete -f k8s/

.PHONY: k8s-status
k8s-status: ## Kubernetesリソースの状態を表示
	kubectl get pods
	kubectl get svc
	kubectl get ingress

.PHONY: k8s-logs-backend
k8s-logs-backend: ## バックエンドのログを表示
	kubectl logs -l app=backend -f

.PHONY: k8s-logs-frontend
k8s-logs-frontend: ## フロントエンドのログを表示
	kubectl logs -l app=frontend -f

# ====================
# 統合コマンド
# ====================

.PHONY: dc-all
dc-all: dc-build dc-up ## Docker Compose環境を完全セットアップ
	@echo "Docker Compose environment is ready!"
	@echo "Access the application at http://localhost/"

.PHONY: k8s-all
k8s-all: k8s-build k8s-load k8s-deploy ## Kubernetes環境を完全セットアップ
	@echo "Kubernetes environment is ready!"
	@echo "Access the application at http://localhost/"

.PHONY: test-dc
test-dc: ## Docker Compose環境でAPIをテスト
	@echo "Testing Docker Compose environment..."
	@curl -s http://localhost/api/users | jq . || echo "API test failed"

.PHONY: test-k8s
test-k8s: ## Kubernetes環境でAPIをテスト
	@echo "Testing Kubernetes environment..."
	@curl -s http://localhost/api/users | jq . || echo "API test failed"

.PHONY: clean-all
clean-all: dc-clean k8s-delete ## すべての環境をクリーンアップ
	docker system prune -f
	@echo "All environments cleaned!"

# ====================
# 開発用コマンド
# ====================

.PHONY: dev-backend
dev-backend: ## バックエンドを開発モードで起動
	cd backend && npm run start:dev

.PHONY: dev-frontend
dev-frontend: ## フロントエンドを開発モードで起動
	cd frontend && npm run dev

.PHONY: install
install: ## 依存関係をインストール
	cd backend && npm install
	cd frontend && npm install

.PHONY: lint
lint: ## コードをlint
	cd backend && npm run lint
	cd frontend && npm run lint

.PHONY: test
test: ## テストを実行
	cd backend && npm test
	cd frontend && npm test