#!/bin/bash
#set -x
usage(){
    echo "============from 139 to 158==================="
    echo "1.you need:
               hyperkube-amd64-v1.6.9.tgz
               kubernetes-vault-init-0.2.1.tgz
               mng-portal-1.4-00158.tgz
               suite-installer-1.0-00158.tgz
               kubernetes-vault-renew-0.2.1.tgz
               keepalived-1.3.5-00158.tgz
               139to158.sh
               on your masters nodes and 
               kubernetes-vault-init-0.2.1.tgz
               kubernetes-vault-renew-0.2.1.tgz
               on your worker nodes."
    echo "---------------------------------------------"
    echo "2. docker load -i ***.tar.gz on all master and worker nodes"
    echo "---------------------------------------------"
    echo "3. run script on master node;
               please run this scirpt on no-livemaster first
               it is a long time on livemaster to run it as it will restart all itsma pods"
    echo "============================================="
}
usage
read -p "please verify the 1&2&3 step is end and Enter Y: "
if [[ $REPLY == Y ]];then
    echo  " will update cdf to 158."
else
    exit 1
fi
read -p "is an three masters?and Enter Y or Enter N:" isthreemaster
read -p "is an live master?and Enter Y or Enter N:" islivemaster

if [[ $isthreemaster == Y ]];then
    echo " get env of keepalived container and  restart keepalived with new 158 image"
    keepalived_container_id=`docker ps  |grep keepalived |awk '{print $1}'`

    RESTART_POLICY=`docker inspect ${keepalived_container_id} |grep -iA 2  RESTARTPOLICY |grep -i name |awk -F "\"" '{print $4}'`
    KEEPALIVED_PRIORITY=`docker inspect ${keepalived_container_id} |grep  KEEPALIVED_PRIORITY |awk -F "[\"=]" '{print $3}'`
    KEEPALIVED_INTERFACE=`docker inspect ${keepalived_container_id} |grep  KEEPALIVED_INTERFACE |awk -F "[\"=]" '{print $3}'`
    KEEPALIVED_VIRTUAL_IPS=`docker inspect ${keepalived_container_id} |grep KEEPALIVED_VIRTUAL_IPS |awk -F "[\"=]" '{print $3}'`
    KEEPALIVED_UNICAST_PEERS=`docker inspect ${keepalived_container_id} |grep KEEPALIVED_UNICAST_PEERS |awk -F "[\"=]" '{print $3}'`
    LOCAL_IP=`docker inspect ${keepalived_container_id} |grep LOCAL_IP |awk -F "[\"=]" '{print $3}'`
    BUILD_NUM=00158

    #kill keepalived container
    docker rm -f ${keepalived_container_id}
    #start keepalived contaier
    docker run --cap-add=NET_ADMIN \
        --net=host \
        --name=KeepAlived \
        --restart=${RESTART_POLICY} \
        --env KEEPALIVED_PRIORITY="${KEEPALIVED_PRIORITY}" \
        --env KEEPALIVED_INTERFACE="${KEEPALIVED_INTERFACE}" \
        --env KEEPALIVED_VIRTUAL_IPS="${KEEPALIVED_VIRTUAL_IPS}" \
        --env KEEPALIVED_UNICAST_PEERS="${KEEPALIVED_UNICAST_PEERS}" \
        --env LOCAL_IP="${LOCAL_IP}" \
        --detach localhost:5000/keepalived:1.3.5-${BUILD_NUM}
fi

#restart all itsma pods on livemaster.
if [[ $islivemaster == Y ]];then
    echo "delete need upgrade pods."
    kubectl delete -f /opt/kubernetes/objectdefs/suite.yaml
    kubectl delete -f /opt/kubernetes/objectdefs/mng-portal.yaml
    kubectl delete -f /opt/kubernetes/objectdefs/idm-pg.yaml
    kubectl delete -f /opt/kubernetes/objectdefs/idm.yaml
    kubectl delete -f /opt/kubernetes/objectdefs/heapster.yaml
    sleep 10s

    echo "modify yaml files."
    cd /opt/kubernetes/objectdefs
    sed -ri.bck 's#1\.0\-00139#1\.0\-00158#g' suite.yaml
    sed -i.bck 's#00139#00158#g' mng-portal.yaml
    cd /opt/kubernetes/manifests
    #sed -i.bck 's#v1\.6\.1#v1\.6\.9#g' kube-apiserver.yaml
    sed -ie  '16,18d;s#namespace:\ core#namespace:\ kube-system#g' /opt/kubernetes/objectdefs/heapster.yaml

    echo "update cdf images to 158."
    apipodNames=$(kubectl get pod -n core| awk '{print $1}'|grep ^apiserver-)
    for apipodName in $apipodNames
    do 
        kubectl set image pod $apipodName apiserver=gcr.io/google_containers/hyperkube:v1.6.9 -n core
    done
    kubectl create -f /opt/kubernetes/objectdefs/suite.yaml
    sleep 1s
    kubectl create -f /opt/kubernetes/objectdefs/mng-portal.yaml
    sleep 1s
    kubectl create -f /opt/kubernetes/objectdefs/idm-pg.yaml
    sleep 1s
    kubectl create -f /opt/kubernetes/objectdefs/idm.yaml
    sleep 1s
    kubectl create -f /opt/kubernetes/objectdefs/heapster.yaml
    sleep 1s

    echo "reboot all itsma pods on livemaster."
    namespace=$(kubectl get namespaces|grep itsma*| awk '{print $1}')
    if [[ ! -n $namespace ]];then
        podlist=$(kubectl get pod -n ${namespace}| awk '{print $1}')
        for pod in $podlist
        do
            kubectl delete pod $pod -n $namespace
            sleep 5s
            echo "$pod have been restarted."
        done
    fi
fi
