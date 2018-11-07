#!/bin/bash
kubectl delete -f /var/vols/itom/core/suite-install/itsma/output/itom-cmdb-10.40.227/yamls/
kubectl delete -f /var/vols/itom/core/suite-install/itsma/output/itom-service-portal-2.26.0-beta14/yamls/propel-postgres.yaml
#kubectl delete -f /var/vols/itom/core/suite-install/itsma/output/itom-xservices-infra-4.2.1.1485/yamls/itom-xservices-postgres.yaml
kubectl delete -f /var/vols/itom/core/suite-install/itsma/output/itom-sm-9.60.0025.8/yamls/sm-db-rc.yaml
sleep 20s
rm -rf /var/vols/itom/itsma/itsma-itsma-db/db/propel
rm -rf /var/vols/itom/itsma/itsma-itsma-db/db/sm
rm -rf /var/vols/itom/itsma/itsma-itsma-db/db/ucmdb
#rm -rf /var/vols/itom/itsma/itsma-itsma-db/db/xservices
\cp -rf /root/07backup/db/propel /var/vols/itom/itsma/itsma-itsma-db/db/propel 
\cp -rf /root/07backup/db/sm /var/vols/itom/itsma/itsma-itsma-db/db/sm
\cp -rf /root/07backup/db/ucmdb /var/vols/itom/itsma/itsma-itsma-db/db/ucmdb
#\cp -rf /root/07backup/db/xservices /var/vols/itom/itsma/itsma-itsma-db/db/xservices
chown -R itsma:itsma /var/vols/itom/itsma/itsma-itsma-db/db/
chmod 700 /var/vols/itom/itsma/itsma-itsma-db/db/propel
chmod 700 /var/vols/itom/itsma/itsma-itsma-db/db/sm
chmod 700 /var/vols/itom/itsma/itsma-itsma-db/db/ucmdb
#chmod 700 /var/vols/itom/itsma/itsma-itsma-db/db/xservices
kubectl create -f /var/vols/itom/core/suite-install/itsma/output/itom-cmdb-10.40.227/yamls/
kubectl create -f /var/vols/itom/core/suite-install/itsma/output/itom-service-portal-2.26.0-beta14/yamls/propel-postgres.yaml
#kubectl create -f /var/vols/itom/core/suite-install/itsma/output/itom-xservices-infra-4.2.1.1485/yamls/itom-xservices-postgres.yaml
kubectl create -f /var/vols/itom/core/suite-install/itsma/output/itom-sm-9.60.0025.8/yamls/sm-db-rc.yaml
echo "        ===================for SM====================================
              wait sm-rte is READY.
      ==================for propel=======================================
              1. wait postgresql is OK.
              kubectl delete -f /var/vols/itom/core/suite-install/itsma/output/itom-service-portal-2.26.0-beta14/yamls/propel-rabbitmq.yaml
              kubectl delete -f /var/vols/itom/core/suite-install/itsma/output/itom-service-portal-2.26.0-beta14/yamls/propel-portal.yaml
              kubectl delete -f /var/vols/itom/core/suite-install/itsma/output/itom-service-portal-2.26.0-beta14/yamls/propel-diagnostics.yaml
              kubectl delete -f /var/vols/itom/core/suite-install/itsma/output/itom-service-portal-2.26.0-beta14/yamls/propel-launchpad.yaml
              kubectl delete -f /var/vols/itom/core/suite-install/itsma/output/itom-service-portal-2.26.0-beta14/yamls/propel-catalog.yaml
              kubectl delete -f /var/vols/itom/core/suite-install/itsma/output/itom-service-portal-2.26.0-beta14/yamls/propel-catalog-ui.yaml
              kubectl delete -f /var/vols/itom/core/suite-install/itsma/output/itom-service-portal-2.26.0-beta14/yamls/propel-sx.yaml
              kubectl delete -f /var/vols/itom/core/suite-install/itsma/output/itom-service-portal-2.26.0-beta14/yamls/propel-sx-ui.yaml
              kubectl delete -f /var/vols/itom/core/suite-install/itsma/output/itom-service-portal-2.26.0-beta14/yamls/propel-sx-client-ui.yaml
              kubectl create -f /var/vols/itom/core/suite-install/itsma/output/itom-service-portal-2.26.0-beta14/yamls/propel-rabbitmq.yaml
              sleep 10s
              kubectl create -f /var/vols/itom/core/suite-install/itsma/output/itom-service-portal-2.26.0-beta14/yamls/propel-portal.yaml
              sleep 10s
              kubectl create -f /var/vols/itom/core/suite-install/itsma/output/itom-service-portal-2.26.0-beta14/yamls/propel-diagnostics.yaml
              sleep 10s
              kubectl create -f /var/vols/itom/core/suite-install/itsma/output/itom-service-portal-2.26.0-beta14/yamls/propel-launchpad.yaml
              sleep 10s
              kubectl create -f /var/vols/itom/core/suite-install/itsma/output/itom-service-portal-2.26.0-beta14/yamls/propel-catalog.yaml
              sleep 10s
              kubectl create -f /var/vols/itom/core/suite-install/itsma/output/itom-service-portal-2.26.0-beta14/yamls/propel-catalog-ui.yaml
              sleep 10s
              kubectl create -f /var/vols/itom/core/suite-install/itsma/output/itom-service-portal-2.26.0-beta14/yamls/propel-sx.yaml
              sleep 10s
              kubectl create -f /var/vols/itom/core/suite-install/itsma/output/itom-service-portal-2.26.0-beta14/yamls/propel-sx-ui.yaml
              sleep 10s
              kubectl create -f /var/vols/itom/core/suite-install/itsma/output/itom-service-portal-2.26.0-beta14/yamls/propel-sx-client-ui.yaml
              3. Login propel/launchpad to Re-customize your modification on content packs.
              4. Login propel/launchpad to modify supplier information if necessary.
              5. Restart propel-sx.yaml.
              6. restart all pod are not ready.
      ===================for ucmdb=========================================
              1. wait postgresql is OK.
              2. restart all ucmdb pod from yaml file.
      ======================================================================"
read -p "end the process:Y/N" verify
if [[ ${verify} == "Y" ]];then
echo "Done."
fi

