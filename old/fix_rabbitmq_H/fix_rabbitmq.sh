#!/bin/sh

namespace=`kubectl get namespace |grep itsma | cut -f1 -d " "`

function check_service(){
service_name=$1
echo checking service ${service_name}
while [ true ]; do
if [[ ${service_name} == itom-xservices-platform ]]; then
  number=`kubectl get pods --all-namespaces --show-all -o wide |grep ${service_name} | grep -v nginx | grep -v offline | awk -F " *|/" '($3!=$4 || $5!="Running") && $5!="Completed"  && $5!="Terminating" {print $0}' |wc -l`
else
  number=`kubectl get pods --all-namespaces --show-all -o wide |grep ${service_name} | awk -F " *|/" '($3!=$4 || $5!="Running") && $5!="Completed"  && $5!="Terminating" {print $0}' |wc -l`
fi
echo -ne "."
if [ $number -eq 0 ]; then
  echo ""
  break
fi
done
}

platform_num=`kubectl get pods -n ${namespace} |grep platform |grep -v offline |grep -v  nginx | wc -l`
gateway_num=`kubectl get pods -n ${namespace} |grep gateway |grep -v mobile | wc -l`
serviceportal_num=`kubectl get pods -n ${namespace} |grep serviceportal | wc -l`

if [ $platform_num == 0 ]; then
  platform_num=1
fi

if [ $gateway_num == 0 ]; then
  gateway_num=1
fi

if [ $serviceportal_num == 0 ] ; then
  serviceportal_num=1
fi

echo Stop Services
kubectl scale deployment itom-xservices-redis -n ${namespace} --replicas=0
kubectl scale deployment itom-xservices-rabbitmq -n ${namespace} --replicas=0
kubectl scale deployment itom-xservices-serviceportal -n ${namespace} --replicas=0
kubectl scale deployment itom-xservices-gateway -n ${namespace} --replicas=0
kubectl scale deployment itom-xservices-platform -n ${namespace} --replicas=0


echo backup rabbitmq data
dname=`date '+%Y-%m-%d-%H-%M'`
echo "Go to your SMA NFS share folder by default: /var/vols/itom/itsma/"
echo mv itom-itsma-db/rabbitmq/xservices/mnesia itom-itsma-db/rabbitmq/xservices/mnesia.${dname}
read -p "Done? Press Enter to continue"

echo Start up redis
kubectl scale deployment itom-xservices-redis -n ${namespace} --replicas=1
check_service itom-xservices-redis

echo Start up rabbitmq
kubectl scale deployment itom-xservices-rabbitmq -n ${namespace} --replicas=1
check_service itom-xservices-rabbitmq


mq_ip=`kubectl get pods -n ${namespace} -o wide | grep rabbitmq |grep -v propel-rabbitmq | awk 'BEING{FS=" "}{print $6}'|head -n 1`

sleep 20
echo Rebuild structure for rabbitmq
echo ./rabbitmqadmin --host ${mq_ip} -P 15672 -u maasuser -p maasuserpwd -q import rabbit-definitions.json
./rabbitmqadmin --host ${mq_ip} -P 15672 -u maasuser -p maasuserpwd -q import rabbit-definitions.json
if [ $? == 0 ]; then
  echo "Rebuild structure successfully"
fi

echo Restart rest services
kubectl scale deployment itom-xservices-platform -n ${namespace} --replicas=1
check_service itom-xservices-platform
kubectl scale deployment itom-xservices-gateway -n ${namespace} --replicas=1
check_service itom-xservices-gateway
kubectl scale deployment itom-xservices-serviceportal -n ${namespace} --replicas=1
check_service itom-xservices-serviceportal

echo Scale to original one
kubectl scale deployment itom-xservices-platform -n ${namespace} --replicas=${platform_num}
kubectl scale deployment itom-xservices-gateway -n ${namespace} --replicas=${gateway_num}
kubectl scale deployment itom-xservices-serviceportal -n ${namespace} --replicas=${serviceportal_num}

echo "Finished successfully"