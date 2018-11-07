#!/bin/bash
timeout 2s kubectl get namespaces >/dev/null 2>&1
if [[ $? == 0 ]]                  
then                              
        echo "kubectl service is OK."
    else
        echo "kubectl service have issue."
        exit 1
fi
#hostName=`hostname --fqdn`
#local_ip=`host $hostName 2>/dev/null | awk '{print $NF}'`
local_ip=$(ifconfig | grep broadcast | grep -v 0.0.0.0 | head -n 1 | awk '{print $2}')
if [ -z $local_ip ];then
    echo "local_ip is null."
    exit 1
fi
sed -i s/\${hostIP}/$local_ip/g prometheus-grafana-all.yaml
kubectl create -f prometheus-grafana-all.yaml
