#!/bin/bash
if [[ ! -f SMASuite.txt ]]; then
  echo "SMASuite.txt does not exit, generating...."
  ./saveSMASuite.sh
fi

namespace=`kubectl get namespace |grep itsma | cut -f1 -d " "`
while read line
do
  depl=$(echo $line | awk '{print $1}')
  repl=$(echo $line | awk '{print $2}')
  echo "Stopping deployment $depl (replicas=$repl)"
  kubectl scale --replicas=0 deployment/$depl -n $namespace
done < SMASuite.txt

