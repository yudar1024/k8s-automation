#!/bin/bash
kubectl create ns prometheus
kubectl apply -f rbac.yaml
kubectl apply -f prometheus-cm.yaml
kubectl apply -f prometheus-deploy.yaml
wget https://raw.githubusercontent.com/kubernetes/kube-state-metrics/v1.7.2/kubernetes/kube-state-metrics-service-account.yaml
wget https://raw.githubusercontent.com/kubernetes/kube-state-metrics/v1.7.2/kubernetes/kube-state-metrics-cluster-role.yaml
wget https://raw.githubusercontent.com/kubernetes/kube-state-metrics/v1.7.2/kubernetes/kube-state-metrics-cluster-role-binding.yaml
wget https://raw.githubusercontent.com/kubernetes/kube-state-metrics/v1.7.2/kubernetes/kube-state-metrics-deployment.yaml
wget https://raw.githubusercontent.com/kubernetes/kube-state-metrics/v1.7.2/kubernetes/kube-state-metrics-service.yaml
sed -i 's/kube-system/prometheus/g' kube-state-metrics-service-account.yaml
sed -i 's/kube-system/prometheus/g' kube-state-metrics-cluster-role.yaml
sed -i 's/kube-system/prometheus/g' kube-state-metrics-cluster-role-binding.yaml
sed -i 's/kube-system/prometheus/g' kube-state-metrics-deployment.yaml
sed -i 's/kube-system/prometheus/g' kube-state-metrics-service.yaml