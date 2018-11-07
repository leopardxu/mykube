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
#kubectl get pod --all-namespaces|grep -v Running
namespace=$(kubectl get namespaces|grep itsma*| awk '{print $1}')
kubectl describe pod -n ${namespace} |grep "\ \ \ \ Image:"| grep -v vault |awk '{print $2}'|sort -n |uniq >imageslist.txt
wget https://raw.github.houston.softwaregrp.net/SMA-RnD/itsma-suite-data/master/itsma/config/feature/2017.11/itsma_suitefeatures.2017.11.json
cat itsma_suitefeatures.2017.11.json | grep itom |cut -d \" -f4 > 201711repolist.txt
for image in $(cat imageslist.txt)
do
imagename=$(echo $image |cut -d / -f 3| cut -d : -f 1)
#newtag is release tag,it need release images list.
newtag=$(cat 201711repolist.txt| grep $imagename:| cut -d : -f 2)
docker pull $image
#newtag=$(cat imageslist.txt| grep $imagename:| cut -d : -f 2)
docker tag $image localhost:5000/hpeswitom/$imagename:$newtag
docker push localhost:5000/hpeswitom/$imagename:$newtag
docker rmi -f $image
echo -e "\n localhost:5000/hpeswitom/$imagename:$newtag is OK. \n"
done
zip -q -r registry.zip /var/vols/itom/core/baseinfra-1.0/PrivateRegistry/docker/registry
echo "you can instsll 2017.11rc version using new images. you need upzip registry.zip to /var/vols/itom/core/baseinfra-1.0/PrivateRegistry/docker/registry in new enviroment."
