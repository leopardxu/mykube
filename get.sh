#!/bin/bash
echo -e "----------Cluster Pod Status------------\n"
kubectl get pod --all-namespaces|grep -v Running
echo -e "\n----------Cluster Resource Status------------\n"
kubectl describe node | awk '/^Name/;/^Non-terminated/;/^\ \ CPU/,/\)$/ {print}'
echo -e "\n----------Master Memery Status------------\n"
free -h
echo -e "\n----------Master Disk Status------------\n"
timeout 2s df -h|head -n 3
echo -e "\n----------Master Docker Status------------\n"
docker ps -qa >/dev/null 2>&1
if [[ $? == 0 ]]
then
        echo "Dokcer service is OK."
else
        echo "Docker service have issue."
fi
