#!/bin/bash
sleep 20
docker run -d --name postgresql_database -e POSTGRESQL_USER=sysadmin -e POSTGRESQL_PASSWORD=Admin_1234 -e POSTGRESQL_DATABASE=db -p 54321:5432 leopardxu/pgsql:9.5.9
docker cp run.sh postgresql_database:/opt/app-root/src
sleep 10
docker exec -i postgresql_database ./run.sh

