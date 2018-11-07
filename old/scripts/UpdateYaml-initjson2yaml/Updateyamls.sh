#!/bin/bash
#you need enter your NFS server folder.
cd /var/vols/itom/core/suite-install/itsma/output/
#get yamls need be changed.
needChangeyaml=$(grep pod.beta.kubernetes.io/init-containers */yamls/ -r -n | cut -d : -f1)
#update yamls
for yamlName in ${needChangeyaml}
do
    jsonStartline=$(sed -n "/pod.beta.kubernetes.io\/init-containers/=" ${yamlName})
    jsonEndiline=$(sed -n "/\]'/=" ${yamlName})
    printStartline=$(expr ${jsonStartline} + 1)
    printEndline=$(expr ${jsonEndiline} - 1)
    sed -n "${printStartline},${printEndline}p" ${yamlName}|sed 's/^ *//g' >initJson.json
    echo "initContainers:">NeedInsert.yaml
    #convert json to yaml format.
    ./json2yaml initJson.json| sed "s/^/    /g;s/^    env/  - env/g" >>NeedInsert.yaml
    sed -i -e 's/^/      /g' -e '$d' NeedInsert.yaml
    sed -i.bak -e '/Worker:\ label/r NeedInsert.yaml' -e "${jsonStartline},${jsonEndiline}d" ${yamlName}
    echo "${yamlName} update success."
done
