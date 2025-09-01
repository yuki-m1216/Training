{{/*
========================================
Helmテンプレートヘルパー関数
このファイルは、他のテンプレートで使い回す共通の値を定義します
{{ include "関数名" . }} で呼び出せます
========================================
*/}}

{{/*
アプリケーション名を返す関数
例: "next-nest-app"
*/}}
{{- define "next-nest-app.name" -}}
next-nest-app
{{- end }}

{{/*
リリース名を含むフルネームを返す関数
例: "my-release-next-nest-app"
*/}}
{{- define "next-nest-app.fullname" -}}
{{ .Release.Name }}-next-nest-app
{{- end }}

{{/*
全リソース共通のラベル
これらのラベルはKubernetesリソースの識別に使われます
*/}}
{{- define "next-nest-app.labels" -}}
app: {{ include "next-nest-app.name" . }}
release: {{ .Release.Name }}
chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}

{{/*
Podを選択するためのラベル（ServiceやDeploymentで使用）
*/}}
{{- define "next-nest-app.selectorLabels" -}}
app: {{ include "next-nest-app.name" . }}
release: {{ .Release.Name }}
{{- end }}

{{/*
バックエンド用のラベル
*/}}
{{- define "next-nest-app.backend.labels" -}}
{{ include "next-nest-app.labels" . }}
component: backend
{{- end }}

{{/*
バックエンドPodを選択するためのラベル
*/}}
{{- define "next-nest-app.backend.selectorLabels" -}}
{{ include "next-nest-app.selectorLabels" . }}
component: backend
{{- end }}

{{/*
フロントエンド用のラベル
*/}}
{{- define "next-nest-app.frontend.labels" -}}
{{ include "next-nest-app.labels" . }}
component: frontend
{{- end }}

{{/*
フロントエンドPodを選択するためのラベル
*/}}
{{- define "next-nest-app.frontend.selectorLabels" -}}
{{ include "next-nest-app.selectorLabels" . }}
component: frontend
{{- end }}

{{/*
PostgreSQLのサービス名
外部PostgreSQLを使う場合の切り替えもここで管理
*/}}
{{- define "next-nest-app.postgresql.servicename" -}}
{{- if .Values.postgresql.enabled }}
{{- .Release.Name }}-postgresql
{{- else }}
{{- .Values.postgresql.externalHost | default "postgres-service" }}
{{- end }}
{{- end }}