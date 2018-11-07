#!/bin/bash -f
namespace=`kubectl get namespace |grep itsma | cut -f1 -d " "`
if [[ ! -f SMASuite.txt ]]; then
  kubectl get deployments -n $namespace -o wide | tail -n +2 | awk '{print $1,$2}' > SMASuite.txt
else
  dname=`date '+%Y-%m-%d-%H-%M'`
  mv SMASuite.txt SMASuite-${dname}.txt
  kubectl get deployments -n $namespace -o wide | tail -n +2 | awk '{print $1,$2}' > SMASuite.txt
fi
echo "Save SMASuite.txt successfully!"