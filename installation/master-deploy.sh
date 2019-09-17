#!/bin/bash
kubeadm config print init-defaults > kubeadm-init.yaml
echo '开始添加kube proxy 相关配置，启用ipvs'
echo '---' >> kubeadm-init.yaml
echo 'apiVersion: kubeproxy.config.k8s.io/v1alpha1' >> kubeadm-init.yaml
echo 'kind: KubeProxyConfiguration' >> kubeadm-init.yaml
echo 'mode: "ipvs"' >> kubeadm-init.yaml
echo 'kube proxy 相关配置结束'
echo '开始添加kubelet 相关配置'
echo '---' >> kubeadm-init.yaml
echo 'apiVersion: kubelet.config.k8s.io/v1beta1' >> kubeadm-init.yaml
echo 'kind: KubeletConfiguration' >> kubeadm-init.yaml
echo 'cgroupDriver: systemd' >> kubeadm-init.yaml
echo '结束添加kubelet 相关配置'
echo '替换 kubeadm apiserver 地址'
sed -i 's/advertiseAddress: 1.2.3.4/advertiseAddress: 127.0.0.1/g' kubeadm-init.yaml
sed -i '/clusterName: kubernetes/a\controlPlaneEndpoint: "127.0.0.1:9443"' kubeadm-init.yaml
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
# sed -i 's?10.96.0.0/12?10.244.0.0/16?' kubeadm-init.yaml
cat kubeadm-init.yaml
kubeadm init --config kubeadm-init.yaml
mkdir ~/.kube
cp /etc/kubernetes/admin.conf ~/.kube/config




