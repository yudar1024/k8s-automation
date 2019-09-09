yum install heketi heketi-client -y
modprobe dm_thin_pool
cp heketi.json /etc/heketi/
cp topology.json /etc/heketi/
ssh-keygen -t rsa -q -f /var/lib/heketi/id_rsa -N ''
chown heketi:heketi /var/lib/heketi/id_rsa*
ssh-copy-id -i /var/lib/heketi/id_rsa root@node1
ssh-copy-id -i /var/lib/heketi/id_rsa root@node2
ssh-copy-id -i /var/lib/heketi/id_rsa root@node3
systemctl start heketi
systemctl enable heketi
heketi-cli --user admin --secret openstack --server http://node1:8888 topology load --json /etc/heketi/topology.json

