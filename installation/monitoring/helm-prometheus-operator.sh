#!/bin/bash
#此方式与 kube-prometheus 方式二选一
#文档 https://github.com/helm/charts/tree/master/stable/prometheus-operator
mkdir -p helm-prometheus-operator/crd
cd helm-prometheus-operator
alertManagerFile="crd/alertmanager.crd.yaml"
prometheusFile="crd/prometheus.crd.yaml"
prometheusruleFile="crd/prometheusrule.crd.yaml"
serviceMonitorFile="crd/servicemonitor.crd.yaml"
podMonitorFile="crd/podmonitor.crd.yaml"

if [[ ! -f "$alertManagerFile" ]] 
then
  wget -O crd/alertmanager.crd.yaml https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/alertmanager.crd.yaml 
else
  echo "test exist"
  echo "${alertManagerFile} already exsit"
fi

if [[ ! -f "$prometheusFile" ]] 
then
  wget -O crd/prometheus.crd.yaml https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/prometheus.crd.yaml
else
  echo "$prometheusFile already exsit"
fi

if [[ ! -f "$prometheusruleFile" ]] 
then
  wget -O crd/prometheusrule.crd.yaml https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/prometheusrule.crd.yaml
else
  echo "$prometheusruleFile already exsit"
fi

if [[ ! -f "$serviceMonitorFile" ]] 
then
  wget -O crd/servicemonitor.crd.yaml https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/servicemonitor.crd.yaml
else
  echo "$serviceMonitorFile already exsit"
fi

if [[ ! -f "$podMonitorFile" ]] 
then
wget -O crd/podmonitor.crd.yaml https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/podmonitor.crd.yaml
else 
echo "$podMonitorFile already exsit"
fi

kubectl apply -f crd/alertmanager.crd.yaml
kubectl apply -f crd/prometheus.crd.yaml
kubectl apply -f crd/prometheusrule.crd.yaml
kubectl apply -f crd/servicemonitor.crd.yaml
kubectl apply -f crd/podmonitor.crd.yaml

git clone https://github.com/helm/charts.git
cd charts
helm install --name my-po stable/prometheus-operator --set prometheusOperator.createCustomResource=false \
  --set prometheusOperator.image.repository=quay.azk8s.cn/coreos/prometheus-operator \
  --set prometheusOperator.configmapReloadImage.repository=quay.azk8s.cn/coreos/configmap-reload \
  --set prometheusOperator.prometheusConfigReloaderImage.repository=quay.azk8s.cn/coreos/prometheus-config-reloader \
  --set prometheus.prometheusSpec.image.repository=quay.azk8s.cn/prometheus/prometheus \
  --set alertmanager.alertmanagerSpec.image.repository=quay.azk8s.cn/prometheus/alertmanager \
  --set prometheusOperator.hyperkubeImage.repository=gcr.azk8s.cn/google-containers/hyperkube

