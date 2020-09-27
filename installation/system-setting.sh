#!/bin/bash 
# 本脚本假设使用者已经装好了与K8S 相对应的docker
# 在所有 master 节点与 node 节点执行
# 此脚本需要与 nginx.conf kubernetes.repo nginx-proxy.service 三个文件在同一目录。
# 脚本传输到linux 后，可能有crlf 问题，报错找不到文件或文件夹。 需要使用 sed -i 's/\r$//' system-setting.sh 处理一下换行符问题


if [ `whoami` != 'root' ]
then
    echo 'you must run this script as root'
    exit 0
fi

read -p "use lvscare or nginx as lb? 1 lvscare ,2 nginx:" lb
read -p "which type of this node is, 1 master, 2 node ? please input 1 or 2 " nodetype
if  [ "$lb" -eq 2 ] && [ ! -f "./nginx.conf" ]; then
echo "missing nginx.conf file, exit"
exit 1
fi

if [ "$lb" -eq 2 ] && [ ! -f "./nginx-proxy.service" ]; then
echo "missing nginx-proxy.service file, exit"
exit 1
fi


if [ ! -f "./kubernetes.repo" ]; then
echo "missing kubernetes.repo file, exit"
exit 1
fi

# 预处理 crlf
sed -i 's/\r$//' nginx.conf
sed -i 's/\r$//' nginx-proxy.service
sed -i 's/\r$//' kubernetes.repo

# install vim, this is optional
yum install -y vim ipvsadm ipset tc bash-completion


# close firewall
systemctl stop firewalld
systemctl disable firewalld

# 临时关闭 swap
swapoff -a
# 永久关闭  在/etc//fstab 中注释掉 "/dev/mapper/centos-swap swap"
sed -i 's/.*swap.*/#&/' /etc/fstab


# 关闭selinux
setenforce 0
# 永久关闭
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/sysconfig/selinux
sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/selinux/config
grubby --args="user_namespace.enable=1" --update-kernel="$(grubby --default-kernel)"
# 修改内核参数, 默认内核配置参数在/etc/sysctl.conf
touch /etc/sysctl.d/docker.conf
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.d/docker.conf
echo "net.bridge.bridge-nf-call-iptables=1" >> /etc/sysctl.d/docker.conf
echo "net.bridge.bridge-nf-call-ip6tables=1" >> /etc/sysctl.d/docker.conf
echo "net.bridge.bridge-nf-call-arptables = 1" >> /etc/sysctl.d/docker.conf
echo "vm.swappiness=0" >> /etc/sysctl.d/docker.conf
cat<<EOF > /etc/sysctl.d/kubernetes.conf
# conntrack 连接跟踪数最大数量，是在内核内存中 netfilter 可以同时处理的“任务”（连接跟踪条目）
net.netfilter.nf_conntrack_max = 10485760
net.netfilter.nf_conntrack_tcp_timeout_established=300
# 每个网络接口接收数据包的速率比内核处理这些包的速率快时，允许送到队列的数据包的最大数目
net.core.netdev_max_backlog = 10000

# 存在于 ARP 高速缓存中的最少层数，如果少于这个数，垃圾收集器将不会运行。缺省值是 128
net.ipv4.neigh.default.gc_thresh1 = 80000
# 保存在 ARP 高速缓存中的最多的记录软限制。垃圾收集器在开始收集前，允许记录数超过这个数字 5 秒。缺省值是 512
net.ipv4.neigh.default.gc_thresh2 = 90000
# 保存在 ARP 高速缓存中的最多记录的硬限制，一旦高速缓存中的数目高于此，垃圾收集器将马上运行。缺省值是 1024
net.ipv4.neigh.default.gc_thresh3 = 100000
#  哈希表大小（只读）（64位系统、8G内存默认 65536，16G翻倍，如此类推）
net.netfilter.nf_conntrack_buckets=655360
# 当数据包超长时，不丢弃数据包。K8S重要
net.netfilter.nf_conntrack_tcp_be_liberal=1
# 表示socket监听(listen)的backlog上限，也就是就是socket的监听队列(accept queue)，当一个tcp连接尚未被处理或建立时(半连接状态)，会保存在这个监听队列，默认为 128，在高并发场景下偏小，优化到 32768。参考 https://imroc.io/posts/kubernetes-overflow-and-drop/
net.core.somaxconn=32768
# 默认值: 128 指定了每一个 real user ID 可创建的 inotify instatnces 的数量上限
fs.inotify.max_user_instances=524288
# 表示同一用户同时可以添加的watch数目（watch一般是针对目录，决定了同时同一用户可以监控的目录数量) 默认值 8192 在容器场景下偏小，在某些情况下可能会导致 inotify watch 数量耗尽，使得创建 Pod 不成功或者 kubelet 无法启动成功，将其优化到 524288
fs.inotify.max_user_watches=524288
# 没有启用syncookies的情况下，syn queue(半连接队列)大小除了受somaxconn限制外，也受这个参数的限制，默认1024，优化到8096，避免在高并发场景下丢包
net.ipv4.tcp_max_syn_backlog=8096
# max-file 表示系统级别的能够打开的文件句柄的数量， 一般如果遇到文件句柄达到上限时，会碰到
# Too many open files 或者 Socket/File: Can’t open so many files 等错误
# fs.file-max=2097152
net.core.bpf_jit_enable=1
net.core.bpf_jit_harden=1
net.core.bpf_jit_kallsyms=1
net.core.dev_weight_tx_bias=1
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 12582912 16777216
net.ipv4.tcp_wmem=4096 12582912 16777216
net.core.rps_sock_flow_entries=8192
net.ipv4.tcp_max_orphans=32768
net.ipv4.tcp_max_tw_buckets=32768
vm.max_map_count=262144
kernel.threads-max=30058
# 避免发生故障时没有 coredump
kernel.core_pattern=core
#touch /etc/modprobe.d/nf_conntrack.conf
#echo "options nf_conntrack hashsize=655360" > /etc/modprobe.d/nf_conntrack.conf
EOF
# 生效
sysctl --system

# 调高 ulimit 最大文件打开数量，systemclt 管理服务文件的最大数量
touch /etc/security/limits.d/k8slimits.conf
echo "* soft nofile 655360" >> /etc/security/limits.d/k8slimits.conf
echo "* hard nofile 655360" >> /etc/security/limits.d/k8slimits.conf
echo "* soft nproc 655360" >> /etc/security/limits.d/k8slimits.conf
echo "* hard nproc 655360" >> /etc/security/limits.d/k8slimits.conf
echo "* soft memlock unlimited" >> /etc/security/limits.d/k8slimits.conf
echo "* hard memlock unlimited" >> /etc/security/limits.d/k8slimits.conf
echo "DefaultLimitNPROC=1024000" >> /etc/systemd/system.conf
echo "DefaultLimitNOFILE=1024000" >> /etc/systemd/system.conf
#此处是个坑， 如果此项没开，elasticsearch 没法集群部署，报bootstrap 错误 [1]: memory locking requested for elasticsearch process but memory is not locked
echo "DefaultLimitMEMLOCK=infinity" >> /etc/systemd/system.conf

# 加载ipvs 所需的内核模块
touch /etc/sysconfig/modules/ipvs.modules
echo '#!/bin/bash' >> /etc/sysconfig/modules/ipvs.modules
echo "modprobe -- ip_vs" >> /etc/sysconfig/modules/ipvs.modules
echo "modprobe -- ip_vs_rr" >> /etc/sysconfig/modules/ipvs.modules
echo "modprobe -- ip_vs_wrr" >> /etc/sysconfig/modules/ipvs.modules
echo "modprobe -- ip_vs_sh" >> /etc/sysconfig/modules/ipvs.modules
echo "modprobe -- nf_conntrack_ipv4" >> /etc/sysconfig/modules/ipvs.modules

# 授权
chmod 755 /etc/sysconfig/modules/ipvs.modules 

# 加载模块
bash /etc/sysconfig/modules/ipvs.modules

# 查看加载
lsmod | grep -e ip_vs -e nf_conntrack_ipv4

# 加载 glusterfs 所需的内核模块
touch /etc/sysconfig/modules/glusterfs.modules
echo '#!/bin/bash' >> /etc/sysconfig/modules/glusterfs.modules
echo "modprobe -- dm_snapshot" >> /etc/sysconfig/modules/glusterfs.modules
echo "modprobe -- dm_mirror" >> /etc/sysconfig/modules/glusterfs.modules
echo "modprobe -- dm_thin_pool" >> /etc/sysconfig/modules/glusterfs.modules
# 授权
chmod 755 /etc/sysconfig/modules/glusterfs.modules 

# 加载模块
bash /etc/sysconfig/modules/glusterfs.modules

lsmod | grep dm


# 重启加载内核模块
# touch /etc/modules-load.d/k8s.conf
# cat > /etc/modules-load.d/k8s.conf <<EOF
# # Load ip_vs at boot
# ip_vs
# ip_vs_rr
# ip_vs_wrr
# ip_vs_sh
# nf_conntrack_ipv4
# dm_snapshot
# dm_mirror
# dm_thin_pool
# dummy
# EOF

mkdir - /etc/docker

cat>/etc/docker/daemon.json<<EOF
{
  "bip": "172.17.0.1/16",
  "exec-opts": ["native.cgroupdriver=systemd"],
  "registry-mirrors": ["https://fmu2ap2k.mirror.aliyuncs.com","https://gcr-mirror.qiniu.com","https://quay-mirror.qiniu.com"],
  "data-root": "/opt/docker",
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "5"
  },
  "dns-search": ["default.svc.cluster.local", "svc.cluster.local", "localdomain"],
  "dns-opts": ["ndots:2", "timeout:2", "attempts:2"]
}
EOF

osversion=`rpm -q centos-release`
if [[ "$osversion" =~ ^centos-release-8 ]]; then
yum install -y https://download.docker.com/linux/fedora/30/x86_64/stable/Packages/containerd.io-1.2.13-3.2.fc30.x86_64.rpm
fi

# 添加阿里docker安装源
#osversion=`rpm -q centos-release|cut -d- -f3 |cut -d. -f1`
if [ ! -f "/usr/lib/systemd/system/docker.service" ]; then 
export VERSION=19.03
curl -fsSL "https://get.docker.com/" | bash -s -- --mirror Aliyun

# yum install -y yum-utils device-mapper-persistent-data lvm2
# yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

# yum makecache fast
# yum list docker-ce.x86_64 --showduplicates | sort -r
# yum install docker-ce -y
systemctl start docker
systemctl enable docker
fi

# 添加kubernetes 安装源为阿里源
mv kubernetes.repo /etc/yum.repos.d/
setenforce 0
yum install -y kubelet-1.19.2 kubeadm-1.19.2 kubectl-1.19.2
echo "source <(kubectl completion bash)" >> ~/.bashrc
source <(kubectl completion bash)
# 添加 api server loadbalance 配置
if [ "$lb" -eq 1 ];then
        echo "use lvscare as lb of master"
        if [ "$nodetype" -eq 2 ];then
          echo "10.103.97.2   apiserver.cluster.local" >> /etc/hosts  #只有node节点裁需要这个  using vip
        fi
        # docker pull fanux/lvscare:v1.0.1
        docker pull fanux/lvscare:latest
else
        echo "use nginx as lb of master"
        docker pull nginx:alpine
        mkdir -p /etc/nginx
        mv nginx.conf /etc/nginx
        chmod +r /etc/nginx/nginx.conf
        mv nginx-proxy.service /etc/systemd/system/
        systemctl daemon-reload
        systemctl start nginx-proxy
        systemctl enable nginx-proxy
        systemctl status nginx-proxy
fi

echo "you must restart your compute to make the change effect"