#!/bin/bash
#open network 
sed -i 's/ONBOOT=no/ONBOOT=yes/g' /etc/sysconfig/network-scripts/ifcfg-ens32
systemctl restart network
#close firewalld
systemctl stop firewalld
systemctl disabled firewalld
#close selinux
sed -i 's/SELINUX=enforce/SELINUX=disabled/g'  /etc/selinux/config
#add yum http_proxy and system http_proxy
echo "proxy= http://web-proxy.corp.hpecorp.net:8080">> /etc/yum.conf
echo "http_proxy=http://web-proxy.corp.hpecorp.net:8088">>/etc/profile
echo "https_proxy=http://web-proxy.corp.hpecorp.net:8088">>/etc/profile
echo "no_proxy=.hpsw.net">>/etc/profile
echo "export http_proxy https_proxy">>/etc/profile
source /etc/profile
# upgrade repo and install tools
yum upgrade -y 
yum install -y net-tools lsof libtool-ltdl vim java-1.8.0-openjdk nfs-utils sysstat iotop httpd-tools chrony unzip socat git golang wget zip
# add admin user
useradd admin
echo "admin:1Qaz2wsx"|passwd
echo "admin ALL=(ALL) ALL">>/etc/sudoers
#bak centos repo and scp docker.repo and hpecore.repo
#cp docker.repo hpecore.repo to  /etc/yum.repos.d/
cd /etc/yum.repos.d/
mv CentOS-Base.repo CentOS-Base.repo.bak
mv CentOS-Debuginfo.repo CentOS-Debuginfo.repo.bak
mv CentOS-Media.repo CentOS-Media.repo.bak
mv CentOS-Vault.repo CentOS-Vault.repo.bak
mv CentOS-CR.repo CentOS-CR.repo.bak
mv CentOS-fasttrack.repo CentOS-fasttrack.repo.bak
mv CentOS-Sources.repo CentOS-Sources.repo.bak
cd ~
#change configure of chronyd
#scp chrony.conf /etc/chrony.conf
systemctl start chronyd
systemctl enable chronyd
#===================================================
#if you upgrade git to version2.21 please refer http://blog.csdn.net/Veechange/article/details/53943871 need install autoconf
#ln -s /usr/local/git/bin/git /usr/sbin/git 
#===================================================

#change kernel parm...
chmod -R 766 /etc/security/limits.conf
echo '* hard nofile 1000000' >> /etc/security/limits.conf
echo '* soft nofile 1000000' >> /etc/security/limits.conf
echo 'root hard nofile 1000000' >> /etc/security/limits.conf
echo 'root soft nofile 1000000' >> /etc/security/limits.conf
echo '* soft nproc 1000000' >> /etc/security/limits.conf
echo '* hard nproc 1000000' >> /etc/security/limits.conf
echo 'kernel.sem=250 125000 100 500' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_tw_recycle = 1' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_tw_reuse = 1' >> /etc/sysctl.conf
echo 'net.core.wmem_max=4194304' >> /etc/sysctl.conf
echo 'net.core.rmem_max=4194304' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_wmem=4096 87380 4194304' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_rmem=4096 87380 4194304' >> /etc/sysctl.conf
echo 'net.ipv4.ip_local_port_range = 1024 65535' >> /etc/sysctl.conf
#====================================================
#scp VMwareTools-10.0.0-3000743.tar.gz
#install vmwaretools.
#http://shc-nexus-repo.hpeswlab.net:8080/repository/itsma-releases/com/hpe/itsma/VMwareTools/10.0.0-3000743/VMwareTools-10.0.0-3000743.tar.gz
#====================================================
#====================================================
#open thinpool for docker 
#https://docs.software.hpe.com/wiki/pages/viewpage.action?pageId=6948528
#====================================================
sed -i '$d' /etc/profile
sed -i '$d' /etc/profile
sed -i '$d' /etc/profile
sed -i '$d' /etc/profile
yum clean all
echo > /var/log/wtmp
echo > /var/log/btmp
echo > ./.bash_history
history -c
