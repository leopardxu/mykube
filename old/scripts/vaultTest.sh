#!/bin/bash
#namespace=${namespace:=itsma}

usage()
{
    echo "$0 yournamespaces"
    exit 0
}
if [ $# -eq 1 ]
then
    kubectl get namespace $1 >/dev/null 2>&1
    if [ $? == 0 ]
    then
        namespace=$1
    else
        echo "the $1 is not exits,please verify it"
        exit 1
    fi
else
    usage
fi
podNumCoun=0
secretKeyNumCoun=`etcdctl --endpoint=https://15.119.87.7:4001 --ca-file /opt/kubernetes/ssl/ca.crt --cert-file /opt/kubernetes/ssl/server.crt --key-file /opt/kubernetes/ssl/server.key  ls  --recursive / | grep _key | cut -d . -f 2 | uniq | wc -l`
for podName in `kubectl get pods -n $namespace --show-all | grep -v NAME | awk '{print $1}'`
do
    secretNuminPod=0
    if [ -n "`kubectl describe pod $podName -n $namespace | grep vault-init |cut -d / -f 2 | cut -d : -f 2 | head -n 1`" ]
    then
        podNumCoun=`expr $podNumCoun + 1`
        for containerName in `kubectl describe pod $podName -n $namespace | sed -n '/Container\ ID/{x;p};h' | grep -v install | grep -v vault | sed 's/://g' | sed 's/\ \ //g'`
        do
            #      for secretKey in `(etcdctl ls  --recursive / | grep _key && etcdctl ls  --recursive / | grep _password )| cut -d . -f 2 | uniq`
            for secretKey in `etcdctl --endpoint=https://15.119.87.7:4001 --ca-file /opt/kubernetes/ssl/ca.crt --cert-file /opt/kubernetes/ssl/server.crt --key-file /opt/kubernetes/ssl/server.key ls  --recursive / | grep _key | cut -d . -f 2 | sort | uniq`
            do
                kubectl exec -it $podName -n $namespace -c $containerName get_secret $secretKey >/dev/null 2>&1
                if [ $? == 0 ]
                then
                    secretNuminPod=`expr $secretNuminPod + 1`
                    echo "the result:$secretKey in $podName is `kubectl exec -it $podName -n $namespace -c $containerName get_secret $secretKey`"
                fi
            done
        done
        echo ">>>>>>>>>>>>>The pod of $podName have $secretNuminPod secretkeys."
    fi
done
echo "the number of pods have using vault is $podNumCoun."
echo "the number of secret keys is $secretKeyNumCoun."

