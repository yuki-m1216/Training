# Helm入門ガイド - next-nest-appチャートを通して学ぶ

## 目次
1. [Helmとは何か](#helmとは何か)
2. [必要なKubernetesの基礎知識](#必要なkubernetesの基礎知識)
3. [Helmチャートの構造](#helmチャートの構造)
4. [テンプレート言語の基礎](#テンプレート言語の基礎)
5. [実際のファイル解説](#実際のファイル解説)
6. [Helmコマンドの使い方](#helmコマンドの使い方)
7. [よくある質問と回答](#よくある質問と回答)

---

## Helmとは何か

### 概要
Helmは「Kubernetesのパッケージマネージャー」と呼ばれるツールです。

**例え話**: 
- Kubernetesマニフェスト = レシピの材料と手順を1つずつ書いたもの
- Helm = 料理キットのように、必要な材料（設定）と手順（テンプレート）をまとめたパッケージ

### なぜHelmが必要か

#### 1. 環境ごとの設定管理が簡単
```yaml
# 開発環境
helm install my-app ./chart --set environment=dev --set replicas=1

# 本番環境
helm install my-app ./chart --set environment=prod --set replicas=5
```

#### 2. 複雑なアプリケーションの管理
私たちのアプリケーションは以下の要素から構成されています：
- Frontend (Next.js)
- Backend (Nest.js)
- Database (PostgreSQL)
- Ingress設定
- Secret/ConfigMap

これらを個別のマニフェストで管理すると：
```bash
# Helmを使わない場合（全て手動）
kubectl apply -f postgres-secret.yaml
kubectl apply -f postgres-deployment.yaml
kubectl apply -f postgres-service.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f backend-service.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f frontend-service.yaml
kubectl apply -f ingress.yaml

# Helmを使う場合（1コマンド）
helm install my-app ./next-nest-app
```

---

## 必要なKubernetesの基礎知識

### 1. リソースの種類

#### Deployment
```yaml
apiVersion: apps/v1
kind: Deployment  # アプリケーションの実行単位
metadata:
  name: backend
spec:
  replicas: 2  # 2つのPodを起動
  template:
    spec:
      containers:
      - name: backend
        image: my-backend:latest
```

**役割**: アプリケーションを実行し、指定した数のPodを維持します。

#### Service
```yaml
apiVersion: v1
kind: Service  # ネットワークアクセスポイント
metadata:
  name: backend-service
spec:
  selector:
    app: backend  # このラベルを持つPodに接続
  ports:
  - port: 3001
```

**役割**: Podへの安定したアクセスポイントを提供します。

#### Ingress
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress  # 外部からのHTTPアクセス管理
metadata:
  name: app-ingress
spec:
  rules:
  - host: localhost
    http:
      paths:
      - path: /api
        backend:
          service:
            name: backend-service
```

**役割**: 外部からのHTTPリクエストを適切なServiceにルーティングします。

### 2. ラベルとセレクター

Kubernetesはラベルを使ってリソースを関連付けます：

```yaml
# Deployment
metadata:
  labels:
    app: backend
    version: v1

# Service
selector:
  app: backend  # app=backendのラベルを持つPodを選択
```

---

## Helmチャートの構造

### ディレクトリ構造
```
next-nest-app/
├── Chart.yaml          # チャートの基本情報
├── values.yaml         # デフォルト設定値
├── README.md          # ドキュメント
└── templates/         # Kubernetesマニフェストのテンプレート
    ├── _helpers.tpl   # 再利用可能なテンプレート部品
    ├── backend-deployment.yaml
    ├── backend-service.yaml
    ├── frontend-deployment.yaml
    ├── frontend-service.yaml
    ├── ingress.yaml
    └── NOTES.txt      # インストール後のメッセージ
```

### 各ファイルの役割

#### Chart.yaml
```yaml
apiVersion: v2
name: next-nest-app  # チャート名
version: 0.1.0       # チャートのバージョン
appVersion: "1.0.0"  # アプリケーションのバージョン
```
**役割**: Helmがチャートを識別するための情報

#### values.yaml
```yaml
backend:
  replicaCount: 2
  image:
    repository: next-nest-k8s-app-backend
    tag: latest
```
**役割**: 設定可能な値のデフォルト値を定義

---

## テンプレート言語の基礎

### 1. 値の参照 `{{ }}`

```yaml
# values.yamlの値を参照
replicas: {{ .Values.backend.replicaCount }}

# 実際の出力
replicas: 2
```

### 2. 条件分岐 `{{- if }}`

```yaml
{{- if .Values.backend.enabled }}
apiVersion: apps/v1
kind: Deployment
# ... Deploymentの定義
{{- end }}
```

**意味**: `backend.enabled`がtrueの場合のみ、Deploymentを作成

### 3. ヘルパー関数 `{{ include }}`

```yaml
# _helpers.tplで定義した関数を呼び出す
name: {{ include "next-nest-app.fullname" . }}-backend

# 実際の出力
name: my-app-next-nest-app-backend
```

### 4. 特殊記号の意味

- `{{-` : 前の空白を削除
- `-}}` : 後の空白を削除
- `|` : 複数行の文字列をそのまま出力
- `nindent` : 指定した数のスペースでインデント

```yaml
labels:
  {{- include "next-nest-app.labels" . | nindent 4 }}
# 4スペースでインデントして出力
```

---

## 実際のファイル解説

### 1. backend-deployment.yaml の詳細解説

```yaml
{{- if .Values.backend.enabled }}  # ← バックエンドが有効な場合のみ作成
apiVersion: apps/v1
kind: Deployment
metadata:
  # Helmリリース名 + チャート名 + "backend"
  name: {{ include "next-nest-app.fullname" . }}-backend
  labels:
    # _helpers.tplで定義したラベルを追加
    {{- include "next-nest-app.backend.labels" . | nindent 4 }}
spec:
  # values.yamlから値を取得
  replicas: {{ .Values.backend.replicaCount }}
  selector:
    matchLabels:
      {{- include "next-nest-app.backend.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "next-nest-app.backend.selectorLabels" . | nindent 8 }}
    spec:
      containers:
      - name: backend
        # イメージ名を動的に構築
        image: "{{ .Values.backend.image.repository }}:{{ .Values.backend.image.tag }}"
        imagePullPolicy: {{ .Values.backend.image.pullPolicy }}
        ports:
        - name: http
          containerPort: {{ .Values.backend.service.targetPort }}
        env:
        - name: NODE_ENV
          value: {{ .Values.backend.env.NODE_ENV | quote }}  # ← quote関数で文字列として扱う
        - name: DATABASE_URL
          # 複数の値を組み合わせてURLを生成
          value: "postgresql://{{ .Values.postgresql.auth.username }}:{{ .Values.postgresql.auth.password }}@{{ include "next-nest-app.postgresql.servicename" . }}:{{ .Values.postgresql.service.port }}/{{ .Values.postgresql.auth.database }}"
{{- end }}
```

#### ポイント解説

1. **条件付きレンダリング**
   ```yaml
   {{- if .Values.backend.enabled }}
   ```
   - values.yamlで`backend.enabled: false`にすると、このDeploymentは作成されません

2. **動的な名前生成**
   ```yaml
   name: {{ include "next-nest-app.fullname" . }}-backend
   ```
   - Helmリリース名が`my-app`の場合: `my-app-next-nest-app-backend`
   - 同じチャートを複数回インストールしても名前が衝突しません

3. **環境変数の構築**
   ```yaml
   value: "postgresql://{{ .Values.postgresql.auth.username }}:..."
   ```
   - 複数の設定値を組み合わせて接続文字列を生成
   - 環境ごとに異なるDBを使える

### 2. _helpers.tpl の詳細解説

```yaml
{{- define "next-nest-app.fullname" -}}
{{- if .Values.fullnameOverride }}
  {{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
  {{- printf "%s-%s" .Release.Name .Chart.Name }}
{{- end }}
{{- end }}
```

#### このヘルパー関数の動作：

1. `fullnameOverride`が設定されている場合
   - その値を使用（最大63文字）
   
2. 設定されていない場合
   - `リリース名-チャート名`の形式で生成
   - 例: `my-app-next-nest-app`

### 3. ingress.yaml - デュアルIngress構成

```yaml
# メインIngress（静的ファイル用）
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "next-nest-app.fullname" . }}-ingress
spec:
  rules:
    - host: localhost
      http:
        paths:
        - path: /api
          backend:
            service:
              name: {{ include "next-nest-app.fullname" . }}-backend
        - path: /
          backend:
            service:
              name: {{ include "next-nest-app.fullname" . }}-frontend
---
# API専用Ingress（パスリライト用）
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "next-nest-app.fullname" . }}-ingress-api
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2  # /api/users → /users
```

#### なぜ2つのIngressが必要か：
1. **静的ファイル問題**: rewrite-targetを使うと、Next.jsの静的ファイル（JS/CSS）のパスも書き換えられてしまう
2. **解決策**: APIと静的ファイルで別々のIngressを使用

---

## Helmコマンドの使い方

### 基本コマンド

#### 1. インストール
```bash
# 基本インストール
helm install my-app ./next-nest-app

# 値を上書きしてインストール
helm install my-app ./next-nest-app \
  --set backend.replicaCount=3 \
  --set postgresql.enabled=false
```

#### 2. 値の確認
```bash
# デフォルト値を表示
helm show values ./next-nest-app

# 実際に使用される値を確認（デバッグ用）
helm install my-app ./next-nest-app --dry-run --debug
```

#### 3. アップグレード
```bash
# 値を保持してアップグレード
helm upgrade my-app ./next-nest-app --reuse-values

# 特定の値だけ変更
helm upgrade my-app ./next-nest-app \
  --reuse-values \
  --set backend.replicaCount=5
```

#### 4. 状態確認
```bash
# インストール済みのリリース一覧
helm list

# リリースの詳細
helm status my-app

# 生成されたマニフェストを確認
helm get manifest my-app
```

#### 5. アンインストール
```bash
helm uninstall my-app
```

### values.yamlの上書き方法

#### 方法1: --setフラグ
```bash
helm install my-app ./next-nest-app \
  --set backend.image.tag=v2.0.0 \
  --set backend.replicaCount=5
```

#### 方法2: カスタムvaluesファイル
```yaml
# custom-values.yaml
backend:
  replicaCount: 5
  image:
    tag: v2.0.0
```

```bash
helm install my-app ./next-nest-app -f custom-values.yaml
```

#### 方法3: 複数のvaluesファイル
```bash
helm install my-app ./next-nest-app \
  -f values.yaml \
  -f values-prod.yaml \
  --set backend.image.tag=v2.0.1
```
**優先順位**: 後に指定したものが優先（--setが最優先）

---

## よくある質問と回答

### Q1: なぜ `{{-` と `-}}` を使うのか？

**A**: 不要な空白や改行を削除するためです。

```yaml
# {{- を使わない場合
labels:

    app: backend  # ← 余分な空行が入る

# {{- を使う場合
labels:
  app: backend    # ← きれいな出力
```

### Q2: `.Values` と `.Release` の違いは？

**A**: 
- `.Values`: values.yamlの値
- `.Release`: Helmリリースの情報（名前、namespace等）

```yaml
name: {{ .Release.Name }}        # helm installで指定した名前
namespace: {{ .Release.Namespace }} # インストール先のnamespace
env: {{ .Values.environment }}   # values.yamlの値
```

### Q3: `include` と `template` の違いは？

**A**: 
- `include`: 結果を文字列として返す（パイプで加工可能）
- `template`: その場に直接出力（パイプ不可）

```yaml
# includeは加工できる
labels:
  {{- include "app.labels" . | nindent 2 }}

# templateは加工できない（エラーになる）
labels:
  {{- template "app.labels" . | nindent 2 }}  # ← エラー！
```

### Q4: エラー「nil pointer evaluating interface」が出る

**A**: values.yamlに定義されていない値を参照しています。

```yaml
# values.yamlに backend.newField がない場合
{{ .Values.backend.newField }}  # ← エラー

# 安全な書き方
{{ .Values.backend.newField | default "default-value" }}
```

### Q5: 生成されるマニフェストを事前確認したい

**A**: `--dry-run`を使います。

```bash
# 実際にはインストールせず、生成されるマニフェストを表示
helm install my-app ./next-nest-app --dry-run --debug > generated.yaml
```

---

## 実践的なTips

### 1. デバッグ方法

```bash
# テンプレートのレンダリング結果を確認
helm template ./next-nest-app > rendered.yaml

# 値の評価を確認
helm install my-app ./next-nest-app --dry-run --debug 2>&1 | less
```

### 2. 条件付きリソース作成

```yaml
# PostgreSQLが有効な場合のみSecretを作成
{{- if .Values.postgresql.enabled }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "next-nest-app.fullname" . }}-postgresql
{{- end }}
```

### 3. ループ処理

```yaml
# 複数の環境変数を一括設定
env:
{{- range $key, $value := .Values.backend.env }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end }}
```

### 4. デフォルト値の設定

```yaml
# 値が未定義の場合のデフォルト値
replicas: {{ .Values.replicas | default 1 }}
```

---

## まとめ

Helmを使うことで：

1. **環境差分の管理が簡単に**: 開発/ステージング/本番で異なる設定を1つのチャートで管理
2. **再利用性の向上**: 同じチャートを異なる設定で複数デプロイ可能
3. **バージョン管理**: アプリケーションのデプロイをバージョン管理
4. **ロールバック**: 問題があれば簡単に前のバージョンに戻せる

```bash
# ロールバック例
helm rollback my-app 1  # リビジョン1に戻す
```

初学者の方は、まず以下の順序で学習することをお勧めします：

1. 基本的なKubernetesリソース（Deployment, Service, Ingress）を理解
2. Helmの基本コマンド（install, upgrade, uninstall）を使ってみる
3. values.yamlの値を変更して動作を確認
4. 簡単なテンプレート（`{{ .Values.xxx }}`）から始める
5. 徐々に複雑な機能（条件分岐、ループ、ヘルパー関数）を学ぶ

このドキュメントを参考に、実際にHelmチャートを触りながら学習を進めてください！