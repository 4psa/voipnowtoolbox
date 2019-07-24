#!/usr/bin/bash

#Copyright Rack-Soft Inc <devel@4psa.com>

if [ -e /etc/voipnow/main.conf ] && [ -e /etc/voipnow/sqldbase.conf ]; then
	db_user=$(grep DB_CREDENTIALS /etc/voipnow/main.conf | awk -F ':' '{print $2}')
	db_pass=$(grep DB_CREDENTIALS /etc/voipnow/main.conf | awk -F ':' '{print $3}')
	db_host=$(cat /etc/voipnow/sqldbase.conf | grep DB_MASTER | awk -F':' '{print $2}')
	db_name=$(grep DB_CREDENTIALS /etc/voipnow/main.conf | awk -F ':' '{print $4}')
	db_port=$(grep DB_MASTER /etc/voipnow/sqldbase.conf | awk -F ':' '{print $3}')
	mysql --user=$db_user --password=$db_pass --port=$db_port -e exit 2>/dev/null
	db_status=$(echo $?)
	if [ $db_status -ne 0 ]; then
		echo "Connection to the database cannot be established."
		exit
	fi
fi


if [ -e /usr/local/voipnow/.version ]; then
	VNVERSION=$(awk '{print $1}' /usr/local/voipnow/.version | awk -F'.' '{print $1$2$3}')
	node_id=$(cat /etc/voipnownode/nodeid)
	role_sip=$(echo "SELECT role FROM node_role WHERE nodeid LIKE '"$node_id"' and role like '"sip"';" | mysql -N -u$db_user -p$db_pass -h$db_host $db_name)
	role_http=$(echo "SELECT role FROM node_role WHERE nodeid LIKE '"$node_id"' and role like '"http"';" | mysql -N -u$db_user -p$db_pass -h$db_host $db_name)

	if [ $VNVERSION -ge 400 ]; then
			yum install -y epel-release
			yum-config-manager --enable repository epel
			yum install -y fail2ban
			if [ -z $(rpm -qa | grep iptables-services) ]; then
				yum install -y iptables-services > /dev/null 2>&1
				chkconfig iptables on
				service iptables start
			fi
			chkconfig  firewalld off > /dev/null 2>&1
			service firewalld stop > /dev/null 2>&1
			chkconfig fail2ban on
			service fail2ban start
#MAKE A COPY OF JAIL.CONF NAMED JAIL.LOCAL IN THE SAME DIRECTORY
			touch /var/log/kamailio/abuse.log
			cp -f  /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

#CREATE THE JAILS IN JAIL.LOCAL DEPENDING ON THE ROLE WHICH IS ASSIGNED TO THE NODE

#VERIFY IF THE ROLE IS SIP AND THEN CREATE THE JAIL AND THE FILTER FOR KAMAILIO
				if [ ! -z $role_sip ]; then
					touch /var/log/kamailio/abuse.log
#ENABLE PIKE
					sed -i 's/^[ \t]*SIP_ANTIABUSE 0[ \t]*$/SIP_ANTIABUSE 1/g' /etc/voipnow/local.conf
					if [ $VNVERSION -gt 500 ] && [ $VNVERSION -le 525 ]; then
						cp /etc/kamailio/kamailio.cfg /etc/kamailio/kamailio.cfg.bkup #MAKE A BACKUP OF THE FILE THAT WILL BE MODIFIED
						sed -i 's#$pike_ip"#"+$pike_ip#g' /etc/kamailio/kamailio.cfg
					fi
						
					cat >> /etc/fail2ban/jail.local << EOL

EOL

#CREATE THE JAIL FOR KAMAILIO
					if grep --quiet kamailio /etc/fail2ban/jail.local ; then
						echo 'Kamailio jail is already created'
						else
						cat  >> /etc/fail2ban/jail.local <<EOL
[kamailio]
enabled = true
filter = kamailio
banaction = iptables-allports[name=kamailio, protocol=all]
logpath = /var/log/kamailio/abuse.log
maxretry = 10
bantime = 3600
ignoreip = 127.0.0.0/8

EOL
					fi

					
#CREATE THE FILTER FOR KAMAILIO
					touch /etc/fail2ban/filter.d/kamailio.conf
					if grep -q Definition /etc/fail2ban/filter.d/kamailio.conf ; then
						echo "Filter already created"
					else echo '[Definition]' >> /etc/fail2ban/filter.d/kamailio.conf
					     echo 'failregex= L. Pike block from <HOST>.*' >> /etc/fail2ban/filter.d/kamailio.conf
					fi

				fi

#VERIFY IF THE ROLE IS HTTP AND THEN CREATE THE JAILS AND THE FILTERS DEPENDING ON THE VERSION OF VOIPNOW
				if [ ! -z $role_http ]; then
#CREATE THE JAILS AND FILTERS FOR VOIPNOW5
					if [ $VNVERSION -gt 500 ]; then
#CREATE THE JAIL FOR HTTP
						if grep --quiet catch-http /etc/fail2ban/jail.local ; then
							echo 'catch-http jail is already created'
							else
							cat  >> /etc/fail2ban/jail.local <<EOL

[catch-http]
enabled = true
filter = catch-http
banaction = iptables-allports[name=%(__name__)s, protocol=all]
logpath = /usr/local/voipnow/admin/log/http-access.log
bantime = 3600
maxretry = 20
findtime = 60
ignoreip = 127.0.0.0/8 

EOL
						fi
#CREATE THE FILTER FOR HTTP
						touch /etc/fail2ban/filter.d/catch-http.conf
						if grep -q Definition /etc/fail2ban/filter.d/catch-http.conf ; then
							echo "Filter already cerated"
						else echo '[Definition]' >> /etc/fail2ban/filter.d/catch-http.conf
						     echo 'failregex = ^<HOST> -.*"(GET|POST|HEAD).*HTTP.*" .* [3-6][0-9][0-9] .*' >> /etc/fail2ban/filter.d/catch-http.conf
						fi

#CREATE THE JAIL FOR PROVISIONING
						if grep --quiet blockprovisioning /etc/fail2ban/jail.local ; then
							echo 'blockprovisioning jail is already created'
						else
						cat  >> /etc/fail2ban/jail.local <<EOL

[blockprovisioning]
enabled = true
filter = blockprovisioning
banaction = iptables-allports[name=blockprovisioning, protocol=all]
logpath = /usr/local/voipnow/admin/log/http-access.log
bantime = 3600
maxretry = 70
findtime = 60
ignoreip = 127.0.0.0/8

EOL
						fi
#CREATE THE FILTER FOR PROVISIONING
						touch /etc/fail2ban/filter.d/blockprovisioning.conf
						if grep -q Definition /etc/fail2ban/filter.d/blockprovisioning.conf ; then
							echo "Filter already created"
						else echo '[Definition]' >> /etc/fail2ban/filter.d/blockprovisioning.conf
						     echo 'failregex = ^<HOST> - .* "(GET|POST|HEAD) \/pro\/p\/.* HTTP\/.*" "-" ".*" [4-6][0-9][0-9] - .*' >> /etc/fail2ban/filter.d/blockprovisioning.conf
						fi

#CREATE THE JAIL FOR PROVISIONING2
						if grep --quiet blockprovisioning2 /etc/fail2ban/jail.local ; then
							echo 'blockprovisioning2 jail is already created'
						else
						cat  >> /etc/fail2ban/jail.local <<EOL
[blockprovisioning2]
enabled = true
filter = blockprovisioning2
banaction = iptables-allports[name=blockprovisioning2, protocol=all]
logpath = /usr/local/voipnow/admin/log/http-access.log
bantime = 3600
maxretry = 20
findtime = 60
ignoreip = 127.0.0.0/8

EOL
						fi
#CREATE THE FILTER FOR PROVISIONIG2
						touch /etc/fail2ban/filter.d/blockprovisioning2.conf
						if grep -q Definition /etc/fail2ban/filter.d/blockprovisioning2.conf ; then
							echo "Filter already created"
						else echo '[Definition]' >> /etc/fail2ban/filter.d/blockprovisioning2.conf
						     echo 'failregex = ^<HOST> -.* "(GET|HEAD|POST) \/pro\/p\/.* HTTP\/1.*" "-" ".* (.*) .*\/.* .*" [4-6][0-9][0-9] - .* .* .*' >> /etc/fail2ban/filter.d/blockprovisioning2.conf
						fi

#CREATE THE JAIL FOR LOGIN
						if grep --quiet blocklogin /etc/fail2ban/jail.local ; then
							echo 'blocklogin jail is already created'
						else
						cat  >> /etc/fail2ban/jail.local <<EOL

[blocklogin]
enabled = true
filter = blocklogin
banaction = iptables-allports[name=blocklogin, protocol=all]
logpath = /usr/local/voipnow/admin/log/http-access.log
bantime = 3600
maxretry = 20
findtime = 60
ignoreip = 127.0.0.1 

EOL
						fi
#CREATE THE FILTER FOR LOGIN
						touch /etc/fail2ban/filter.d/blocklogin.conf
						if grep -q Definition /etc/fail2ban/filter.d/blocklogin.conf ; then
							echo "Filter already cerated"
						else echo '[Definition]' >> /etc/fail2ban/filter.d/blocklogin.conf
						     echo 'failregex = ^<HOST> - .* "(GET|POST) \/.* HTTP\/.*" "https:\/\/.*\/login_up.php" ".*" [4-6][0-9][0-9] - .* .* .*' >> /etc/fail2ban/filter.d/blocklogin.conf
						fi
				
		
					else

#CREATE THE JAILS AND FILTER FOR VOIPNOW4

#CREATE THE JAIL FOR HTTP					
					if grep --quiet catch-http /etc/fail2ban/jail.local ; then
                                                        echo 'catch-http jail is already created'
                                                        else
                                                        cat  >> /etc/fail2ban/jail.local <<EOL

[catch-http]
enabled = true
filter = catch-http
banaction = iptables-allports[name=%(__name__)s, protocol=all]
logpath = /usr/local/voipnow/admin/log/access.log
bantime = 3600
maxretry = 20
findtime = 60
ignoreip = 127.0.0.0/8

EOL
					fi
#CREATE THE FILTER FOR HTTP
					touch /etc/fail2ban/filter.d/catch-http.conf
					if grep -q Definition /etc/fail2ban/filter.d/catch-http.conf ; then
						echo "Filter already cerated"
					else echo '[Definition]' >> /etc/fail2ban/filter.d/catch-http.conf
					     echo 'failregex = ^<HOST> -.*"(GET|POST|HEAD).*HTTP.*" .* [3-6][0-9][0-9] - .*' >> /etc/fail2ban/filter.d/catch-http.conf
					fi

#CREATE THE JAIL FOR PROVISIONING
					if grep --quiet blockprovisioning /etc/fail2ban/jail.local ; then
						echo 'blockprovisioning jail is already created'
					else
					cat  >> /etc/fail2ban/jail.local <<EOL

[blockprovisioning]
enabled = true
filter = blockprovisioning
banaction = iptables-allports[name=blockprovisioning, protocol=all]
logpath = /usr/local/voipnow/admin/log/access.log
bantime = 3600
maxretry = 70
findtime = 60
ignoreip = 127.0.0.0/8

EOL
					fi
#CREATE THE FILTER FOR PROVISIONING
					touch /etc/fail2ban/filter.d/blockprovisioning.conf
					if grep -q Definition /etc/fail2ban/filter.d/blockprovisioning.conf ; then
						echo "Filter already created"
					else echo '[Definition]' >> /etc/fail2ban/filter.d/blockprovisioning.conf
					     echo 'failregex = ^<HOST> - .* "(GET|POST|HEAD) \/pro\/p\/.* HTTP\/.*" "-" ".*" [4-6][0-9][0-9] - .*' >> /etc/fail2ban/filter.d/blockprovisioning.conf
					fi

#CREATE THE JAIL FOR PROVISIONING2
					if grep --quiet blockprovisioning2 /etc/fail2ban/jail.local ; then
						echo 'blockprovisioning2 jail is already created'
					else
					cat  >> /etc/fail2ban/jail.local <<EOL
[blockprovisioning2]
enabled = true
filter = blockprovisioning2
banaction = iptables-allports[name=blockprovisioning2, protocol=all]
logpath = /usr/local/voipnow/admin/log/access.log
bantime = 3600
maxretry = 20
findtime = 60
ignoreip = 127.0.0.0/8

EOL
					fi
#CREATE THE FILTER FOR PROVISIONING2
					touch /etc/fail2ban/filter.d/blockprovisioning2.conf
					if grep -q Definition /etc/fail2ban/filter.d/blockprovisioning2.conf ; then
						echo "Filter already created"
					else echo '[Definition]' >> /etc/fail2ban/filter.d/blockprovisioning2.conf
					     echo 'failregex = ^<HOST> -.* "(GET|HEAD|POST) \/pro\/p\/.* HTTP\/1.*" "-" ".* (.*) .*\/.* .*" [4-6][0-9][0-9] - .* .* .*' >> /etc/fail2ban/filter.d/blockprovisioning2.conf
					fi
#CREATE THE JAIL FOR LOGIN
					if grep --quiet blocklogin /etc/fail2ban/jail.local ; then
						echo 'blocklogin jail is already created'
					else
					cat  >> /etc/fail2ban/jail.local <<EOL

[blocklogin]
enabled = true
filter = blocklogin
banaction = iptables-allports[name=blocklogin, protocol=all]
logpath = /usr/local/voipnow/admin/log/access.log
bantime = 3600
maxretry = 20
findtime = 60
ignoreip = 127.0.0.0/8

EOL
					fi
#CREATE THE FILTER FOR LOGIN
					touch /etc/fail2ban/filter.d/blocklogin.conf
					if grep -q Definition /etc/fail2ban/filter.d/blocklogin.conf ; then
						echo "Filter already cerated"
					else echo '[Definition]' >> /etc/fail2ban/filter.d/blocklogin.conf
					     echo 'failregex = ^<HOST> - .* "(GET|POST) \/.* HTTP\/.*" "https:\/\/.*\/login_up.php" ".*" [2,4-6][0-9][0-9] - .* .* .*' >> /etc/fail2ban/filter.d/blocklogin.conf
					fi
					fi
				fi


POSITIONAL=()
while [ "$#" -gt 0 ]; do
key="$1"
        case $key in
                --whitelist)
                        for i in $(echo $2 | sed "s/,/ /g") ; do
                                if [[ "$i" =~ ^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$ ]]; then
                                        sed -i "s#ignoreip = 127.0.0.1/8#ignoreip = 127.0.0.1/8 $i #g" /etc/fail2ban/jail.local
					mysql -u$db_user -p$db_pass -h$db_host $db_name -e "insert into ser_address values ('',1,'$i','32',0,'');"
				
     				elif [[ "$i" =~ ^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\/[0-9][0-9]$ ]]; then
					sed -i "s#ignoreip = 127.0.0.1/8#ignoreip = 127.0.0.1/8 $i #g" /etc/fail2ban/jail.local
        				mysql -u$db_user -p$db_pass -h$db_host $db_name << EOF
INSERT INTO ser_address values ('',1,"$(echo $i | awk -F '/' '{print $1}')","$(echo $i | awk -F '/' '{print $2}')",0,'');
EOF
	
										
                                fi
                        done
                        shift
                        shift
                        ;;

                --restartkamailio)
                        echo "Restarting kamailio service"
                        service kamailio restart
                        shift
                        shift
                        ;;
                *)
                        POSITIONAL+=($1)
                        shift
                        ;;
        esac
done

#RESTART FAIL2BAN SERVICE TO HAVE ALL THE CHAMNGES APPLIED

		service fail2ban restart

#DISABLE EPEL REPOSITORY

		yum-config-manager --disable repository epel > /dev/null 2>&1

        	echo '======================================COMPLETED!==============================================='


	else echo "Fail2ban is supported on versions of Voipnow greater than 4.0.0. Your version of Voipnopw is $(awk '{print $1}' /usr/local/voipnow/.version | awk -F'.' '{print $1"."$2"."$3}') and it does not support fail2ban. Please upgrade your Voipnow to the latest version."
	fi



else echo "VoipNow is not installed. Nothing to do."
fi


