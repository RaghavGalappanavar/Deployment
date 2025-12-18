{{/*
Expand the name of the chart.
*/}}
{{- define "mb-otr.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "mb-otr.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "mb-otr.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mb-otr.labels" -}}
helm.sh/chart: {{ include "mb-otr.chart" . }}
{{ include "mb-otr.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mb-otr.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mb-otr.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "mb-otr.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "mb-otr.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Common labels for services
*/}}
{{- define "mb-otr.serviceLabels" -}}
{{- $serviceName := .serviceName -}}
helm.sh/chart: {{ include "mb-otr.chart" .root }}
app.kubernetes.io/name: {{ include "mb-otr.name" .root }}-{{ $serviceName }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ $serviceName }}
{{- if .root.Chart.AppVersion }}
app.kubernetes.io/version: {{ .root.Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .root.Release.Service }}
{{- end }}

{{/*
Selector labels for services
*/}}
{{- define "mb-otr.serviceSelectorLabels" -}}
{{- $serviceName := .serviceName -}}
app.kubernetes.io/name: {{ include "mb-otr.name" .root }}-{{ $serviceName }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
{{- end }}

{{/*
Image pull secrets
*/}}
{{- define "mb-otr.imagePullSecrets" -}}
{{- if .Values.global.imagePullSecrets }}
imagePullSecrets:
{{- range .Values.global.imagePullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Database URL helper
*/}}
{{- define "mb-otr.databaseUrl" -}}
{{- if .Values.postgresql.enabled }}
jdbc:postgresql://{{ .Release.Name }}-postgresql:5432/{{ .Values.postgresql.auth.database }}
{{- else }}
{{ .Values.externalDatabase.url }}
{{- end }}
{{- end }}

{{/*
Kafka bootstrap servers helper
*/}}
{{- define "mb-otr.kafkaBootstrapServers" -}}
{{- if .Values.kafka.enabled }}
{{ .Release.Name }}-kafka:9092
{{- else }}
{{ .Values.externalKafka.bootstrapServers }}
{{- end }}
{{- end }}
