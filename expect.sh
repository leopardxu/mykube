#!/bin/bash
/usr/tcl/bin/expect -c "
spawn ssh root@xxxxxxx \"kubectl get events --all-namespaces;kubectl get pod --all-namespaces|grep -v Running;kubectl describe node | awk '/^Name/;/^\ \ CPU/,/\)$/ {print}'\"
expect {
\"*assword\" {set timeout 300; send \"*******\r\";}
\"yes/no\" {send \"yes\r\"; exp_continue;}
};

expect eof"


#!/usr/tcl/bin/expect -f  
 set ip [lindex $argv 0 ]
 #set password [lindex $argv 1 ]  
# set command [lindex $argv 2 ]  
 set timeout 10
 #spawn ssh root@$ip \"[lindex $argv 2 ];\" 
 spawn ssh root@$ip
 expect {
 "*yes/no" { send "yes\r"; exp_continue}
 "*password:" { send "iso*help\r" }
 }
expect "#*"
send "ls\r"
send "exit\r"
expect eof

