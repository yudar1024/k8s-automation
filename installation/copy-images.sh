if [ "$#" -eq 0 ]; then
echo "请输入至少一个 node 节点的主机名或IP"
exit 0
fi
# -s 文件存在切不为空 -f 文件存在
if [ ! -s ".ssh/id_rsa" ]; then
echo "generate sshkey"
ssh-keygen -t rsa -b 2048
fi

#pull images
if [ ! -f "kubeadm-init.yaml" ]; then
kubeadm config print init-defaults > kubeadm-init.yaml
echo "使用阿里镜像"
sed -i "s?k8s.gcr.io?registry.cn-hangzhou.aliyuncs.com/google_containers?" kubeadm-init.yaml
# 当sed的替换内容和被替换内容也包含/ \ 等字符时，可以使用? 代替原来sed 本身的/ 字符。https://www.cnblogs.com/linux-wangkun/p/5745584.html
sed -i 's?imageRepository: k8s.gcr.io?imageRepository: registry.cn-hangzhou.aliyuncs.com/google_containers?' kubeadm-init.yaml
fi
version=`kubeadm version -o short`
sed -i '/kubernetesVersion/d' kubeadm-init.yaml
sed -i "/kind: ClusterConfiguration/akubernetesVersion: $version" kubeadm-init.yaml
echo "开始拉取镜像"
#awk 使用shell 变量方法1 awk -v awk_var1=$version 然后就可以在 表达式中使用awk_var1
# 直接使用 shell 变量
docker images |  'NR>1 && /^registry.cn-hangzhou.*'$version'/ {count=split($1,img,"/");cmd="docker image save "$1":"$2 " -o " img[3]"-"$2".tar"; system(cmd)}'
echo "镜像拉取完毕"
echo "--------------------------------------"
echo "--------------------------------------"
echo "开始道拷贝到如下机器"
echo "$*"
for i in "$*"; do
echo "设置$i免密"
ssh-copy-id root@$i
echo "拷贝镜像到$i"
scp coredns-$version.tar root@$i:~
scp etcd.tar root@$i:~
scp kube-apiserver-$version.tar root@$i:~
scp kube-controller-manager-$version.tar root@$i:~
scp kube-proxy-$version.tar root@$i:~
scp kube-scheduler-$version.tar root@$i:~
scp pause-$version.tar root@$i:~
done

#load images cmd
# ls | grep tar$ | awk '{cmd="docker load -i "$1;system(cmd)}'


