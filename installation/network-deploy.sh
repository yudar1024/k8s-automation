#!/bin/bash
yum install wget -y
wget -c -t 0 https://docs.projectcalico.org/v3.9/manifests/calico.yaml
# 删除 CALICO_IPV4POOL_CIDR的下一行
sed -i '/CALICO_IPV4POOL_CIDR/{n;d}' calico.yaml
# 需与kubeadm-init.yaml 中的 podsubnet 一致
sed -i '/CALICO_IPV4POOL_CIDR/a\              value: "10.244.0.0/16"' calico.yaml
kubectl apply -f calico.yaml