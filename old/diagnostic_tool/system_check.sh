#!/bin/bash

#set -x

usage(){
    echo "Usage: $0 -l|--logfile <filename of precheck log> "
    echo "  Example: $0 -l system-check.log"
    exit 1;
}

logfile="/tmp/system-check-`date "+%Y%m%d%H%M%S"`.log"
MIN_DISK=30
RED='\033[0;31m'
Yellow='\033[0;33m'
NC='\033[0m'
logfile=Syscheck.log

while [ "$1" != "" ]; do
    case $1 in
      -l|--logfile)
        logfile=$2
        shift 2
        ;;
      *) usage ;;
    esac
done

log() {
    level=$1
    msg=$2
    exitCode=1
    if [[ ! -z $3 ]] ; then
        exitCode=$3
    fi
    case $level in
        debug)
            echo "[DEBUG]   `date "+%Y-%m-%d %H:%M:%S"` : $msg  " >> $logfile ;;
        info)
            echo "$msg"
            echo "[INFO]    `date "+%Y-%m-%d %H:%M:%S"` : $msg  " >> $logfile ;;
        error)
            echo "$msg"
            echo "[ERROR]   `date "+%Y-%m-%d %H:%M:%S"` : $msg  " >> $logfile ;;
        warn)
            echo "$msg"
            echo "[WARN]    `date "+%Y-%m-%d %H:%M:%S"` : $msg  " >> $logfile ;;
        begin)
            echo "$msg  " >> $logfile ;;
        end)
            echo "$msg  " >> $logfile ;;
        fatal)
            echo "$msg"
            echo "[FATAL]   `date "+%Y-%m-%d %H:%M:%S"` : $msg  " >> $logfile
            echo "[INFO]    `date "+%Y-%m-%d %H:%M:%S"` : Please refer to the Troubleshooting section in suite help center for help on how to resolve this error.  " >> $logfile
            exit ${exitCode}
            ;;
        summary)
            echo "[WARN]    : $msg "  >> /tmp/${logfile}_tmp ;;
        *)
            echo "$msg"
            echo "[INFO] `date "+%Y-%m-%d %H:%M:%S"` : $msg  " >> $logfile ;;
    esac
}

check_k8s_home(){
	if [[ -z $K8S_HOME ]]; then
        log "error" "K8S_HOME does not exist. Check if Kubernetes is installed successfully."
    else
    	log "debug" "Find Kubernetes installation folder here: $K8S_HOME"
	fi
}

get_local_info(){
    local_ipaddress=`hostname -I |cut -f1 -d " "`    
    local_hostname=`hostname -f`
    if [[ -z $local_ipaddress ]]; then
      log "error" "Cannot find local IP address"
    else
      log "debug" "Local IP is $local_ipaddress"
    fi

    if [[ -z $local_hostname ]]; then
      log "error" "Cannot find local hostname"
    else
      log "debug" "Local hostname is $local_hostname"
    fi
    
}

getVaildDir() {
    local cur_dir=$1

    if [ -z $cur_dir ]
    then
        return 1
    fi

    if [ -d $cur_dir ]
    then
        echo $cur_dir
    else
        echo $(getVaildDir $(dirname $cur_dir))
    fi
}

checkDisk() {
    if [[ ! -z $K8S_HOME ]]; then
        local k8s_basedir=$(getVaildDir $K8S_HOME)
    elif [[ $is_nfs_server == true ]]; then
        local k8s_basedir=$(getVaildDir $NFS_FOLDER)
    else
            local k8s_basedir=$(getVaildDir /)
    fi        
    # local local_disk=$(df --si -m --direct $k8s_basedir|sed '1d'|awk '{printf "%.2f", $4/1000}')
    local available_disk=$(timeout 2s df -m $k8s_basedir|sed '1d'|awk '{printf "%.2f", $4/1024}')
    local mount_point=$(timeout 2s df $k8s_basedir|sed '1d'|awk '{print $6}')

    log "info" "Free disk:      $available_disk GB"
    if [ $(echo "$available_disk $MIN_DISK"|awk '{print $1<$2}') = 1 ]
    then
        log "summary" "Free disk: $available_disk GB is not enough. $MIN_DISK GB free hard disk is required."
    fi
}


get_master_ip(){
    master_ip=` ps -ef |grep flannel | grep -v grep |awk 'BEGIN{FS="https://"}{printf $2}'|awk 'BEGIN{FS=":"}{printf $1}'`
    if [[ -z master_ip ]]; then
      log "error" "Check if flannel is started."
    else
      log "debug" "Master IP is $master_ip"
    fi
}

check_is_master(){
    get_local_info
    get_master_ip
    NodeType=NULL

    if [[ ! -z $K8S_HOME ]]; then
        if [[ "$local_ipaddress" == "$master_ip" ]]; then
            log "debug" "Current system is Master"
            NodeType=Master
        elif [[ "$local_hostname" == "$master_ip" ]]; then 
            log "debug" "Current system is Master"
            NodeType=Master
        else
            log "debug" "Current system is Worker"
            NodeType=Worker
        fi
    elif [[ $is_nfs_server == true ]]; then
            log "debug" "Current system is NFS"
            NodeType=NFS
    fi
}


check_service(){
    service_name=$1
    status=dead
    status=`systemctl status $service_name |grep Active|awk 'BEGIN{FS="("}{print $2}'|awk 'BEGIN{FS=")"}{print $1}'`
    log "info" "Checking $service_name ............ $status"
    if [[ $service_name == firewalld ]] && [[ $status != dead ]]; then
        log "summary" "Firewall is not disabled. Run 'systemctl stop $service_name'"
    fi
    if [[ $service_name == chronyd.service ]] && [[ $status == dead ]]; then
        log "summary" "Data time is not synchronized. Run 'systemctl start $service_name'"
    elif [[ $service_name == docker.service ]] && [[ $status != running ]]; then
        log "summary" "Service [$service_name] error [$status]. Run 'journalctl -u $service_name' for details"
    elif [[ $status != running ]] && [[ $service_name != firewalld ]] ; then
        log "summary" "Service [$service_name] error [$status]. Run 'systemctl start $service_name'"
    fi
    
}


checkNFSExports(){
    #check if NFS server export the folder.
    local CA_FILE=$PEER_CA_FILE
    local CERT_FILE=$PEER_CERT_FILE
    local KEY_FILE=$PEER_KEY_FILE
    local TMP_FOLDER=/tmp/cdf_nfs_readwrite_check
    showmount --all > /dev/null 2>&1
    if [[ $? == 0 ]]; then
        NFS_SERVER=`showmount --all |grep on |cut -f5 -d " " |awk 'BEGIN{FS=":"}{print $1}'`
    else
        NFS_SERVER=""
    fi
    if [[ -f /etc/exports ]]; then
        NFS_FOLDER=`cat /etc/exports |grep core |cut -f1 -d " "`
    else
        NFS_FOLDER=/var/vols/itom/core
    fi
        
    if [[ $(which showmount > /dev/null 2>&1; echo $?) != 0 ]]; then
        is_nfs_server=false
    else
        if [[ ! -z ${NFS_SERVER} ]] && [[ ! -z ${NFS_FOLDER} ]] && \
            [[ $(ping -c 1 -W 3 ${NFS_SERVER} > /dev/null 2>&1 ; echo $?) == 0 ]] ; then
            local res=`showmount -e ${NFS_SERVER}|grep "${NFS_FOLDER} "|wc -l`
            if [[ $res == 0 ]]; then
                is_nfs_server=false
            else
                if [[ ! -d ${TMP_FOLDER} ]]; then
                    mkdir -p ${TMP_FOLDER}
                fi
                if ! grep -qs '${TMP_FOLDER}' /proc/mounts; then
                    umount ${TMP_FOLDER} >/dev/null 2>&1
                    is_nfs_server=true
                fi
            fi
        else
            is_nfs_server=false
        fi
    fi
}

get_node(){
    node_type=$1
    node_name=$2
    label=`kubectl describe node $node_name |grep Worker`
    log "info" "$node_type:  `kubectl get node | grep -m 1 $node_name`"
    log "debug" "$node_name $label"
}


list_worker_node(){
    worker_number=0
    for i in `kubectl get node |grep -v NAME |cut -f1 -d " "`
    do
        if [[ $i != $local_ipaddress ]]; then
            if [[ $i != $local_hostname ]]; then
                get_node Worker $i
                worker_number=`expr $worker_number + 1`
            fi
        fi
    done
    if [[ $worker_number < 2 ]]; then
        log "summary" "Worker node number [$worker_number] is not enough. At least 2 worker nodes are required."
    fi
}

list_master_node(){
    for i in `kubectl get node |grep -v NAME |cut -f1 -d " "`
    do
        if [[ $i == $local_ipaddress ]]; then
                get_node Master $i
        else if [[ $i == $local_hostname ]]; then
                get_node Master $i
            fi
        fi
    done
}

function version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

list_os_version(){
    kernal=`uname -r`
    log "info" "OS kernal: $kernal"
    kernal_version=`echo $kernal | awk 'BEGIN{FS="-"}{print $1}'`
    kernal_version_min=`echo $kernal | awk 'BEGIN{FS="-"}{print $2}' | awk 'BEGIN{FS="."}{print $1}'`
    design_version=3.10.0
    design_verion_min=514
    if version_gt $design_version $kernal_version; then
        log "summary" "Current OS kernal ${kernal_version} is not updated. Please update it to ${design_version}"
    elif version_gt $design_verion_min $kernal_version_min; then
        log "summary" "Current OS kernal patch ${kernal_version}-${kernal_version_min} is not updated. Please update it to ${design_version}-${design_verion_min}"
    fi
}

list_node_type(){
    log "info" "Current system: $NodeType"
    if [[ $is_nfs_server == true ]]; then
        log "info" "Current system: NFS server"
    fi
}

list_k8s_info(){
    log "info" "Kubernets Home: $K8S_HOME"
    log "info" "CDF version   : `cat $K8S_HOME/version.txt`"
}

list_nfs_home(){
    if [[ $is_nfs_server == true ]]; then
        log "info" "NFS Home      : $NFS_SERVER"
    fi
}


list_system_details(){
    net_mask=`ifconfig |grep $local_ipaddress|awk 'BEGIN{FS=" "}{print $4}'`
    broadcast=`ifconfig |grep $local_ipaddress|awk 'BEGIN{FS=" "}{print $6}'`
    cpu_core=`cat /proc/cpuinfo |grep processor |wc -l`
    mem_info=`cat /proc/meminfo  |grep Mem`
    cpu_frq=`cat /proc/cpuinfo | grep name | cut -f9 -d " " | uniq |awk 'BEGIN{FS="GHz"}{print $1}'`
    cpu_type=`cat /proc/cpuinfo | grep name | cut -f3 -d " " | uniq `
    cpu_version=`cat /proc/cpuinfo | grep name | cut -f6 -d " " | uniq |awk 'BEGIN{FS="-"}{print $1}'`
    cpu_version_all=`cat /proc/cpuinfo | grep name | cut -f6 -d " " | uniq`
    cpu_version_min=`cat /proc/cpuinfo | grep name | cut -f6 -d " " | uniq |awk 'BEGIN{FS="-"}{print $1}'|awk 'BEGIN{FS="E"}{print $2}'`
    
    read des gateway genmask <<<　`route |sed -n '3p'`

    log "debug" "List gateway"
    log "debug" "`route`"
    log "debug" "`cat /proc/cpuinfo | grep name | uniq`"
    log "info" "Local  IP:      $local_ipaddress"
    log "info" "Netmask  :      $net_mask"
    log "info" "Broadcast:      $broadcast"
    log "info" "Gateway  :      $gateway"
    log "info" "CPU cores:      $cpu_core"
    log "info" "$mem_info"
    checkDisk
    # 8 CPU cores is mandatory
    if version_gt 8 $cpu_core; then
        log "summary" "CPU Cores($cpu_core) is not enough. 8 core CPU is required."
    fi
    net_mask_ip=`echo $net_mask | awk 'BEGIN{FS="."}{print $4}'`
    #net mask cannot be 255.255.255.255
    if [[ $net_mask_ip == 255 ]]; then
        log "summary" "net_mask is not correct. It cannot be $net_mask"
    fi
    #32 GB memroy is necessary
    memory_size=`cat /proc/meminfo  |grep MemTotal | cut -f8 -d " "`
    if version_gt 32000000 $memory_size; then
        log "summary" "Memory size($memory_size kb) is not enough. 32 GB is necessary."
    fi
    #CPU frequency should be larger than 2.20
    if version_gt 2.20 $cpu_frq; then
      log "summary" "CPU frequency (${cpu_frq}GHz) is not as expected. Use 2.3 GHz or above."
    fi
    #CPU type
    if [[ $cpu_type != Intel\(R\) ]]; then
      log "summary" "CPU type is $cpu_type. Please use Intel(R) CPU."
    fi
    
    #CPU version
    if [[ $cpu_version != E5 ]] && [[ $cpu_version != E6 ]] && [[ $cpu_version != E7 ]]; then
        log "summary" "CPU processor is ${cpu_version_all}. Please use E5 or above."
    fi
   
    log "debug" "Node usage information"
    log "debug" "`kubectl describe node | awk '/^Name/;/^\ \ CPU/,/\)$/ {print}'`"
    log "debug" "nslookup $local_hostname"
    log "debug" "`nslookup $local_hostname`"
    log "debug" "nslookup www.google.com"
    log "debug" "`nslookup www.google.com`"
    log "debug" "cat /etc/hosts"
    log "debug" "`cat /etc/hosts`"
}

check_all_service(){
    check_service firewalld
    check_service kubelet.service
    check_service docker-bootstrap.service
    check_service docker.service
    check_service chronyd.service
    if [[ $is_nfs_server == "true" ]]; then
        check_service rpcbind
    fi
 
}

check_uid(){
    if [[ $is_nfs_server == true ]]; then
        userid=`getent passwd | grep 1999|awk 'BEGIN{FS=":"}{print $1}'`
        uid=`getent passwd | grep 1999|awk 'BEGIN{FS=":"}{print $3}'`
        gid=`getent passwd | grep 1999|awk 'BEGIN{FS=":"}{print $4}'`
        log "info" "Userid:         $userid"
        log "info" "Uid:            $uid"
        log "info" "Gid:            $gid"
        if [[ $uid != 1999 ]]; then
            log "summary" "uid($uid) of $userid is not 1999. The SMA suite cannot be installed successfully."
        fi
    fi
}

check_nfs_folder(){
    if [[ $is_nfs_server = true ]]; then
        for i in `showmount --exports |grep -v "Export list" |cut -f1 -d " "`
        do
            if [[ -z $i ]]; then
                log "Error" "NFS folder $i does not exist"
            else
                uuid=`ls -ld $i | cut -f3 -d " "`
                ggid=`ls -ld $i | cut -f4 -d " "`
                log "info" "Checking $i uid:gid: $uuid:$ggid"
                if [[ $uuid != $userid ]]; then
                    log "summary" "Ownership of NFS server $i is not correct!"
                fi
            fi
        done
    fi
}

get_namespace(){
    NAMESPACE=`kubectl get namespace |grep itsma | cut -f1 -d " "`
}

check_deployer_status(){
   name_space=$1
   if [[ ! -z $name_space ]]; then
        log "info" "Checking deployer pod status under namespace [$name_space]"
        for i in `kubectl get pods -n $name_space --show-all |grep -v Running |grep -v NAME | cut -f1 -d " "`
        do
            read NAME STATE status other <<< "`kubectl get pods $i -n $name_space |grep -v NAME`"
            log "debug" "$name_space     $NAME           $STATE      $status"
            echo -ne "."
            if [[ $status != Completed ]]; then
                log "summary" "Deployer pod(${NAME}) is not correct($status). Run 'kubectl logs $i -n $name_space' for details."
                log "debug" "kubectl logs $i -n $name_space"
                log "debug" "`kubectl logs $i -n $name_space`"
            fi
        done
        log "info" ""            
    fi
}

check_pod_status(){
   name_space=$1
   if [[ ! -z $name_space ]]; then
        log "info" "Checking pod status under namespace [$name_space]"
        log "debug" "`kubectl get pods -n $name_space --show-all -o wide`"
        for i in `kubectl get pods -n $name_space |grep -v NAME | cut -f1 -d " "`
        do
            read NAME STATE status restart_number other <<< "`kubectl get pods $i -n $name_space |grep -v NAME`"
            desired_status=`echo $STATE | awk 'BEGIN{FS="/"}{print $2}'`
            actual_status=`echo $STATE | awk 'BEGIN{FS="/"}{print $1}'`       
            log "debug" "$name_space     $NAME           $STATE      $status      $restart_number"
            echo -ne "."
            if [[ $status != Running ]]; then
                container_id=`kubectl describe pod $i -n $name_space | sed -n '/Container\ ID/{x;p};h' | grep -v install | grep -v vault | sed 's/://g' | sed 's/\ \ //g'`
                log "summary" "pod(${NAME}) is not correct($status). Run 'kubectl describe pods $i -n $name_space' for details."
                log "debug" "kubectl describe pods $i -n $name_space"
                log "debug" "`kubectl describe pods $i -n $name_space`"
                log "debug" "kubectl logs $i -n $name_space -c $container_id"
                log "debug" "`kubectl logs $i -n $name_space -c $container_id`"
            elif [[ $desired_status != $actual_status ]]; then
                container_id=`kubectl describe pod $i -n $name_space | sed -n '/Container\ ID/{x;p};h' | grep -v install | grep -v vault | sed 's/://g' | sed 's/\ \ //g'`
                log "summary" "pod(${NAME}) is not ready($STATE). Wait for a while, or run 'kubectl logs $i -n $name_space -c $container_id' "
                log "debug" "kubectl logs $i -n $name_space -c $container_id"
                log "debug" "`kubectl logs $i -n $name_space -c $container_id`"
            fi
			if version_gt $restart_number 50; then
				log "summary" "pod(${NAME}) was restarted too many times($restart_number). Current status is $status($STATE)"                
			fi
        done
        log "info" ""            
    fi
}

summary(){
    if [[ $NodeType == Master ]]; then
        list_os_version
        list_k8s_info
        list_nfs_home
        list_node_type
        list_system_details
        check_uid
        list_master_node
        list_worker_node
        check_nfs_folder
        check_all_service
        check_deployer_status $NAMESPACE
        check_pod_status core
        check_pod_status $NAMESPACE
    elif [[ $NodeType == Worker ]]; then
        list_os_version
        list_k8s_info
        list_nfs_home
        list_node_type
        list_system_details
        check_uid
        check_nfs_folder
        check_all_service
    elif [[ $NodeType == NFS ]]; then
        list_os_version
        list_nfs_home
        list_node_type
        list_system_details
        check_uid
        check_nfs_folder
        check_service rpcbind
    else
        list_os_version
        list_system_details
    fi
}

checkAll(){
    log "begin" "################### Start ##################"
    check_k8s_home
    checkNFSExports
    check_is_master
    get_namespace
    summary
    log "end" "################### END ##################"
    if [[ -f /tmp/${logfile}_tmp ]]; then
        while IFS= read -r var
        do
            echo -e "${Yellow} $var ${NC}"
            echo -e "${Yellow} $var ${NC}" >> $logfile
        done < /tmp/${logfile}_tmp
        rm -rf /tmp/${logfile}_tmp
    fi
}

source /etc/profile
checkAll
