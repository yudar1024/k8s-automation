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

if [ ! -f "./nginx.conf" ] && [$lb -eq 2]; then
echo "missing nginx.conf file, exit"
exit 1
fi

if [ ! -f "./nginx-proxy.service" ] && [$lb -eq 2]; then
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
yum install -y vim
yum install ipvsadm -y
yum install bash-completion bash-completion-extras

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

# 修改内核参数, 默认内核配置参数在/etc/sysctl.conf
touch /etc/sysctl.d/docker.conf
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.d/docker.conf
echo "net.bridge.bridge-nf-call-iptables=1" >> /etc/sysctl.d/docker.conf
echo "net.bridge.bridge-nf-call-ip6tables=1" >> /etc/sysctl.d/docker.conf
echo "net.bridge.bridge-nf-call-arptables = 1" >> /etc/sysctl.d/docker.conf
echo "vm.swappiness=0" >> /etc/sysctl.d/docker.conf
touch /etc/sysctl.d/k8s.conf
echo "# conntrack 连接跟踪数最大数量，是在内核内存中 netfilter 可以同时处理的“任务”（连接跟踪条目）" >> /etc/sysctl.d/k8s.conf
echo "net.netfilter.nf_conntrack_max = 10485760" >> /etc/sysctl.d/k8s.conf
echo "net.netfilter.nf_conntrack_tcp_timeout_established=300" >> /etc/sysctl.d/k8s.conf
#echo "net.nf_conntrack_max=1048576" >> /etc/sysctl.d/k8s.conf
echo "# 每个网络接口接收数据包的速率比内核处理这些包的速率快时，允许送到队列的数据包的最大数目" >> /etc/sysctl.d/k8s.conf
echo "net.core.netdev_max_backlog = 10000" >> /etc/sysctl.d/k8s.conf
echo "# 存在于 ARP 高速缓存中的最少层数，如果少于这个数，垃圾收集器将不会运行。缺省值是 128" >> /etc/sysctl.d/k8s.conf
echo "net.ipv4.neigh.default.gc_thresh1 = 80000" >> /etc/sysctl.d/k8s.conf
echo "# 保存在 ARP 高速缓存中的最多的记录软限制。垃圾收集器在开始收集前，允许记录数超过这个数字 5 秒。缺省值是 512" >> /etc/sysctl.d/k8s.conf
echo "net.ipv4.neigh.default.gc_thresh2 = 90000" >> /etc/sysctl.d/k8s.conf
echo "# 保存在 ARP 高速缓存中的最多记录的硬限制，一旦高速缓存中的数目高于此，垃圾收集器将马上运行。缺省值是 1024" >> /etc/sysctl.d/k8s.conf
echo "net.ipv4.neigh.default.gc_thresh3 = 100000" >> /etc/sysctl.d/k8s.conf
echo "#  哈希表大小（只读）（64位系统、8G内存默认 65536，16G翻倍，如此类推）" >> /etc/sysctl.d/k8s.conf
echo "net.netfilter.nf_conntrack_buckets=655360" >> /etc/sysctl.d/k8s.conf
# max-file 表示系统级别的能够打开的文件句柄的数量， 一般如果遇到文件句柄达到上限时，会碰到
# "Too many open files" 或者 Socket/File: Can’t open so many files 等错误
# echo "fs.file-max=1000000" >> /etc/sysctl.d/k8s.conf
# 当数据包超长时，不丢弃数据包。K8S重要
echo "net.netfilter.nf_conntrack_tcp_be_liberal=1" >> /etc/sysctl.d/k8s.conf
# 表示socket监听(listen)的backlog上限，也就是就是socket的监听队列(accept queue)，当一个tcp连接尚未被处理或建立时(半连接状态)，会保存在这个监听队列，默认为 128，在高并发场景下偏小，优化到 32768。参考 https://imroc.io/posts/kubernetes-overflow-and-drop/
echo "net.core.somaxconn=32768" >> /etc/sysctl.d/k8s.conf
# 默认值: 128 指定了每一个 real user ID 可创建的 inotify instatnces 的数量上限
echo "fs.inotify.max_user_instances=524288" >> /etc/sysctl.d/k8s.conf
# 表示同一用户同时可以添加的watch数目（watch一般是针对目录，决定了同时同一用户可以监控的目录数量) 默认值 8192 在容器场景下偏小，在某些情况下可能会导致 inotify watch 数量耗尽，使得创建 Pod 不成功或者 kubelet 无法启动成功，将其优化到 524288
echo "fs.inotify.max_user_watches=524288" >> /etc/sysctl.d/k8s.conf
# 没有启用syncookies的情况下，syn queue(半连接队列)大小除了受somaxconn限制外，也受这个参数的限制，默认1024，优化到8096，避免在高并发场景下丢包
echo "net.ipv4.tcp_max_syn_backlog=8096" >> /etc/sysctl.d/k8s.conf
# max-file 表示系统级别的能够打开的文件句柄的数量， 一般如果遇到文件句柄达到上限时，会碰到
# Too many open files 或者 Socket/File: Can’t open so many files 等错误
#fs.file-max=2097152
echo "net.core.bpf_jit_enable=1" >> /etc/sysctl.d/k8s.conf
echo "net.core.bpf_jit_harden=1" >> /etc/sysctl.d/k8s.conf
echo "net.core.bpf_jit_kallsyms=1" >> /etc/sysctl.d/k8s.conf
echo "net.core.dev_weight_tx_bias=1" >> /etc/sysctl.d/k8s.conf
echo "net.core.rmem_max=16777216" >> /etc/sysctl.d/k8s.conf
echo "net.core.wmem_max=16777216" >> /etc/sysctl.d/k8s.conf
echo "net.ipv4.tcp_rmem=4096 12582912 16777216" >> /etc/sysctl.d/k8s.conf
echo "net.ipv4.tcp_wmem=4096 12582912 16777216" >> /etc/sysctl.d/k8s.conf
echo "net.core.rps_sock_flow_entries=8192" >> /etc/sysctl.d/k8s.conf
echo "net.ipv4.tcp_max_orphans=32768" >> /etc/sysctl.d/k8s.conf
echo "net.ipv4.tcp_max_tw_buckets=32768" >> /etc/sysctl.d/k8s.conf
echo "vm.max_map_count=262144" >> /etc/sysctl.d/k8s.conf
echo "kernel.threads-max=30058" >> /etc/sysctl.d/k8s.conf
# 避免发生故障时没有 coredump
echo "kernel.core_pattern=core" >> /etc/sysctl.d/k8s.conf
#touch /etc/modprobe.d/nf_conntrack.conf
#echo "options nf_conntrack hashsize=655360" > /etc/modprobe.d/nf_conntrack.conf
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

mkdir - /etc/docker
touch /etc/docker/daemon.json
echo '{'>> /etc/docker/daemon.json
echo '  "log-opts": {' >> /etc/docker/daemon.json
echo '    "max-size": "100m"' >> /etc/docker/daemon.json
echo '  },' >> /etc/docker/daemon.json
echo '  "storage-driver": "overlay2",' >> /etc/docker/daemon.json
echo '  "exec-opts": ["native.cgroupdriver=systemd"],' >> /etc/docker/daemon.json
echo '  "dns":["114.114.114.114"],' >> /etc/docker/daemon.json
echo '  "dns-search":["default.svc.cluster.local","svc.cluster.local","localdomain"],' >> /etc/docker/daemon.json
echo '  "dns-opt":["ndots:2","timeout:2","attempts:2"],' >> /etc/docker/daemon.json
echo '  "registry-mirrors": [' >> /etc/docker/daemon.json
echo '    "https://fmu2ap2k.mirror.aliyuncs.com",' >> /etc/docker/daemon.json
echo '    "https://gcr-mirror.qiniu.com",' >> /etc/docker/daemon.json
echo '    "https://quay-mirror.qiniu.com",' >> /etc/docker/daemon.json
echo '    "https://docker.mirrors.ustc.edu.cn",' >> /etc/docker/daemon.json
echo '    "https://mirror.ccs.tencentyun.com",' >> /etc/docker/daemon.json
echo '    "http://hub-mirror.c.163.com",' >> /etc/docker/daemon.json
echo '    "https://reg-mirror.qiniu.com",' >> /etc/docker/daemon.json
echo '    "http://f1361db2.m.daocloud.io",' >> /etc/docker/daemon.json
echo '    "https://registry.docker-cn.com"' >> /etc/docker/daemon.json
echo '  ]' >> /etc/docker/daemon.json
echo '}' >> /etc/docker/daemon.json

osversion=`rpm -q centos-release`
if [[ "$osversion" =~ ^centos-release-8 ]]; then
yum install -y https://download.docker.com/linux/fedora/30/x86_64/stable/Packages/containerd.io-1.2.13-3.2.fc30.x86_64.rpm
fi

# 添加阿里docker安装源
#osversion=`rpm -q centos-release|cut -d- -f3 |cut -d. -f1`
if [ ! -f "/usr/lib/systemd/system/docker.service" ]; then 

yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

yum makecache fast
yum list docker-ce.x86_64 --showduplicates | sort -r
yum install docker-ce -y
systemctl start docker
systemctl enable docker
fi

# 添加kubernetes 安装源为阿里源
mv kubernetes.repo /etc/yum.repos.d/
setenforce 0
yum install -y kubelet kubeadm kubectl
yum install -y  bash-completion bash-completion-extras
echo "source <(kubectl completion bash)" >> ~/.bashrc
source <(kubectl completion bash)
# 添加 api server loadbalance 配置
if [ "$lb" -eq 1 ];then
        echo "use lvscare as lb of master"
        echo "10.103.97.2 apiserver.cluster.local" >> /etc/hosts   # using vip
        docker pull fanux/lvscare:v1.0.1
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