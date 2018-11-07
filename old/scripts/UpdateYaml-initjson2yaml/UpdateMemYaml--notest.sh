#!/bin/bash
set -x
echo -e "\n----------Master kubectl Status------------\n"
timeout 2s kubectl get namespaces >/dev/null 2>&1
if [[ $? == 0 ]]                  
then                              
    echo "kubectl service is OK."
else
    echo "kubectl service have issue."
    exit 1
fi
echo -e "\n----------Master Docker Status------------\n"
timeout 2s docker ps -qa >/dev/null 2>&1
if [[ $? == 0 ]]
then
    echo "Dokcer service is OK."
else
    echo "Docker service have issue."
    exit 2
fi
echo -e "\n----------Cluster Pod Status------------\n"

Namespace=$(kubectl get namespaces|grep itsma*| awk '{print $1}')
Podlist=$(kubectl get pod -n ${Namespace} --no-headers | grep -v "1/1" | awk '{print $1}')

UpdateYamlandRestart(){
    local PodName=$1
    kubectl get pod ${PodName} -n ${Namespace} -o yaml >./tmp/${PodName}.yaml
    kubectl delete -f ./tmp/${PodName}.yaml
    sed '/kubernetes.io\/init-containers/p' ./tmp/${PodName}.yaml |head -n1|cut -d"'" -f 2 >IninJson.json
    echo "initContainers:">NeedInsert.yaml
    ./json2yaml IninJson.json >>NeedInsert.yaml
    sed -i 's/^/  /g' NeedInsert.yaml
    sed -ie.bak '/kubernetes.io\/init-container/d;/^spec:/r NeedInsert.yaml' ./tmp/${PodName}.yaml
    kubectl create -f ./tmp/${PodName}.yaml
    echo ${PodName} update yaml success.
    sleep 2s
}

for Pod in ${Podlist}
do
    UpdateYamlandRestart ${Pod}
done
