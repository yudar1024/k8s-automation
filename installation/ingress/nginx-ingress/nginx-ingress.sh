#!/bin/bash
AddTolerations(){
  # 计算总共有多少行
    end=`sed -n '$=' mandatory.yaml`
    echo "end = $end"
    begin=$[end-1]
    echo "begin = $begin"
    sed -i "$begin,$ d" mandatory.yaml
    sed -i 's/quay.io\/kubernetes-ingress-controller/registry.cn-hangzhou.aliyuncs.com\/google_containers/g' mandatory.yaml
    echo '# 添加部分内容' >> mandatory.yaml
    echo '      hostNetwork: true' >> mandatory.yaml
    echo '      affinity:  # 声明亲和性设置' >> mandatory.yaml
    echo '        nodeAffinity: # 声明 为 Node 亲和性设置' >> mandatory.yaml
    echo '          requiredDuringSchedulingIgnoredDuringExecution:  # 必须满足下面条件' >> mandatory.yaml
    echo '            nodeSelectorTerms: # 声明 为 Node 调度选择标签' >> mandatory.yaml
    echo '            - matchExpressions: # 设置node拥有的标签' >> mandatory.yaml
    echo '              - key: kubernetes.io/hostname  #  kubernetes内置标签' >> mandatory.yaml
    echo '                operator: In   # 操作符' >> mandatory.yaml
    echo '                values:        # 值,既集群 node 名称' >> mandatory.yaml
# master1 要根据实际情况的值改动
    echo '                - master1' >> mandatory.yaml
    echo '        podAntiAffinity:  # 声明 为 Pod 亲和性设置' >> mandatory.yaml
    echo '          requiredDuringSchedulingIgnoredDuringExecution:  # 必须满足下面条件' >> mandatory.yaml
    echo '            - labelSelector:  # 与哪个pod有亲和性，在此设置此pod具有的标签' >> mandatory.yaml
    echo '                matchExpressions:  # 要匹配如下的pod的,标签定义' >> mandatory.yaml
    echo '                  - key: app.kubernetes.io/name  # 标签定义为 空间名称(namespaces)' >> mandatory.yaml
    echo '                    operator: In' >> mandatory.yaml
    echo '                    values: ' >> mandatory.yaml
    echo '                    - ingress-nginx' >> mandatory.yaml
    echo '              topologyKey: "kubernetes.io/hostname"    # 节点所属拓朴域' >> mandatory.yaml
    echo '      tolerations:    # 声明 为 可容忍 的选项' >> mandatory.yaml
    echo '      - key: node-role.kubernetes.io/master    # 声明 标签为 node-role 选项' >> mandatory.yaml
    echo '        effect: NoSchedule                     # 声明 node-role 为 NoSchedule 也可容忍' >> mandatory.yaml
}

# wget -c -t 0 https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml
if [ -s 'mandatory.yaml' ]; then
    read -p "you have do you want download latest version? y/n" dl
    case $dl in
        # Y | y ) curl -C - https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml -o mandatory.yaml;
        Y | y ) curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml -o mandatory.yaml;
        ;;
        * ) echo "use exsit one";;
    esac
else
    # curl -C - https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml -o mandatory.yaml;
    curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml -o mandatory.yaml;
fi

if [ -s 'mandatory.yaml' ]; then
    AddTolerations
    #        cat mandatory.yaml
    read -p "execut install ingress controller? y/n" answer
    case $answer in
        [Yy]* ) kubectl apply -f mandatory.yaml;;
        [Nn]* ) exit 0;;
        * ) echo "please input Y/y or N/n"; exit 0;;
    esac
else
    echo 'miss mandatory.yaml file, begin download latest one'
fi
