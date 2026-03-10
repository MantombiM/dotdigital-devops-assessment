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

{{- define "multi-site-app.validateSite" -}}
{{- $allowed := list "web" "api" "app" -}}
{{- if not (has .Values.site $allowed) -}}
{{- fail "Values.site must be one of: web, api, app" -}}
{{- end -}}
{{- end -}}

{{- define "multi-site-app.validateRegion" -}}
{{- $allowed := list "region1" "region2" "region3" -}}
{{- if not (has .Values.region $allowed) -}}
{{- fail "Values.region must be one of: region1, region2, region3" -}}
{{- end -}}
{{- end -}}

{{- define "multi-site-app.validateEnvironment" -}}
{{- $allowed := list "dev" "stg" "prd" -}}
{{- if not (has .Values.environment $allowed) -}}
{{- fail "Values.environment must be one of: dev, stg, prd" -}}
{{- end -}}
{{- end -}}

{{- define "multi-site-app.hosts" -}}
{{- $site := .Values.site -}}
{{- $region := .Values.region -}}
{{- $environment := .Values.environment -}}
{{- $baseDomain := .Values.baseDomain -}}
{{- if eq $environment "prd" -}}
  {{- if eq $region "region1" -}}
- {{ printf "%s.%s" $site $baseDomain }}
- {{ printf "%s-%s.%s" $region $site $baseDomain }}
  {{- else -}}
- {{ printf "%s-%s.%s" $region $site $baseDomain }}
  {{- end -}}
{{- else -}}
- {{ printf "%s-%s-%s.%s" $region $site $environment $baseDomain }}
{{- end -}}
{{- end -}}