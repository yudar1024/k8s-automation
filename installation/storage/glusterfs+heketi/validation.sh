#!/bin/bash
GLUSTERPODNAME=`kubectl get pod -n glusterfs | grep heketi | awk '{print $1}'`
#kubectl -n glusterfs exec -i ${GLUSTERPODNAME} -- heketi-cli -s http://localhost:8080 --user admin --secret 'openstack' cluster list | grep "Id" 
GLUSTERCLUSTERID=`kubectl -n glusterfs exec -i ${GLUSTERPODNAME} -- heketi-cli -s http://localhost:8080 --user admin --secret 'openstack' cluster list | awk 'NR>1{print substr($1,4)}'`
echo $GLUSTERCLUSTERID
GLUSTERCLUSTERIP=`kubectl get svc -n glusterfs | grep 8080 | awk '{ print $3}'`
sed -i "s/CLUSTERID/${GLUSTERCLUSTERID}/" storageclass.yaml
sed -i "s/HEKETI_URL/http:\/\/${GLUSTERCLUSTERIP}:8080/" storageclass.yaml
kubectl apply -f storageclass.yaml
kubectl apply -f pvc.yaml
kubectl get sc,pv,pvc
