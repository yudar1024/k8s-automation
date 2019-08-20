#!/bin/bash
wget https://docs.projectcalico.org/v3.8/manifests/calico.yaml
# 删除 CALICO_IPV4POOL_CIDR的下一行
sed -i '/CALICO_IPV4POOL_CIDR/{n;d}' calico.yaml
# 需与kubeadm-init.yaml 中的 podsubnet 一致
sed -i '/CALICO_IPV4POOL_CIDR/a\              value: "10.254.64.0/18"' calico.yaml
kubectl apply -f calico.yaml