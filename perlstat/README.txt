
Code Name: culegatorul
Based on: Sys::Statistic::Linux library http://search.cpan.org/~bloonix/Sys-Statistics-Linux/lib/Sys/Statistics/Linux.pm


System related information: 

sysinfo     -  Collect system information             
cpustats    -  Collect cpu statistics                 
procstats   -  Collect process statistics 
memstats    -  Collect memory statistics  
pgswstats   -  Collect paging and swapping statistics
netstats    -  Collect net statistics                
sockstats   -  Collect socket statistics             
diskstats   -  Collect disk statistics               
diskusage   -  Collect the disk usage                
loadavg     -  Collect the load average              
filestats   -  Collect inode statistics              
processes   -  Collect process statistics            

VoipNow releated (roles are automatically detected):

sipstat     - Collect information about Kamailio
amqpstat    - Collect information about AMQP
pbxstat     - Collect information about Asterisk
sqlstat     - Collect information about Mysql
jabberstat  - Collect information about EJabberd
hubringstat - Collect information about Hubring
esstat      - Collect information about ElasitcSearch
icstat      - Collect information about Infrastructure controller HTTP service
httpstat    - Collect information about HTTP service
phpfpmstat  - Collect information about php-fpm service 
worstat     - Collect information about Celery
vnstat      - Collect general information about accounts from the server
nfscstat    - Collect information about NFS client
nfsstat     - Collect information about NFS server

In order to enable a certain stat the corresponding value in the options hash must be 1. 

my %options = (
        cpustats => 1,
        memstats => 1,
        diskstats => 1,
        netstats => 1,
        pgswstats => 1,
        procstats => 1,
        sysinfo => 1,
        sockstats => 1,
        diskusage => 1,
        loadavg => 1,
        filestats => 1,
        processes => 0,
        nfscstat => 1,
        nfssstat => 1,
        vnstat => 0 || $role{'ic'},
        sipstat => 0 || $role{'sip'},
        amqpstat => 0 || $role{'que'},
        pbxstat => 0 || $role{'pbx'},
        sqlstat => 0 || $role{'sql'},
        jabberstat => 0 ||$role{'jabber'},
        hubringstat => 0 || $role{'dd'},
        esstat => 0 || $role{'es'},
        icstat => 0 || $role{'ic'},
        httpstat =>  0 || $role{'http'},
        phpfpmstat => 0 || $role{'fpm'},
        worstat =>  0 || $role{'wk'},
    );
 

Setting $send_to_graphite = 1; force sending the results to Graphite, but you have to make sure that the  $graphite_host contain the correct IP address of the server where Graphite is installed


Aditionally needed packages available in the distribution repo:

- perl-Time-HiRes 
- perl-libwww 
- perl-JSON
- perl-Crypt-SSLeay


