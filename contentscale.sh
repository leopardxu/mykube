#!/bin/bash

#enter the root path of NFSpath.
echo "-----------------------------------------------------------"
echo "------Please enter the path of NFS server------------------"
echo "-----------------------------------------------------------"
read NFSpath

echo "The path of NFS server is ${NFSpath}."
if [ "${NFSpath}" == "" -o ! -d "${NFSpath}" ]; then
	echo "The path of ${NFSpath} is NOT exist in your system."
	exit 1
fi

#Judge kubectl
kubectl get node 
if [ $? -eq 0 ]
then
echo "the kubernetes is exist in your system."
else 
echo "the kubernetes is NOT exist in your system."
exit 1
fi

#enter namespace for content
echo "-----------------------------------------------------------"
echo "------Please enter the namespace in cluster----------------"
echo "-----------------------------------------------------------"
read namespace
echo "The namespace is ${namespace} you enter."

#Judge the namespace
Isnamespace=0
for Nspace in `kubectl get namespace |awk '{print $1}'| sed 1d`
do
if [ ${Nspace} == ${namespace} ] 
then
echo "The cluster have namespace $namespace."
Isnamespace=1
fi
done
if [ "${namespace}" == "" -o ${Isnamespace} -eq 0 ]; then
        echo "The ${namespace} is NOT exist in your system."
        exit 1
fi

#get the num of content and propel content.
nums_content=`kubectl get svc --namespace=${namespace}|grep content|wc -l`
nums_propel=`kubectl get svc --namespace=${namespace}|grep propel|wc -l`
if [ ${nums_content} -eq 0 -o ${nums_propel} -eq 0 ]
then
echo "Please check your cluster,IDOL server is starting?"
exit 1
fi

#enter the number of content that you want to sacle.
echo "-----------------------------------------------------------"
echo "--Please enter the number of content that you want to scale--"
echo "-----------------------------------------------------------"
read NUM_scalecontent

if [[ ${NUM_scalecontent} =~ ^[0-9]+$ ]]
then
echo  "the NUMBER of content is ${NUM_scalecontent}."
else
echo "the type of ${NUM_scalecontent} is not int."
exit 1
fi

#create content yaml and start service
while [ ${NUM_scalecontent} \> 0 ]
do
SUM_content=$(( ${nums_content} + ${NUM_scalecontent} ))
if [ ! -d ${NFSpath}/config/idol/content${SUM_content} ]
then
mkdir ${NFSpath}/config/idol/content${SUM_content}
else
echo "the directory is exist."
fi
cp content1/* ${NFSpath}/config/idol/content${SUM_content}

if [ -d ./scaled ]
then
echo "the scaled directory is EXIST."
else
mkdir scaled
fi

cat sm-idol-contentscale-rc.yaml > scaled/sm-idol-content${SUM_content}-rc.yaml
sed -i s/\$\{namespace\}/${namespace}/g scaled/sm-idol-content${SUM_content}-rc.yaml
sed -i s/\$\{NUM_content\}/${SUM_content}/g scaled/sm-idol-content${SUM_content}-rc.yaml
kubectl create -f scaled/sm-idol-content${SUM_content}-rc.yaml
echo "-----------------------------------------------------------"
echo "-------The HOST: sm-idol-content${SUM_content}-svc---------"
echo "--------------The PORT: 10010------------------------------"
echo "-----------------------------------------------------------"
NUM_scalecontent=$(( ${NUM_scalecontent} - 1 ))
sleep 3
done

#create conpropel yaml and start service
echo "--------------------------------------------------------------------"
echo "--Please enter the number of content-propel that you want to scale--"
echo "--------------------------------------------------------------------"
read NUM_scaleconpropel
if [[ ${NUM_scaleconpropel} =~ ^[0-9]+$ ]]
then
echo  "the NUMBER of content is ${NUM_scaleconpropel}."
else
echo "the type of ${NUM_scaleconpropel} is not int."
exit 1
fi

while [ ${NUM_scaleconpropel} \> 0 ]
do
SUM_conpropel=$(( ${nums_propel} + ${NUM_scaleconpropel} ))
if [ ! -d ${NFSpath}/config/idol/contentPropel${SUM_conpropel} ]
then
mkdir ${NFSpath}/config/idol/contentPropel${SUM_conpropel}
else
echo "the directory is exist."
fi
cp contentPropel/* ${NFSpath}/config/idol/contentPropel${SUM_conpropel}

if [ -d ./scaled ]
then
echo "the scaled directory is EXIST."
else
mkdir scaled
fi
cat sm-idol-conpropelscale-rc.yaml > scaled/sm-idol-conpropel${SUM_conpropel}-rc.yaml
sed -i s/\$\{namespace\}/${namespace}/g scaled/sm-idol-conpropel${SUM_conpropel}-rc.yaml
sed -i s/\$\{NUM_content\}/${SUM_conpropel}/g scaled/sm-idol-conpropel${SUM_conpropel}-rc.yaml
kubectl create -f scaled/sm-idol-conpropel${SUM_conpropel}-rc.yaml
echo "-----------------------------------------------------------"
echo "-------The HOST: sm-idol-conpropel${SUM_conpropel}-svc-----"
echo "--------------The PORT: 10010------------------------------"
echo "-----------------------------------------------------------"
NUM_scaleconpropel=$(( ${NUM_scaleconpropel} - 1 ))
sleep 3
done

echo "the progrom is over."
