# **ITSMA suite diagnotic tool**

## Purpose

Suite diagnotic tool is script based tool to check ITSMA suite system inforamtion as well as suite service status, include hardware information, network, service status and Kubernetes service status.


## USAGE
Usage: ./system_check.sh -l|--logfile <filename of precheck log>

Example:
```
 ./system_check.sh -l system-check.log
```
 
## Change Log

### v0.06
Check deployer, Core and itsm1 service/pod status

### v0.05
Check DNS, netmask

### v0.04
Add check for services, like firewalld, data sync and kubelet.service

### v0.03
Add check for NFS, Master, Worker node

### v0.02
Add check for CPU, Memory, Harddisk

### v0.01
Initialize project
