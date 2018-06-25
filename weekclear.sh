#! /bin/bash
set -x
oldData=$(data -d "-7 days" "+%Y%m%d")
cd /var/lib/docker/volumes
find . -type d -maxdepth 1 -mtime +7 --exec rm -rf {} \;
