yum install centos-release-gluster -y
yum -y install glusterfs-server glusterfs-fuse
systemctl enable glusterd
systemctl start glusterd
systemctl status glusterd
modprobe fuse
echo "modprobe -- fuse" >> /etc/sysconfig/modules/glusterfs.modules