#!/bin/bash
#此方式与 helm 方式二选一
git clone https://github.com/coreos/kube-prometheus.git
git checkout -b v0.1.0 v0.1.0
sed -i 's?k8s.gcr.io?gcr.azk8s.cn/google-containers?g' `grep k8s.gcr.io -rl kube-prometheus/manifests`
sed -i 's/quay.io/quay.azk8s.cn/g' `grep quay.io -rl kube-prometheus/manifests/`
mkdir -p kube-prometheus/manifests/crd
mkdir -p kube-prometheus/manifests/operator
ls kube-prometheus/manifests | grep CustomResourceDefinition | awk '{cmd="mv kube-prometheus/manifests/"$1" kube-prometheus/manifests/crd/";system(cmd)}'
mv kube-prometheus/manifests/*.yaml kube-prometheus/manifests/operator
kubectl apply -f kube-prometheus/manifests/crd
kubectl apply -f kube-prometheus/manifests/operator
