#!/bin/bash
echo "Please enter the number of records to be indexed into xxxx,the unit is MILLION."

read Record_Number
if [[ ${Record_Number} =~ ^[0-9]+$ ]]
then
	echo  "the NUMBER is ${Record_Number} million."
else
	echo "the type of ${Record_Number} is not int."
	exit 1
fi
echo "Please enter the number of Concurrent user."

read Concurrent_User
if [[ ${Concurrent_User} =~ ^[0-9]+$ ]]
then
        echo  "the NUMBER of concurrent_user is ${Concurrent_User}."
else
        echo "the type of ${Concurrent_User} is not int."
        exit 1
fi
sed -ri "/RECORD_NUMBER/{n;s/[0-9]+/${Record_Number}/}" svc.yaml
sed -ri "/CONCURRENT_USER/{n;s/[0-9]+/${Concurrent_User}/}" svc.yaml

echo "SUCCES."

