#!/bin/bash
for line in $(cat hostname.txt)
do
echo "===================================$line Status===================================================="
ping -c 3 -w 5 $line >/dev/null 2>&1
if [[ $? == 0 ]];then
/usr/tcl/bin/expect -c "
spawn scp get.sh root@$line:/root
expect {
\"*assword\" {set timeout 300; send \"iso*help\r\";}
\"yes/no\" {send \"yes\r\"; exp_continue;}
};
expect eof
spawn ssh root@$line \"./get.sh\"
expect {
\"*assword\" {set timeout 300; send \"iso*help\r\";}
\"yes/no\" {send \"yes\r\"; exp_continue;}
};
expect eof"
else
echo "$line can not connect."
continue
fi
echo "===================================$line Status End================================================="
sleep 20
done
