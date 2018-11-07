#!/bin/bash
source /etc/profile.d/alias.sh
namespace=$(kubectl get namespaces|grep itsma*| awk '{print $1}')
localzone=$(date +%Z)
echo "the timezone is ${localzone} on your host."
podlist=$(kubectl get pod -n ${namespace}| awk 'NR>1{print $1}')
echo "">time.txt
for pod in $podlist
do
    zone=$(ke $pod  date +%Z|tail -n2| head -n1)
    if [[ $zone != $localzone ]];then
        echo "$pod timezone is $zone ,need sync time."| tee -a time.txt
    fi
done

