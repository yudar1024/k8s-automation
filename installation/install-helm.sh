if [ ! -f "helm-v2.14.3-linux-amd64.tar.gz" ]; then
wget -c -t 0 https://get.helm.sh/helm-v2.14.3-linux-amd64.tar.gz
fi
tar -zxf helm-v2.14.3-linux-amd64.tar.gz
chmod +x linux-amd64/helm
mv linux-amd64/helm /usr/local/bin
kubectl create serviceaccount --namespace=kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
version=`kubeadm version -o short`
# note 正则不能使用引号，变量可以使用引号
if [[ "$version" =~ ^1.16 ]]; then
helm init -i registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:v2.14.3 --stable-repo-url http://mirror.azure.cn/kubernetes/charts/ --service-account tiller --override spec.selector.matchLabels.'name'='tiller',spec.selector.matchLabels.'app'='helm' --output yaml | sed 's@apiVersion: extensions/v1beta1@apiVersion: apps/v1@' | kubectl apply -f -
else
helm init --upgrade -i registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:v2.14.3 --stable-repo-url http://mirror.azure.cn/kubernetes/charts/ --service-account=tiller
fi

