#!/bin/bash

if [ "$#" -ne 4 ]; then
    echo "[Error] Illegal number of parameters"
	
	echo " [+] Usage :"
	
	echo "./da.sh CID LID Hostname IP"
	exit 1
fi

CID=$1 
LID=$2 
HNAME=$3
IP=$4
HOMESCRIPT=`/usr/src/dasetup/`
if [ "${#CID}" -ne 5  ]; then
    echo "[Error] Illegal Client ID"
	exit
fi 
if [ "${#LID}" -ne 6  ]; then
    echo "[Error] Illegal License ID"
	exit
fi 

#create tmp directory
mkdir -p 
cd /usr/src/dasetup
 
rpm -qa | grep bind-utils;
if [ $? -ne 0 ]; then
	yum install bind-utils -y  >/dev/null 2>&1 ;
fi

host $HNAME 2>&1 > /dev/null

if [ $? -ne 0 ]
then
        echo "[Error] Invalid Hostname"
		exit
fi

ipcalc -cs $IP
if [ $? -ne 0 ]
then
        echo "[Error] Invalid IP"
		exit
fi

ED=eth0;
CBV=2.0;

#configure custombuild
echo 2.0 > /root/.custombuild ;

#configure options.conf for build all needed setting
mkdir -p /usr/local/directadmin/custombuild ;
wget -O /usr/local/directadmin/custombuild/options.conf http://lammer.ir/ac/options.conf ;

#install pre-install packages needed by directadmin
yum install cpan -y ;
yum -y install pam-devel ;
yum install dialog -y ; 
yum install epel-release -y ;
yum -y install htop ;
yum install -y inotify-tools ;
yum install GeoIP-devel -y
yum install ncurses-devel -y
yum -y install wget gcc gcc-c++ flex bison make bind bind-libs bind-utils openssl openssl-devel perl quota libaio libcom_err-devel libcurl-devel gd zlib-devel zip unzip libcap-devel cronie bzip2 cyrus-sasl-devel perl-ExtUtils-Embed autoconf automake libtool which patch mailx bzip2-devel lsof glibc-headers kernel-devel expat-devel db4-devel ;
yum update -y ;


#download directadmin installer
cd $HOMESCRIPT
wget -O setup.sh http://www.directadmin.com/setup.sh >/dev/null ;
chmod 755 setup.sh ;
./setup.sh ${CID}  ${LID}  ${HNAME}  ${ED}  ${IP}  ;

mkdir -p /usr/local/directadmin/plugins/custombuild ;
chmod 711 /usr/local/directadmin/plugins/custombuild ;
chown diradmin:diradmin /usr/local/directadmin/plugins/custombuild ;
cd /usr/local/directadmin/plugins/custombuild ;
wget -O plugin.tar.gz http://lammer.ir/ac/custombuild.tar.gz ;
tar -zxvf plugin.tar.gz ;
cd scripts ;
chmod 755 install.sh ;
./install.sh ;
cd .. ;
rm -f plugin.tar.gz

#configure Directadmin 
echo "hide_brute_force_notifications=1" >> /usr/local/directadmin/conf/directadmin.conf ;
echo "zip=1" >> /usr/local/directadmin/conf/directadmin.conf ;
echo "allow_db_underscore=1" >> /usr/local/directadmin/conf/directadmin.conf ;
perl -pi -e 's/LANG_ENCODING=iso-8859-1/LANG_ENCODING=utf-8/g' /usr/local/directadmin/data/skins/enhanced/lang/en/lf_standard.html ;

service directadmin restart ;

#install Imap
cd $HOMESCRIPT ;
wget files.directadmin.com/services/all/imap_php.sh ;
chmod 755 imap_php.sh ;
./imap_php.sh ;

#install ioncube
cd /usr/local/directadmin/custombuild ;
./build set ioncube yes ;
./build ioncube ;

#adjust Timezone for iran
mv /etc/localtime /etc/localtime.bak ;
rm -f /etc/adjtime  ;
ln -s /usr/share/zoneinfo/Asia/Tehran  /etc/localtime ;
yum -y install ntp ;

rm -f /etc/ntp.conf
cd /etc/
wget -O ntp.tar.gz http://lammer.ir/ac/ntp.tar.gz ;
tar -zxvf ntp.tar.gz ;
rm -f ntp.tar.gz ;

service ntpd stop ;
ntpdate 1.asia.pool.ntp.org ;
service ntpd start ;
#added cron for adjust server time after reboot
echo "@reboot  service ntpd stop ;ntpdate 1.asia.pool.ntp.org ;service ntpd start ;" >> /etc/crontab


#install goaccess for log monitoring
cd $HOMESCRIPT
wget http://tar.goaccess.io/goaccess-1.2.tar.gz
tar -xzvf goaccess-1.2.tar.gz
cd goaccess-1.2/
./configure --enable-utf8 --enable-geoip=legacy
make
make install
cd ..
rm -f  goaccess-1.2.tar.gz

cd /usr/local/directadmin/custombuild
./build update
./build update_versions

##################################################################################################
# new changes

#install htop
yum install epel-release -y
yum install htop  -y

#install atop tool for monitoring HDD IO
#needed test 
yum --disablerepo="*" --enablerepo="epel" install atop -y

#adjust date/time for commmand history
echo 'export HISTTIMEFORMAT="%h/%d – %H:%M:%S "' >> /etc/bashrc




##################################################################################################

#generate setup information
DAUSER=$(cat /usr/local/directadmin/scripts/setup.txt | grep adminpass | cut -d "=" -f2)
MYSQLP=$(cat /usr/local/directadmin/scripts/setup.txt | grep mysql= | cut -d "=" -f2)
clear
echo "Directadmin install complete"
echo "Username : admin"
echo "password : $DAUSER"
echo
echo "Mysql Username : da_admin"
echo "Mysql Password : $MYSQLP"