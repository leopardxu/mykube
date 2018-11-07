#!/bin/bash -f
if [[ ! -f SMASuite.txt ]]; then
  echo "SMASuite.txt does not exit, run './saveSMASuite.sh to create one, exit..."
  exit
fi

namespace=`kubectl get namespace |grep itsma | cut -f1 -d " "`
while read line
do
  depl=$(echo $line | awk '{print $1}')
  repl=$(echo $line | awk '{print $2}')
  echo "Starting deployment $depl (replicas=$repl)"
  if [[ $repl -gt 0 ]]; then
    kubectl scale --replicas=$repl deployment/$depl -n $namespace
  else
    echo "Warning, the replicas number($repl) for service($depl) is not correct!"
  fi
done < SMASuite.txt