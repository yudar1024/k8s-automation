#安装
yum install heketi heketi-client -y
modprobe dm_thin_pool
#heketi 免密
ssh-keygen -t rsa -q -f /var/lib/heketi/id_rsa -N ''
chown heketi:heketi /var/lib/heketi/id_rsa*
ssh-copy-id -i /var/lib/heketi/id_rsa root@node1
ssh-copy-id -i /var/lib/heketi/id_rsa root@node2
ssh-copy-id -i /var/lib/heketi/id_rsa root@node3
# heketi 配置
cp heketi.json /etc/heketi/
cp topology.json /etc/heketi/
#启动heketi
systemctl start heketi
systemctl enable heketi
export HEKETI_CLI_SERVER=http://192.168.10.50:8888
#heketi-cli --user admin --secret openstack -s http://192.168.10.50:8888 topology load --json /etc/heketi/topology.json
heketi-cli topology load --json=/etc/heketi/topology.json
#alias heketi-cli='heketi-cli --server "http://192.168.10.50:8888" --user admin --secret openstack'

