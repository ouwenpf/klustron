#!/bin/bash

klunstron_user=${1:-kunlun}
#klunstron_basedir=${2:-/kunlun}
VERSION=1.1.1


install_docker(){
#控制机上面执行,已经安装好docker就无需安装
#yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
#yum -y install yum-utils
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin device-mapper-persistent-data lvm2
systemctl start docker
systemctl enable docker

}

download_package(){
#下载安装包
mkdir -p /softwares
cd /softwares
git clone -b 1.1 https://gitee.com/zettadb/cloudnative.git 
cd /softwares/cloudnative/cluster/clustermgr
wget http://zettatech.tpddns.cn:14000/thirdparty/hadoop-3.3.1.tar.gz
wget http://zettatech.tpddns.cn:14000/thirdparty/jdk-8u131-linux-x64.tar.gz
wget http://zettatech.tpddns.cn:14000/thirdparty/mysql-connector-python-2.1.3.tar.gz
wget http://zettatech.tpddns.cn:14000/thirdparty/prometheus.tgz
wget http://zettatech.tpddns.cn:14000/thirdparty/haproxy-2.5.0-bin.tar.gz
wget http://zettatech.tpddns.cn:14000/thirdparty/efk/filebeat-7.10.1-linux-x86_64.tar.gz

wget http://zettatech.tpddns.cn:14000/releases/$VERSION/release-binaries/kunlun-cluster-manager-$VERSION.tgz
wget http://zettatech.tpddns.cn:14000/releases/$VERSION/release-binaries/kunlun-node-manager-$VERSION.tgz
wget http://zettatech.tpddns.cn:14000/releases/$VERSION/release-binaries/kunlun-server-$VERSION.tgz
wget http://zettatech.tpddns.cn:14000/releases/$VERSION/release-binaries/kunlun-storage-$VERSION.tgz
wget http://zettatech.tpddns.cn:14000/releases/$VERSION/release-binaries/kunlun-proxysql-$VERSION.tgz
wget http://zettatech.tpddns.cn:14000/releases/$VERSION/release-binaries/kunlun-xpanel-$VERSION.tgz
wget http://zettatech.tpddns.cn:14000/releases/$VERSION/release-binaries/kunlun-cdc--$VERSION.tgz

# 如果需要使用elasticsearch/kibana来收集并显示节点的日志信息, 则还需要以下两个包:
wget http://zettatech.tpddns.cn:14000/thirdparty/efk/elasticsearch-7.10.1.tar.gz
wget http://zettatech.tpddns.cn:14000/thirdparty/efk/kibana-7.10.1.tar.gz
chown -R $klunstron_user:$klunstron_user /softwares/
cd /softwares/cloudnative/cluster/

}


#install_docker
download_package
