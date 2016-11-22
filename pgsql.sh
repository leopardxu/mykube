#!/bin/bash
psql -U postgres \reviewdb7 -c \\q
if [ $? == 0 ];then
	echo "the DB is exites."
else
	psql -U postgres -c "CREATE ROLE gerrit_test7 PASSWORD '123456' CREATEDB LOGIN;" -q
	psql -U postgres -c "CREATE DATABASE reviewdb7 WITH OWNER=gerrit_test;" -q
fi

