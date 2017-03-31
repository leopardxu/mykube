#!/bin/bash
/usr/tcl/bin/expect -c "
spawn ssh root@pr02-master.hpeswlab.net \"kubectl get events --all-namespaces;kubectl get pod --all-namespaces|grep -v Running;kubectl describe node | awk '/^Name/;/^\ \ CPU/,/\)$/ {print}'\"
expect {
\"*assword\" {set timeout 300; send \"*******\r\";}
\"yes/no\" {send \"yes\r\"; exp_continue;}
};

expect eof"
