#!/bin/bash
echo "this software must run kubernetes above 1.8."
#echo "http_proxy=http://web-proxy.corp.hpecorp.net:8088">>/etc/profile
#echo "https_proxy=http://web-proxy.corp.hpecorp.net:8088">>/etc/profile
#echo "export http_proxy https_proxy">>/etc/profile
#source /etc/profile
curl https://run.conduit.io/install | sh
echo "export PATH=$PATH:/root/.conduit/bin/">>/etc/profile
source /etc/profile
kubectl create -f ./conduit.yaml
