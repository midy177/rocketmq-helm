{{/*
Expand the name of the chart.
*/}}
{{- define "rocketmq.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 35 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "rocketmq.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 35 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 35 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 35 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "rocketmq.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 35 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "rocketmq.labels" -}}
helm.sh/chart: {{ include "rocketmq.chart" . }}
{{ include "rocketmq.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "rocketmq.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rocketmq.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "rocketmq.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "rocketmq.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
configmap
*/}}
{{- define "rocketmq.configmap.fullname" -}}
{{ include "rocketmq.fullname" . }}-server-config
{{- end }}

{{/*
acl configmap
*/}}
{{- define "rocketmq.acl.configmap.fullname" -}}
{{ include "rocketmq.fullname" . }}-acl-cm
{{- end }}

{{/*
broker-cm
*/}}
{{- define "rocketmq.broker.configmap.fullname" -}}
{{ include "rocketmq.fullname" . }}-broker-cm
{{- end }}

{{- define "rocketmq.broker.fullname" -}}
{{ include "rocketmq.fullname" . }}-broker
{{- end }}
{{/*
nameserver
*/}}
{{- define "rocketmq.nameserver.fullname" -}}
{{ include "rocketmq.fullname" . }}-nameserver
{{- end }}

{{/*
proxy
*/}}
{{- define "rocketmq.proxy.fullname" -}}
{{ include "rocketmq.fullname" . }}-proxy
{{- end }}

{{/*
dashboard
*/}}
{{- define "rocketmq.dashboard.fullname" -}}
{{ include "rocketmq.fullname" . }}-dashboard
{{- end }}

{{/*
dashboard-cm
*/}}
{{- define "rocketmq.dashboard.configmap.fullname" -}}
{{ include "rocketmq.dashboard.fullname" . }}-cm
{{- end }}

{{/*
dashboard
*/}}
{{- define "rocketmq.dashboard.dataPath" -}}
/tmp/rocketmq-console/data
{{- end }}

{{/*
env NAMESRV_ADDR
*/}}
{{- define "rocketmq.nameserver.addr" -}}
{{- $nsFullName := include "rocketmq.nameserver.fullname" . -}}
{{- $headlessDomain := printf "%s-headless.%s.svc" $nsFullName .Release.Namespace -}}
{{- $address := list -}}
{{- $replicaCount := int .Values.nameserver.replicaCount -}}
  {{- range $i := until $replicaCount -}}
  {{- $address = printf "%s-%d.%s:9876" $nsFullName $i $headlessDomain | append $address -}}
  {{- end -}}
{{- join ";" $address -}}
{{- end -}}


{{/*
controller
*/}}
{{- define "rocketmq.controller.fullname" -}}
{{ include "rocketmq.fullname" . }}-controller
{{- end -}}

{{/*
controller
*/}}
{{- define "rocketmq.enableControllerInNamesrv" -}}
{{- if and .Values.controllerModeEnabled (not .Values.controller.enabled) -}}
{{- print "true" -}}
{{- else -}}
{{- print "false" -}}
{{- end -}}
{{- end -}}

{{/*
rocketmq.broker.controllerAddr
*/}}
{{- define "rocketmq.broker.controllerAddr" -}}
{{- $address := list -}}
  {{- $fullName := include "rocketmq.controller.fullname" . -}}
  {{- $headlessDomain := printf "%s.%s.svc" $fullName .Release.Namespace -}}
  {{- $replicaCount := int .Values.controller.replicaCount -}}
{{- if eq (include "rocketmq.enableControllerInNamesrv" .) "true" -}}
  {{- $fullName = include "rocketmq.nameserver.fullname" . -}}
  {{- $headlessDomain = printf "%s-headless.%s.svc" $fullName .Release.Namespace -}}
  {{- $replicaCount = int .Values.nameserver.replicaCount -}}
{{- end -}}
  {{- range $i := until $replicaCount -}}
  {{- $address = printf "%s-%d.%s:9878" $fullName $i $headlessDomain | append $address -}}
  {{- end -}}
{{- join ";" $address -}}
{{- end -}}

{{/*
rocketmq.controller.dlegerPeers
*/}}
{{- define "rocketmq.controller.dlegerPeers" -}}
{{- $address := list -}}
  {{- $fullName := include "rocketmq.controller.fullname" . -}}
  {{- $headlessDomain := printf "%s.%s.svc" $fullName .Release.Namespace -}}
  {{- $replicaCount := int .Values.controller.replicaCount -}}
{{- if eq (include "rocketmq.enableControllerInNamesrv" .) "true" -}}
  {{- $fullName = include "rocketmq.nameserver.fullname" . -}}
  {{- $headlessDomain = printf "%s-headless.%s.svc" $fullName .Release.Namespace -}}
  {{- $replicaCount = int .Values.nameserver.replicaCount -}}
{{- end -}}
  {{- range $i := until $replicaCount -}}
  {{- $address = printf "n%d-%s-%d.%s:9878" $i $fullName $i $headlessDomain | append $address -}}
  {{- end -}}
{{- join ";" $address -}}
{{- end -}}

{{/*
rocketmq.noticeValues.controllerMode
*/}}
{{- define "rocketmq.noticeValues.controllerMode" -}}
{{ if .Values.controllerModeEnabled }}
Notice about controller mode:
    Controller mode is an experimental feature, you can disable it (--set conrtollerModeEnabled=false)
    If you decide to enable controller mode, you need to note:
  {{- $brokerReplicaCount := .Values.broker.size.replica | int }}
  {{- if lt $brokerReplicaCount 2 }}
        The minimum number of replica is 1, and the recommended number of replica is 2
        Please set a valid number of replica (--set broker.size.replica=2)
  {{- end }}
  {{- if eq (include "rocketmq.enableControllerInNamesrv" .) "true" }}
        Controller roles require persistent storage (--set nameserver.persistence.enabled=true)
  {{- else }}
        Controller roles require persistent storage (--set controller.persistence.enabled=true)
  {{- end }}
{{- end }}
{{- end }}