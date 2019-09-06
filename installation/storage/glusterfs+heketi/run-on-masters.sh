#!/bin/bash
git clone https://github.com/yudar1024/gluster-kubernetes.git
yum install -y heketi-client -y
read -p 'do you want include master nodes in glusterfs cluster [Y]]es, [N]o? [Default: n]? ' choose
# 如果没有显示的指定n/y 取默认值 n
choose=${choose:-n}
echo "you choose is ${choose}"
if [[ "${choose}" == "y" || "${choose}" == "Y" ]]; then
  sed -i '/hostNetwork: true/a\      tolerations: '  gluster-kubernetes/deploy/kube-templates/glusterfs-daemonset.yaml
  sed -i '/tolerations/a\        - key: node-role.kubernetes.io/master' gluster-kubernetes/deploy/kube-templates/glusterfs-daemonset.yaml
  sed -i '/key: node-role.kubernetes.io/a\          operator: Exists' gluster-kubernetes/deploy/kube-templates/glusterfs-daemonset.yaml
  sed -i '/operator: Exists/a\          effect: NoSchedule' gluster-kubernetes/deploy/kube-templates/glusterfs-daemonset.yaml
fi
sed -i 's/"key" : ""/"key" : "openstack"/g' gluster-kubernetes/deploy/heketi.json.template
sed -i '/targetPort: 8080/a\  type: NodePort' gluster-kubernetes/deploy/kube-templates/heketi-deployment.yaml
ns=`kubectl get ns | grep glusterfs | awk '{print $1}'`
if [[ "${ns}" == "glusterfs" ]]; then
  echo 'glusterfs namespace already exsit'
else 
  kubectl create ns glusterfs
fi
cp gluster-kubernetes/deploy/topology.json.sample gluster-kubernetes/deploy/topology.json
sed -i 's/"key" : ""/"key" : "openstack"/g' gluster-kubernetes/deploy/topology.json
echo ' please edit gluster-kubernetes/deploy/topology.json files then run "./gk-deploy -g -n glusterfs -c kubectl --admin-key openstack --user-key openstack -v" in  gluster-kubernetes/deploy folder'

# dd if=/dev/zero of=/dev/sdb bs=1k count=1
# blockdev --rereadpt /dev/sdb
# need reboot