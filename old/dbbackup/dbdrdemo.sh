#!/bin/bash
DBROOTPATH=/var/vols/itom/itsma/itsma-itsma-db/db
#NAMESPA=`kubectl get pods --all-namespaces -o=custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name --no-headers |grep auth|head -n 1|awk '{print $1}'`
NAMESPA=`kubectl get namespaces|grep itsma|head -n 1|awk '{print $1}'`
datest=`date +%Y%m%d%H%M`
YAMLPATH=/var/vols/itom/core/suite-install/itsma/output
dbpreback()
{
  for dbpath in ${DBROOTPATH}/*
  do
    echo "db ${dbpath}"
    addline "max_wal_senders = 4" ${dbpath}/postgresql.conf
    addline "max_replication_slots = 4" ${dbpath}/postgresql.conf
    addline "wal_level = 'hot_standby'" ${dbpath}/postgresql.conf
    addrepl ${dbpath}/pg_hba.conf 
  done
}

addrepl()
{
  para=`grep repl $1|grep "^local"`
  if [ -z "${para}" ]; then 
    echo "local replication repl_user  trust" >> $1
  fi
}

addline()
{
   para=`echo $1|awk -F'=' '{split($0,a,"=");printf("%s", a[1])}'`
   if [ -z ${para} ]; then 
     echo "You need import the line like "max_wal_senders = 4""
     return;
   fi
   llnum=`sed -n "/^${para}/=" $2|head -n 1`
   if [ -z ${llnum} ]; then
     echo $1 >> $2
   else
     sed -i "$llnum d" $2 
     echo $1 >> $2
   fi
}

podStop()
{
   if  [[ $1 == *rabbit* ]]; then
     kubectl scale statefulset pro-rabbitmq -n ${NAMESPA} --replicas=0
     kubectl scale statefulset infra-rabbitmq -n ${NAMESPA} --replicas=0
     return
   elif [[ $1 == *postg* ]]; then
     deployments=(`kubectl get deployment -n ${NAMESPA} -o=custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name --no-headers  |grep $1|grep -v aplm|awk '{print $2}'`)
   else 
     deployments=(`kubectl get deployment -n ${NAMESPA} -o=custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name --no-headers  |grep $1|grep -v ui|grep -v post|awk '{print $2}'`)
   fi

   if [ ${#deployments[@]} -eq 0 ]; then 
     echo "There is no deployment for $1!"
   fi
   for((i=0;i<${#deployments[@]};i++))
   do
        kubectl scale deployment ${deployments[i]} -n ${NAMESPA} --replicas=0
   done
}

podStart()
{
   if  [[ $1 == *rabbit* ]]; then
     kubectl scale statefulset pro-rabbitmq -n ${NAMESPA} --replicas=1
     kubectl scale statefulset infra-rabbitmq -n ${NAMESPA} --replicas=1
     return
   elif [[ $1 == *postg* ]]; then
     deployments=(`kubectl get deployment -n ${NAMESPA} -o=custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name --no-headers  |grep $1|awk '{print $2}'`)
   else 
     deployments=(`kubectl get deployment -n ${NAMESPA} -o=custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name --no-headers  |grep $1|grep -v ui|grep -v post|awk '{print $2}'`)
   fi
 
   if [ ${#deployments[@]} -eq 0 ]; then 
     echo "There is no deployment for $1!"
   fi
   for((i=0;i<${#deployments[@]};i++))
   do
        kubectl scale deployment ${deployments[i]} -n ${NAMESPA} --replicas=1
   done
}

stopAll()
{
  podStop itom-xruntime-platform 
  podStop itom-bo-license 
  podStop itom-bo-config 
  podStop itom-bo-ats 
  podStop itom-bo-user 
  podStop idm
  podStop ucmdb
#for H
  podStop propel
  podStop rte
  podStop sm-chat
}

stopSystem()
{
  deployments=(`kubectl get deployment -n ${NAMESPA} -o=custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name --no-headers  |awk '{print $2}'`)
  for((i=0;i<${#deployments[@]};i++))
  do
       kubectl scale deployment ${deployments[i]} -n ${NAMESPA} --replicas=0
  done
  kubectl scale statefulset pro-rabbitmq -n ${NAMESPA} --replicas=0
  kubectl scale statefulset infra-rabbitmq -n ${NAMESPA} --replicas=0
}

startSystem()
{
  podStop gossip
  kubectl scale statefulset pro-rabbitmq -n ${NAMESPA} --replicas=1
  kubectl scale statefulset infra-rabbitmq -n ${NAMESPA} --replicas=1
  deployments=(`kubectl get deployment -n ${NAMESPA} -o=custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name --no-headers  |awk '{print $2}'`)
  echo deployments
  for((i=0;i<${#deployments[@]};i++))
  do
       kubectl scale deployment ${deployments[i]} -n ${NAMESPA} --replicas=1
  done

}

startAll()
{
  podStart itom-xruntime-platform 
  podStart itom-bo-license 
  podStart itom-bo-user 
  podStart itom-bo-config 
  podStart itom-bo-ats 
  podStart idm
  podStart propel
  podStart ucmdb
#for H
  podStart propel
  podStart rte
  podStart sm-chat
}

smStop()
{
   podStop sm-rte
}

smStart()
{
   podStart sm-rte
}

idmStop()
{
   podStop idm
}

idmStart()
{
   podStart idm
}

propelStop()
{
   echo "Stop Propel before backup propeldb!"
   podStop propel
}

propelStart()
{
   echo "Start Propel before backup propeldb!"
   podStart propel
}

dbStop()
{
   podStop postgres
}

dbStart()
{
   podStart postgres
}

lwssoPodsStart()
{
  cd $YAMLPATH
  pwd
  find */yamls -name itom-chat-svc.yaml|xargs kubectl create -f    
  find */yamls -name sm-rte.yaml|xargs kubectl create -f    
  find */yamls -name sm-rte-integration.yaml|xargs kubectl create -f    
  find */yamls -name sm-webtier.yaml|xargs kubectl create -f    
  find */yamls -name itom-idm-deployment.yaml|xargs kubectl create -f    
  find */yamls -name ucmdb-suite-browser.yaml|xargs kubectl create -f    
  find */yamls -name ucmdb-suite-server.yaml|xargs kubectl create -f    
}

lwssoPodsStop()
{
  cd $YAMLPATH
  pwd
  find */yamls -name itom-chat-svc.yaml|xargs kubectl delete -f    
  find */yamls -name sm-rte.yaml|xargs kubectl delete -f    
  find */yamls -name sm-rte-integration.yaml|xargs kubectl delete -f    
  find */yamls -name sm-webtier.yaml|xargs kubectl delete -f    
  find */yamls -name itom-idm-deployment.yaml|xargs kubectl delete -f    
  find */yamls -name ucmdb-suite-browser.yaml|xargs kubectl delete -f    
  find */yamls -name ucmdb-suite-server.yaml|xargs kubectl delete -f    
}

genSQL()
{
cat >execSQL.sh <<ECHOCMD
#!/bin/bash
  res=\`psql -U postgres -c "SELECT * FROM pg_roles WHERE rolname='repl_user'"|grep "1 row"\`
  if [ -z "\${res}" ]; then
    echo "CREATE ROLE repl_user LOGIN REPLICATION..."
    psql -U postgres -c "CREATE ROLE repl_user LOGIN REPLICATION PASSWORD 'replpassword';"
  fi
  res1=\`psql -U postgres -c "SELECT * FROM pg_replication_slots WHERE slot_name='dbdrdemo'"|grep "1 row"\`
  if [ -z "\${res1}" ]; then
    echo "CREATE PHYSICAL REPLICATION SLOT..."
    psql -U postgres -c "SELECT pg_create_physical_replication_slot('dbdrdemo');"
  fi
ECHOCMD
chmod +x ./execSQL.sh

cat >execBackup.sh <<ECHOCMD
#!/bin/bash
rm -rf /tmp/dbbackup
pg_basebackup -U repl_user -X stream -D /tmp/dbbackup
ECHOCMD
chmod +x ./execBackup.sh
}

doBackup()
{
  if  [ ! -d "/tmp/dbbackup/${datest}" ]; then
    mkdir -p /tmp/dbbackup/${datest}
  fi
  cd  /tmp/dbbackup/${datest}
  genSQL
  for containerName in `kubectl describe pod $1 -n ${NAMESPA} | sed -n '/Container\ ID/{x;p};h' | grep -v install | grep -v vault | grep -v depend| sed 's/://g' | sed 's/\ \ //g'`
  do
  echo "pod is $1, containerName is ${containerName}"
  kubectl cp ./execSQL.sh ${NAMESPA}/$1:/tmp/execSQL.sh -c ${containerName}
  kubectl cp ./execBackup.sh ${NAMESPA}/$1:/tmp/execBackup.sh -c ${containerName}
  echo "copy finish"
  kubectl exec $1 -it -n ${NAMESPA} -c ${containerName} /tmp/execSQL.sh
  kubectl exec $1 -it -n ${NAMESPA} -c ${containerName} /tmp/execBackup.sh
  rm -rf dbbackup
  kubectl cp ${NAMESPA}/$1:/tmp/dbbackup /tmp/dbbackup/${datest}/dbbackup -c ${containerName}
  tar -czf $2.tar.gz dbbackup
  done
}

dbBackup()
{
 if [ -z $1 ]; then
   echo "To back all databases."
   pods=(`kubectl get pods -n ${NAMESPA} -o=custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name --no-headers |grep "post"|awk '{print $2}'`)
 else 
   echo "To back $1 database."
   pods=(`kubectl get pods -n ${NAMESPA} -o=custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name --no-headers |grep "post"|grep $1|awk '{print $2}'`)
 fi

 for((i=0;i<${#pods[@]};i++))
  do
      case ${pods[i]} in 
      "idm-postgresql"*) doBackup ${pods[i]} "idm-postgresql";;
      "itom-bo-postgres"*) doBackup ${pods[i]} "itom-bo-postgres";;
      "itom-xruntime-postgres"*) doBackup ${pods[i]} "itom-xruntime-postgres";;
      "postgresql-ucmdb"*) doBackup ${pods[i]} "postgresql-ucmdb";;
      "smarta-postgres"*) doBackup ${pods[i]} "smarta-postgres";;
##for X
      "itom-xservices-postgres"*) doBackup ${pods[i]} "itom-xservices-postgres";;
      "propel-postgresql"*) doBackup ${pods[i]} "propel-postgresql";;
      "sm-postgres"*) doBackup ${pods[i]} "sm-postgres";;
      *) echo noting ;;
     esac
  done
}
setvalutdbpasswd()
{
    suite_mode=`kubectl get cm itsma-common-configmap -n ${NAMESPA} -o yaml|grep itom_suite_mode|grep H_MODE`
    if [ -z "${suite_mode}" ]; then
       echo "This is a X_MODE suite. Please use other tool to set db password in vault. "
       return
    fi
    podname=(`kubectl get pods -n ${NAMESPA} -o=custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name --no-headers|grep "itom-itsma-config"|head -n 1|awk '{print $2}'`)
    echo "pod is ${podname}"
    passwdname=""
    case $1 in
    "idm"|"itom-idm"|"itom-idm-db") passwdname=itom-idm;;
    "cmdb"|"ucmdb"|"itom-cmdb"|"itom-cmdb-db") passwdname=itom-cmdb;;
    "sm"|"sm-db"|"itom-sm"|"sm-chat") passwdname=itom-sm;;
    "propel"|"propel-db") passwdname=itom-service-portal;;
    "xservice"|"xservice-db") passwdname=itom-xservices-infra;;
     *) echo nothing ;;
    esac
    echo "passwd name is ${passwdname}"
    if [ ! "" = "\${passwdname}" ]; then
      passwd=`kubectl exec -it ${podname} -n ${NAMESPA} -c config get_secret itom_itsma_db_password_secret_key ${passwdname}`
      echo "old passwd is ${passwd}"
      echo "new passwd is $2"
      kubectl exec -it ${podname} -n ${NAMESPA} -c config update_secret itom_itsma_db_password_secret_key $2 ${passwdname} >/dev/null 2>&1
    else
      echo "To change idm db password           : ./dbdrdemo.sh setvdbpasswd idm <new password>"
      echo "To change cmdb db password          : ./dbdrdemo.sh setvdbpasswd cmdb <new password>"
      echo "To change sm db password            : ./dbdrdemo.sh setvdbpasswd sm <new password>"
      echo "To change service portal db password: ./dbdrdemo.sh setvdbpasswd propel <new password>"
      echo "To change xservice db password      : ./dbdrdemo.sh setvdbpasswd xservice <new password>"
    fi

}
printUsage ()
{
cat << END_HELP

NAME
    dbdrdemo.sh

DESCRIPTION
    This shell script is used to backup the contained postgreSQL data. The user running this script must be the root user. 
    For the first time backup, you need go through Step 1 to Step 4. Later you can only run Step 4 to implement the db backup.
    Step1. Run #./dbdrdemo.sh dbpreback.
    Step2. Run #./dbdrdemo.sh dbstop. Then check all postgres pods are shutdown. Then go to next step.
    Step3. Run #./dbdrdemo.sh dbstart. Wait until all the postgres db pods are running up.
    Step4. Run #./dbdrdemo.sh dbbackup. All backup files will be kept in /tmp/backup/YYYYMMDDHHMMSS.
    Good luck!

OPTIONS
    dbpreback             #To prepare the db to be ready to be backup. Run #./dbdrdemo.sh dbpreback.
    dbstop                #To shutdow all db pods. Run #./dbdrdemo.sh dbstop.
    dbstart		  #To startup all db pods. Run #./dbdrdemo.sh dbstart.
    dbbackup              #To backup all db or specified db. #dbdrdemo.sh dbbackup idm.
    start                 #To start the pod. For example, #dbdrdemo.sh start idm.
    stop                  #To stop the pod. For example, #dbdrdemo.sh stop idm.
    startsystem           #To stop all pods.  Run #./dbdrdemo.sh startsystem.
    stopsystem            #To start all pods.  Run #./dbdrdemo.sh stopsystem.
    setvdbpasswd          #To set db passwd in vault. For example: #./dbdrdemo.sh setvdbpasswd <idm> <Idm_1234>
END_HELP
}

DEBUG=""
CMD=""
if [ $# -eq 0 ]; then
    printUsage
fi
while  [ $# -gt 0 ]; do
    arg="$1"
    shift
    case "$arg" in
    'dbpreback')
      dbpreback;;
    'dbstop')
       dbStop;;
    'dbstart')
       dbStart;;
    'dbbackup')
       dbBackup $1
       break;;
    'start')
       podStart $1
       break;;
    'stop')
       podStop $1
       break;;
    'setvdbpasswd')
       setvalutdbpasswd $1 $2
       break;;
    'startsystem')
       startSystem
       break;;
    'stopsystem')
       stopSystem
       break;;
    *)
        printUsage
        echo "Please check your command!"
        exit 1;;
    esac
done
