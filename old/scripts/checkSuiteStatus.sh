#!/bin/bash
filePath='/root/checkStatus'
nameSpace=`kubectl get ns |grep itsma |awk '{print $1}'`
printUsage(){

cat << END_HELP

DESCRIPTION
    this shell scruot is used to help check suite status before and after CDF update

OPTIONS
    backup  <fileName  # backup current pod status to fileName
    check   <fileName>   # check deployment status in fileName,exit 0 if status is fine
    compare <fileA> <fileB>  # compare pod list in fileA and fileB,exit 0 when they are the same
   
END_HELP
    exit
}
getPodStatus(){
  
   desFile=$1
   echo "getPodStatus start"
   kubectl get pod  -n $nameSpace > $desFile 
   sed -i '/READY/d' $desFile > desFile
   echo "getPodStatus finish"

}
checkPodStatus(){
  origin_IFS=$IFS
  status=0 # defult status is ready
  IFS=$'\n' 
 srcFile=$1
  echo "this is checking .."
  echo "" > $srcFile.check
  echo "" > $srcFile.check.error
  cat $srcFile | while read LINE
    do
      left=`echo $LINE | awk '{print $2}'| awk -F/ '{print $1} '` 
      right=`echo $LINE | awk '{print $2}'| awk -F/ '{print $2}'` 
      if [ $left -eq $right ]; then
         echo $LINE >> $srcFile.check
      else 
         echo $LINE >> $srcFile.check.error
         status=1 # have one pod is not ready
      fi
    done
 IFS=$origin_IFS
  echo "check is finished"
  if [ $status -eq 1 ];then
   exit 1
  else 
   exit 0
  fi
}

comparePodList(){
  isSame=0 # default 0, compare lists are the same
  oldList=$1
  newList=$2
  oldListLineNum=`cat $oldList | wc -l`
  newListLineNum=`cat $newList | wc -l`
  compareLog=$oldList.$newList.compare.log
  echo "" > $compareLog
  if [ $oldListLineNum -ne $newListLineNum ]; then 
       echo "$newList pod list num is less than $oldList" >> $compareLog
  else 
   cat $oldList | awk 'NF>2{print}'|sort> $oldList.sort
   cat $newList | awk 'NF>2{print}'|sort> $newList.sort
    ####compare every line in file
     for ((i=1;i<=$oldListLineNum;i++))
     do
       old_name=`sed -n "$i,1p" $oldList.sort |awk '{print $1}'| awk -F "-" '{NF-=2;print}'`
       new_name=`sed -n "$i,1p" $newList.sort |awk '{print $1}'| awk -F "-" '{NF-=2;print}'`
       old_ready=`sed -n "$i,1p" $oldList.sort | awk '{print $2}'`
       new_ready=`sed -n "$i,1p" $newList.sort | awk '{print $2}'`
       old_status=`sed -n "$i,1p" $oldList.sort | awk '{print $3}'`
       new_status=`sed -n "$i,1p" $newList.sort | awk '{print $3}'`
      if [ "$old_name" != "$new_name" ] || [ "$old_ready" != "$new_ready" ]||[ "$old_status" != "$new_status" ]; then
         isSame=1 # have one record not the same
         echo "`sed -n "$i,1p" $oldList.sort` in $oldList" >> $compareLog
         echo "`sed -n "$i,1p" $newList.sort` in $newList" >> $compareLog
      fi
     done    
  fi
 #clean unncessary file
   #rm -rf $oldList.sort
   #rm -rf $newList.sort
 echo " compare is finished"
 if [ $isSame -eq 1 ];then
   exit 1
 else
   exit 0
 fi


}

#########main stream #####################
while [ $# -gt 0 ]; do
   arg="$1"
   case $arg in 
   'backup' )
    if [ $# -gt 1 ]; then
       echo "this is backup function"
       getPodStatus $2 
    else 
       printUsage
    fi
    break;;
   'check' )
    if [ $# -gt 1 ]; then
       echo "this is check function"
       checkPodStatus $2
    else
       printUsage
    fi
    break;;
   'compare' )
    if [ $# -gt 2 ]; then
       echo "this is compare function"
       comparePodList $2 $3
    else
       printUsage
    fi
    break;;
    *)
     printUsage
     echo "pls check the usage"
     exit 1;;
    esac
done



