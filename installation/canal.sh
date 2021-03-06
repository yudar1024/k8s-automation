#!/bin/bash
curl https://docs.projectcalico.org/manifests/canal.yaml -O
# 删除 CALICO_IPV4POOL_CIDR的下一行
# sed -i '/CALICO_IPV4POOL_CIDR/{n;d}' calico.yaml
# 需与kubeadm-init.yaml 中的 podsubnet 一致
# sed -i '/CALICO_IPV4POOL_CIDR/a\              value: "10.244.0.0/16"' calico.yaml
sed -i 's/            # - name: CALICO_IPV4POOL_CIDR/            - name: CALICO_IPV4POOL_CIDR/' canal.yaml
sed -i 's/            #   value: "192.168.0.0\/16"/              value: "10.244.0.0\/16"/' canal.yaml
# sed -i 's/quay.io/quay.azk8s.cn/g' canal.yaml

kubectl apply -f canal.yaml