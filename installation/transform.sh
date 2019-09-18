# generate ssh key
ssh-keygen -t rsa -b 2048
ssh-copy-id root@192.168.10.52
ssh-copy-id root@192.168.10.53
ssh-copy-id root@192.168.10.54
ssh-copy-id root@192.168.10.51

#copy ca to other masters
ssh 192.168.10.51 "mkdir -p /etc/kubernetes/pki/etcd"
ssh 192.168.10.52 "mkdir -p /etc/kubernetes/pki/etcd"
scp /etc/kubernetes/pki/ca.* 192.168.10.51:/etc/kubernetes/pki/
scp /etc/kubernetes/pki/sa.* 192.168.10.51:/etc/kubernetes/pki/
scp /etc/kubernetes/pki/front-proxy-ca.* 192.168.10.51:/etc/kubernetes/pki/
scp /etc/kubernetes/pki/etcd/ca.* 192.168.10.51:/etc/kubernetes/pki/etcd/
scp /etc/kubernetes/admin.conf 192.168.10.51:/etc/kubernetes/

scp /etc/kubernetes/pki/ca.* 192.168.10.52:/etc/kubernetes/pki/
scp /etc/kubernetes/pki/sa.* 192.168.10.52:/etc/kubernetes/pki/
scp /etc/kubernetes/pki/front-proxy-ca.* 192.168.10.52:/etc/kubernetes/pki/
scp /etc/kubernetes/pki/etcd/ca.* 192.168.10.52:/etc/kubernetes/pki/etcd/
scp /etc/kubernetes/admin.conf 192.168.10.52:/etc/kubernetes/

# save docker image and cp to other masters
docker images | awk 'NR>1 && /^registry/ {count=split($1,img,"/");cmd="docker image save "$1":"$2 " -o " img[3]".tar"; system(cmd)}'
scp etcd.tar root@192.168.10.51:~
scp etcd.tar root@192.168.10.52:~
scp etcd.tar root@192.168.10.53:~
scp etcd.tar root@192.168.10.54:~

scp kube-apiserver.tar root@192.168.10.51:~
scp kube-apiserver.tar root@192.168.10.52:~
scp kube-apiserver.tar root@192.168.10.53:~
scp kube-apiserver.tar root@192.168.10.54:~

scp kube-scheduler.tar root@192.168.10.51:~
scp kube-scheduler.tar root@192.168.10.52:~
scp kube-scheduler.tar root@192.168.10.53:~
scp kube-scheduler.tar root@192.168.10.54:~

scp pause.tar root@192.168.10.51:~
scp pause.tar root@192.168.10.52:~
scp pause.tar root@192.168.10.53:~
scp pause.tar root@192.168.10.54:~

scp kube-controller-manager.tar root@192.168.10.51:~
scp kube-controller-manager.tar root@192.168.10.52:~
scp kube-controller-manager.tar root@192.168.10.53:~
scp kube-controller-manager.tar root@192.168.10.54:~

scp coredns.tar root@192.168.10.51:~
scp coredns.tar root@192.168.10.52:~
scp coredns.tar root@192.168.10.53:~
scp coredns.tar root@192.168.10.54:~

scp kube-proxy.tar root@192.168.10.51:~
scp kube-proxy.tar root@192.168.10.52:~
scp kube-proxy.tar root@192.168.10.53:~
scp kube-proxy.tar root@192.168.10.54:~

# load docker images in other master
ssh 192.168.10.51 "docker load -i etcd.tar"
ssh 192.168.10.52 "docker load -i etcd.tar"
ssh 192.168.10.53 "docker load -i etcd.tar"
ssh 192.168.10.54 "docker load -i etcd.tar"


ssh 192.168.10.51 "docker load -i kube-apiserver.tar"
ssh 192.168.10.52 "docker load -i kube-apiserver.tar"
ssh 192.168.10.53 "docker load -i kube-apiserver.tar"
ssh 192.168.10.54 "docker load -i kube-apiserver.tar"

ssh 192.168.10.51 "docker load -i kube-scheduler.tar"
ssh 192.168.10.52 "docker load -i kube-scheduler.tar"
ssh 192.168.10.53 "docker load -i kube-scheduler.tar"
ssh 192.168.10.54 "docker load -i kube-scheduler.tar"

ssh 192.168.10.51 "docker load -i pause.tar"
ssh 192.168.10.52 "docker load -i pause.tar"
ssh 192.168.10.53 "docker load -i pause.tar"
ssh 192.168.10.54 "docker load -i pause.tar"

ssh 192.168.10.51 "docker load -i kube-controller-manager.tar"
ssh 192.168.10.52 "docker load -i kube-controller-manager.tar"
ssh 192.168.10.53 "docker load -i kube-controller-manager.tar"
ssh 192.168.10.54 "docker load -i kube-controller-manager.tar"

ssh 192.168.10.51 "docker load -i coredns.tar"
ssh 192.168.10.52 "docker load -i coredns.tar"
ssh 192.168.10.53 "docker load -i coredns.tar"
ssh 192.168.10.54 "docker load -i coredns.tar"


ssh 192.168.10.51 "docker load -i kube-proxy.tar"
ssh 192.168.10.52 "docker load -i kube-proxy.tar"
ssh 192.168.10.53 "docker load -i kube-proxy.tar"
ssh 192.168.10.54 "docker load -i kube-proxy.tar"
