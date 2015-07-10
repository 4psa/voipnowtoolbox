
Code Name: culegatorul

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
        sipstat => $role{'sip'},
        amqpstat => $role{'que'},
        pbxstat => $role{'pbx'},
        sqlstat => $role{'sql'},
        jabberstat =>$role{'jabber'},
        hubringstat => $role{'dd'},
        esstat => $role{'es'},
        icstat => $role{'ic'},
        httpstat => $role{'http'},
        worstat => $role{'wk'},

);
 

Setting $send_to_graphite = 1; force sending the results to Graphite, but you have to make sure that the connector is properly configured like the below example.

        $graphite = Net::Graphite->new(
            host                        => '10.150.5.31',
            port                        => 2003,
            trace                       => 1,
            proto                       => 'tcp',
            timeout                     => 1,
            fire_and_forget             => 0,
            return_connect_error        => 0,
            path                        => 'foo.bar.baz',
        );



Aditionally needed packages available in the distribution repo:

- perl-Time-HiRes 
- perl-libwww 
- perl-JSON
- perl-Crypt-SSLeay


