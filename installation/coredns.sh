#!/bin/bash
sed -i 's/CLUSTER_DOMAIN/cluster.local/' coredns.yaml
sed -i 's?REVERSE_CIDRS?10.254.0.0/18?' coredns.yaml # 设置pod的IP段
sed -i 's?UPSTREAMNAMESERVER?8.8.4.4?' coredns.yaml # 外部DNS地址
sed -i 's?CLUSTER_DNS_IP?10.254.0.2?' coredns.yaml # coredns 在集群内的地址


