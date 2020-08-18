#!/bin/bash

if [ "$#" == 0 ]; then 
echo "please indecate master nodes ip. exmaple: bash master-deploy-1.18+.sh 192.168.106.128 192.168.106.129 192.168.106.130"
exit 1
fi

if [ ! -f "./audit-policy.yaml" ]; then
echo "missing audit-policy.yaml file, exit"
exit 1
fi
kubeadm config print init-defaults > kubeadm-init.yaml
ip=`ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | awk -F"/" '{print $1}'`
# ip=`ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1 -d '/'`
# kubeadm config print init-defaults --component-configs KubeletConfiguration
# kubeadm config print init-defaults --component-configs KubeProxyConfiguration
cat >> kubeadm-init.yaml <<EOF
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: ipvs
ipvs:
  excludeCIDRs: 
  - 10.103.97.2/32 # VIP
  minSyncPeriod: 5s
  syncPeriod: 5s
  # 加权轮询调度
  scheduler: "wrr"
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
clusterDNS:
# coredns 默认ip地址
- 10.96.0.10
# 如下为 NodeLocal DNSCache 默认主机地址
#- 169.254.20.10
clusterDomain: cluster.local
EOF
# echo '开始添加kube proxy 相关配置，启用ipvs'
# echo '---' >> kubeadm-init.yaml
# echo 'apiVersion: kubeproxy.config.k8s.io/v1alpha1' >> kubeadm-init.yaml
# echo 'kind: KubeProxyConfiguration' >> kubeadm-init.yaml
# echo 'mode: "ipvs"' >> kubeadm-init.yaml
# echo 'kube proxy 相关配置结束'
# echo '开始添加kubelet 相关配置'
# echo '---' >> kubeadm-init.yaml
# echo 'apiVersion: kubelet.config.k8s.io/v1beta1' >> kubeadm-init.yaml
# echo 'kind: KubeletConfiguration' >> kubeadm-init.yaml
# echo 'cgroupDriver: systemd' >> kubeadm-init.yaml
# echo '结束添加kubelet 相关配置'
read -p "use lvscare or nginx as lb? 1 lvscare ,2 nginx:" lb
echo '替换 kubeadm apiserver 地址'
#此处为apiserver 实际的IP地址
sed -i "s/advertiseAddress: 1.2.3.4/advertiseAddress: $ip/g" kubeadm-init.yaml
if ["$lb" -eq 2]; then
#此处为访问APIserver的请求地址 for nginx lb
  sed -i '/clusterName: kubernetes/a\controlPlaneEndpoint: "127.0.0.1:6443"' kubeadm-init.yaml
elif ["$lb" -eq 1];then 
#此处为访问APIserver的请求地址 for lvscare lb
  sed -i '/clusterName: kubernetes/a\controlPlaneEndpoint: "apiserver.cluster.local:6443"' kubeadm-init.yaml
  host=$(cat /etc/hosts | grep apiserver.cluster.local)
  if [ "$host" == "" ]; then 
    echo "$ip apiserver.cluster.local" >> /etc/hosts
  fi
fi
echo 'k8s version'
sed -i '/kubernetesVersion/d' kubeadm-init.yaml
versionkey="kubernetesVersion:"
# awk 与变量交互http://blog.jcix.top/2017-03-30/shell_awk_variables/
p1=`kubeadm version | awk '{print $5}' | awk -v awk_var1=$versionkey '{split($0,v,"\"");print awk_var1, v[2]}'`
sed -i "/kind: ClusterConfiguration/a$p1" kubeadm-init.yaml
echo $p1
echo "使用阿里镜像"
sed -i "s?k8s.gcr.io?registry.cn-hangzhou.aliyuncs.com/google_containers?" kubeadm-init.yaml
# 当sed的替换内容和被替换内容也包含/ \ 等字符时，可以使用? 代替原来sed 本身的/ 字符。https://www.cnblogs.com/linux-wangkun/p/5745584.html
sed -i 's?imageRepository: k8s.gcr.io?imageRepository: registry.cn-hangzhou.aliyuncs.com/google_containers?' kubeadm-init.yaml
 # 设置为10.244.0.0/16 是因为 canal 中 fannal 默认是这个网段， 可以查看 cannal.yaml 中的 net-conf.json 配置段
sed -i '/dnsDomain: cluster.local/a\  podSubnet: "10.244.0.0/16"' kubeadm-init.yaml
#apiserver的审计配置
echo "########################### 开始设置API SERVER 访问域名与审计"
cp audit-policy.yaml /etc/kubernetes/audit-policy.yaml
cat > apiserver.yml <<EOF
  # apiserver相关配置
  # 添加所有的MASTER 以及预留的MASTER IP
  certSANs:
  - 127.0.0.1
  - apiserver.cluster.local #lvscare 所用的域名
$(for arg in $*
  do
echo "  - $arg"
  done
  )
  - 10.103.97.2 # VIP
#  extraArgs:
#    # 审计日志相关配置
#    audit-log-maxage: "20"
#    audit-log-maxbackup: "10"
#    audit-log-maxsize: "100"
#    audit-log-path: "/var/log/kube-audit/audit.log"
#    audit-policy-file: "/etc/kubernetes/audit-policy.yaml"
#    audit-log-format: json
#  # 开启审计日志配置, 所以需要将宿主机上的审计配置
#  extraVolumes:
#  - name: "audit-config"
#    hostPath: "/etc/kubernetes/audit-policy.yaml"
#    mountPath: "/etc/kubernetes/audit-policy.yaml"
#    readOnly: true
#    pathType: "File"
#  - name: "audit-log"
#    hostPath: "/var/log/kube-audit"
#    mountPath: "/var/log/kube-audit"
#    pathType: "DirectoryOrCreate"
EOF
sed -i '/apiServer:/r apiserver.yml' kubeadm-init.yaml
rm -f audit.yml
echo "*************************** 设置API SERVER 访问域名与审计 完毕"
echo "########################### 开始设置证书时间"
#设置证书时间为100年
cat > cm.yml <<EOF
  extraArgs:
    experimental-cluster-signing-duration: 876000h
EOF
sed -i 's/{}//' kubeadm-init.yaml
sed -i '/controllerManager:/r cm.yml' kubeadm-init.yaml
rm -f cm.yml
echo "*************************** 设置证书时间完毕"

# sed -i 's?10.96.0.0/12?10.244.0.0/16?' kubeadm-init.yaml
cat kubeadm-init.yaml
read -p "do you want to install now ? 1 yes ,2 no:" run
if [ "$run" -eq 1 ]; then 
kubeadm init --config kubeadm-init.yaml --upload-certs
mkdir ~/.kube
cp /etc/kubernetes/admin.conf ~/.kube/config
source <(kubectl completion bash)
echo "source <(kubectl completion bash)"
else
echo 'you can run "kubeadm init --config kubeadm-init.yaml --upload-certs" later'
fi



