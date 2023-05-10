#!/bin/bash

if [ ! -f gcc-8.2.0.tar.gz -a glibc-2.28.tar.gz -a make-4.3.tar.gz ];then
	echo "No such file or directory"
	exit 
fi


install_gcc(){
cd /root/
tar xf gcc-8.2.0.tar.gz
cd gcc-8.2.0
./contrib/download_prerequisites
mkdir -p build
cd build
../configure --prefix=/usr/local/gcc-8.2.0 --enable-bootstrap --enable-checking=release --enable-languages=c,c++ --disable-multilib
make -j 4
make install

echo -e '\nexport PATH=/usr/local/gcc-8.2.0/bin:$PATH\n' > /etc/profile.d/gcc.sh
source /etc/profile.d/gcc.sh
sudo ln -s /usr/local/gcc-8.2.0/include/ /usr/include/gcc

cd ~
}

install_make(){
cd /root/
tar xf make-4.2.1.tar.gz
cd make-4.2.1
mkdir -p build
cd build
../configure --prefix=/usr/local/make && make && make install
echo 'export PATH=/usr/local/make/bin:$PATH' > /etc/profile.d/make.sh
source /etc/profile.d/make.sh
ln -s /usr/local/make/bin/make /usr/local/make/bin/gmake

cd ~
}


install_glibc(){

tar xf glibc-2.28.tar.gz
cd glibc-2.28
mkdir -p build && cd build
../configure --prefix=/usr --disable-profile --enable-add-ons --with-headers=/usr/include --with-binutils=/usr/bin
make  -j 4
make install

cd ~

}

install_env(){
cat > /etc/environment  <<EOF
LANG="en_US.UTF-8"
LC_ALL=
EOF

cat > /etc/sysconfig/i18n  <<EOF
LANG="en_US.UTF-8"
SYSFONT="latarcyrheb-sun16"
EOF

localedef -v -c -i en_US -f UTF-8 en_US.UTF-8 &>/dev/null
}


intall_log(){

strings /lib64/libc.so.6 | grep GLIBC_2.28  >> install.log
make -v|grep  Make  >> install.log
gcc -v >> install.log

}





install_gcc
install_make
install_glibc
install_env
intall_log





