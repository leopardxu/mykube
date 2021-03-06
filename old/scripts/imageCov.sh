#!/bin/bash
#set -x
FILENAME=$(date +"%y%m%d")
if [ -d /home/admin/imagecover/ ];then
    touch /home/admin/imagecover/${FILENAME}.txt
else
    mkdir -p /home/admin/imagecover/
    touch /home/admin/imagecover/${FILENAME}.txt
fi
ROOTPATH=/data/registry/docker/registry/v2/repositories/itsma/
FIRSTPATH=/_manifests/tags/
SECONDPATH=/index/sha256/
for IMAGENAME in $(cat imagelist.tt)
do
    cd $ROOTPATH$IMAGENAME$FIRSTPATH
    LATESTTAG=$(ls -lt|grep ^d|awk '{print $NF}'|grep "\."|head -n1)
    cd $LATESTTAG$SECONDPATH    NUMBER=$(ls -lt|grep ^d|wc -l)
    if [ ${NUMBER} -gt 1 ];then
        let "COVERNUMBER=${NUMBER} - 1"
        echo "$IMAGENAME:$LATESTTAG have ${COVERNUMBER} cover.">>/home/admin/imagecover/${FILENAME}.txt
    fi
done

