{{- define "multi-site-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "multi-site-app.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name .Values.site | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "multi-site-app.labels" -}}
app.kubernetes.io/name: {{ include "multi-site-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: {{ .Values.site }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end -}}

{{- define "multi-site-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "multi-site-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: {{ .Values.site }}
{{- end -}}

{{- define "multi-site-app.host" -}}
{{- printf "%s.%s" .Values.site .Values.baseDomain -}}
{{- end -}}

{{- define "multi-site-app.validateSite" -}}
{{- $allowed := list "web" "api" "app" -}}
{{- if not (has .Values.site $allowed) -}}
{{- fail "Values.site must be one of: web, api, app" -}}
{{- end -}}
{{- end -}}