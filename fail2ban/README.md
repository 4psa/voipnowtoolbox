Fail2ban scans log files (e.g. /var/log/apache/error_log) and bans IPs that show the malicious signs -- too many password failures, seeking for exploits, etc. Generally Fail2Ban is then used to update firewall rules to reject the IP addresses for a specified amount of time, although any arbitrary other action (e.g. sending an email) could also be configured. Out of the box Fail2Ban comes with filters for various services (apache, courier, ssh, etc).
This script is used to install Fail2ban configured for VoipNow.

It automatically installs Fail2ban.

There are a couple of commands that can check some of the functionalities, for example:

[root@instance ~]# fail2ban-client status <jail_name> #This command shows the status of the specified jail (Please change <jail_name> with the name of the jail which you want to check, and it looks like this:
[root@instance ~]# fail2ban-client status kamailio
Status for the jail: kamailio
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /var/log/kamailio/abuse.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
   
[root@instance ~]# fail2ban-client set <jail_name> unbanip <ip_address_to_unban> #This command allows you to unban IP addresses.

It's worth mentioning that fail2ban is supported on VoipNow versions greater than 4.
Another thing to mention is that fail2baninstall.sh script triggers actions with IPTABLES.

Please keep in mind that you need to restart kamailio service after you run fail2baninstall.sh script.

There are also 2 command line options that the script accepts:

--whitelist 127.0.0.1,127.0.0.0,127.127.127.127 #It allows you to add IP addresses to the Whitelist to protect them from banning. The IP addresses must be separated by a comma, as shown in previous example. The Whitelist can also be configured editing the file /etc/fail2ban/jail.local, adding the target IPs to ignoreip variable using space as a delimiter between IP addresses.

--restartkamailio #If this option is specified in the command line, the script will automatically restart kamailio service.
