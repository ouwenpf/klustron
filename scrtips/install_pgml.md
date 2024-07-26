# 安装pgml

```sh
#!/bin/bash

cat << EOF > /etc/yum.repos.d/CentOS-SCLo-rh.repo

# CentOS-SCLo-rh.repo
#
# Please see http://wiki.centos.org/SpecialInterestGroup/SCLo for more
# information

[centos-sclo-rh]
name=CentOS-7 - SCLo rh
baseurl=http://mirrors.aliyun.com/centos/7/sclo/$basearch/rh/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo

[centos-sclo-rh-testing]
name=CentOS-7 - SCLo rh Testing
baseurl=http://mirrors.aliyun.com/centos/7/sclo/$basearch/rh/
gpgcheck=0
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo

[centos-sclo-rh-source]
name=CentOS-7 - SCLo rh Sources
baseurl=http://vault.centos.org/centos/7/sclo/Source/rh/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo

[centos-sclo-rh-debuginfo]
name=CentOS-7 - SCLo rh Debuginfo
baseurl=http://debuginfo.centos.org/centos/7/sclo/$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo


EOF


yum repolist
yum install -y rh-python38-python rh-python38-python-pip rh-python38-python-devel

if [ ! -f /etc/profile.d/python38.sh ];then
	echo 'export PATH=$PATH:/usr/local/python38/bin' >> /etc/profile.d/python38.sh
	source /etc/profile.d/python38.sh
fi

if [ ! -d /usr/local/python38 ];then
	ln -s /opt/rh/rh-python38/root  /usr/local/python38
fi

```


##编译安装以3.7.17为例

```sh
wget https://www.python.org/ftp/python/3.7.17/Python-3.7.17.tar.xz  
tar xf Python-3.7.17.tar.xz
cd Python-3.7.17
./configure --prefix=/usr/local/python37
make && make install

if [ ! -f /etc/profile.d/python37.sh ];then
	echo 'export PATH=$PATH:/usr/local/python37/bin' >> /etc/profile.d/python37.sh
	source /etc/profile.d/python37.sh
fi

```
[参考资料](http://zettatech.tpddns.cn:13000/tracpub/wiki/kunlun.guide.pgml_load)
