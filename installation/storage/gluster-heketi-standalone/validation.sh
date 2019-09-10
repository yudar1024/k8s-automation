#!/bin/bash
GLUSTERCLUSTERID=`heketi-cli -s http://localhost:8888 --user admin --secret 'openstack' cluster list | awk 'NR==2{print substr($1,4)}'`
echo "cluster id = $GLUSTERCLUSTERID"
GLUSTERCLUSTERIP=`kubectl get svc  | grep heketi-service | awk '{ print $3}'`
echo "ip = ${GLUSTERCLUSTERIP}"
CLUSETERPORT=`kubectl get svc | grep heketi-service |awk '{split($5,port,"/");print port[1]}'`
echo "CLUSETERPORT = ${CLUSETERPORT}"
sed -i "s/CLUSTERID/${GLUSTERCLUSTERID}/" storageclass.yaml
sed -i "s/HEKETI_URL/http:\/\/${GLUSTERCLUSTERIP}:${CLUSETERPORT}/" storageclass.yaml
kubectl apply -f storageclass.yaml
kubectl apply -f pvc.yaml
kubectl get sc,pv,pvc
