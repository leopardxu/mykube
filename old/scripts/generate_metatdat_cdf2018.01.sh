#!/bin/bash

set -e
helpinfo(){
echo "-u     github url of suite-data, default https://github.houston.softwaregrp.net/SMA-RnD/itsma-suite-data.git"
echo "-t     tag or branch of suite-data, default master"
exit 0

}

while getopts ":u:t:" opt; do
case $opt in
	u)
	SUITE_DATE_URL=$OPTARG
	;;
	t)
	SUIET_DATA_TAG=$OPTARG
	;;
	*)
	helpinfo
	;;
esac

done
if [ -z ${SUITE_DATE_URL} ] ;then
	SUITE_DATE_URL="https://github.houston.softwaregrp.net/SMA-RnD/itsma-suite-data.git"
fi

if [ -z ${SUIET_DATA_TAG} ]; then
	SUIET_DATA_TAG="master"
fi

echo "start clone suite-data code form github..."
git clone ${SUITE_DATE_URL} 

if [ $? -ne 0 ]; then
	echo "Get suite-data failed."

fi

#check out branch or tag
cd itsma-suite-data
git checkout ${SUIET_DATA_TAG} 

    cd itsma/config 
    mv feature/ suite_feature 
    mkdir itsma 
    mv suite_feature/* itsma/ 
    mv itsma/ suite_feature/ 
    sed  -i '/"suite": "itsma",/i\    "suiteInfoList": [{' suiteinfo.json 
    sed -i '$ a\]}' suiteinfo.json 
    for i in `ls ./suite_feature/itsma/ `; do cat ./suite_feature/itsma/$i/itsma_suitefeatures.$i.json |jq '.images = [{"image": "heapster:v1.4.3"}]' |jq '.feature_sets[].images = [{"image": "heapster:v1.4.3"}]' > tmp.$$.json && mv -f tmp.$$.json ./suite_feature/itsma/$i/itsma_suitefeatures.$i.json; done 
    tar -zcf meta-data.tar.gz * 
    mv meta-data.tar.gz ../../../meta-data.tar.gz


