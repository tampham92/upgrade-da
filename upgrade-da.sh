#!/bin/bash
inet=`netstat -i | head -n 3 | tail -n 1 | cut -d' ' -f1`
da="/usr/local/directadmin/directadmin"
da_local="/usr/local/directadmin"
#ifdown="/usr/sbin/ifdown ${inet}"
IPADD="/etc/sysconfig/network-scripts/ifcfg-${inet}:1"
IPADD_NEW="/etc/sysconfig/network-scripts/ifcfg-${inet}:100"
DA_VER=`/usr/local/directadmin/directadmin v | awk '{print $3}' | cut -d. -f2,3`
eth="IPADDR=176.99.3.34"
eth_old="IPADDR=221.121.12.138"
eth_lic=`cat ${IPADD} | grep IPADD`
lic="/usr/local/directadmin/conf/license.key"
key="http://get.cyberslab.net/da/v6/key/license.key"
cron_dir="/usr/local/directadmin/scripts"
cron_dir2="/var/spool/da"
cron_job="/etc/cron.d/directadmin_lic"
url_sc="http://get.cyberslab.net/da/v6/script/getLicense.sh"
url_down="http://get.cyberslab.net/da/v6/downgrade/update.tar.gz"
iface="http://get.cyberslab.net/da/v6/script/iface_v6"
daconf="/usr/local/directadmin/conf/directadmin.conf"
old_nic=`cat /usr/local/directadmin/conf/directadmin.conf | grep ethernet_dev | cut -d'=' -f2`
new_nic="${inet}:100"
boot_dir="/usr/local/directadmin/scripts/boot.sh"
boot_url="http://get.cyberslab.net/da/v6/script/boot"

####################################################Begin########################################

iFace(){
	curl -Lso- ${iface} | bash
}
doUpdateDAConf(){
	sed -i 's+'$old_nic'+'$new_nic'+g' $daconf
}
addIface(){
	/usr/bin/touch ${IPADD_NEW}
	iFace

}
doCheckDA(){
	if test -f $da; then
		doCheckInterFace
	else
		echo "Directadmin not found!"
		exit 0
	fi
}
doUpdateLic(){
	if test -f $lic; then
		rm -f $lic
		/usr/bin/wget -O $lic $key &>/dev/null
		chown -R diradmin:diradmin $lic
		doUpdateDAConf
		doReloadService
		doAddCron
		doCheckBoot
		doCheckVerUpdate
	else 
		/usr/bin/wget -O $lic $key &>/dev/null
		chown -R diradmin:diradmin $lic
		doUpdateDAConf
		doReloadService
		doAddCron
		doCheckBoot
		doCheckVerUpdate
	fi
}
doCronJob(){
	if test -f $cron_job; then
		echo "15      04      *       *       *       root	/usr/bin/tlic diradmin" > $cron_job
	else touch $cron_job
		echo "15      04      *       *       *       root	/usr/bin/tlic diradmin" > $cron_job
	fi
}
doAddCron(){
	if test -d $cron_dir; then
		rm -f $cron_dir/getLicense.sh
		/usr/bin/wget -O $cron_dir/getLicense.sh $url_sc &>/dev/null
		doCronJob
	else
		mkdir -p $cron_dir
		/usr/bin/wget -O $cron_dir/getLicense.sh $url_sc &>/dev/null
		doCronJob
	fi
}
doReloadService(){
	if test -f /etc/sysconfig/network-scripts/route-${inet};then
		echo > /etc/sysconfig/network-scripts/route-${inet}
	fi
	systemctl restart network
	systemctl restart  startips
	systemctl restart directadmin
	reboot
}
doCheckVerUpdate(){
	if test -d $cron_dir2; then
		/usr/bin/rm -f $cron_dir2/active.sh
		/usr/bin/rm -f $cron_dir2/firstboot.sh
	fi
}
doCheckInterFace(){
	if test -f ${IPADD}; then
		if [[ ${eth_lic} == ${eth_old} ]]; then
			/usr/sbin/ifdown ${inet}:1
			/usr/bin/rm -f ${IPADD}
			addIface
			doCheckVersionDA
			sleep 2
			doUpdateLic
		fi
	else
		addIface
		doCheckVersionDA
		sleep 2
		doUpdateLic
	fi
}
doCheckBoot(){
	if test -f ${boot_dir}; then
		/usr/bin/rm -f ${boot_dir}
		/usr/bin/wget -O ${boot_dir} ${boot_url} &>/dev/null
		chown -R diradmin:diradmin ${boot_dir}
	fi
}
doCheckVersionDA(){
	if [[ "$DA_VER" == "1.50" ]]; then
		doUpGrade
	fi
}
doUpGrade(){
	pkill -9 directadmin
	/usr/bin/rm -f ${da_local}/update.tar.gz
	/usr/bin/rm -f ${da_local}/directadmin
	/usr/bin/rm -f ${da_local}/.directadmin
	csf -u
	/usr/bin/wget -O ${da_local}/update.tar.gz ${url_down} &> /dev/null
	/usr/bin/tar zxvf ${da_local}/update.tar.gz -C ${da_local} &> /dev/null
	chown -R diradmin:diradmin ${da_local}/directadmin
	/usr/local/directadmin/directadmin p
}
main(){
	doCheckDA
}
main