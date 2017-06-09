#!/bin/bash
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
fi
echo -e "\n----------Cluster Pod Status------------\n"
#kubectl get pod --all-namespaces|grep -v Running
namespace=$(kubectl get namespaces|grep itsma*| awk '{print $1}')
podlist=$(kubectl get pod -n $namespace --no-headers |awk '{print $1}')
for pod in $podlist
do
    readystatus=$(kubectl describe pod $pod -n itsma1| awk '/^\ \ Ready/ {print$2}')
    if [[ "$readystatus"A == "False"A ]]
    then
        echo -e " $pod is not Ready.\n"
    fi
done
echo -e "\n----------Cluster Resource Status------------\n"
kubectl describe node | awk '/^Name/;/^Non-terminated/;/^\ \ CPU/,/\)$/ {print}'
echo -e "\n----------Master Memery Status------------\n"
free -h
echo -e "\n----------Master Disk Status------------\n"
timeout 2s df -h|head -n 3

