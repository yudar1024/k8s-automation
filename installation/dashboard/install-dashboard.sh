kubectl apply -f dashboard-v2.yaml
# 生成dashbaord ssl 证书
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout dashboard.key -out dashboard.crt -subj "/CN=dashboard.k8s.me"
kubectl create secret tls kubernetes-dashboard-certs --namespace=kubernetes-dashboard --cert dashboard.crt --key dashboard.key
kubectl apply -f admin-sa.yaml
