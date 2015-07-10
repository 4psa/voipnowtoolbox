#!/usr/bin/perl -w

#require yum install perl-Time-HiRes perl-libwww-perl perl-JSON

use JSON;
use FindBin;                 
use lib "$FindBin::Bin/lib/";
use Sys::Statistics::Linux;
use Net::Graphite;
use aModule;

    my $send_to_graphite = 1; # set to 0 for not pushing data to Graphite
    my $graphite_host = '10.150.5.31';

    my (@node_hash, %role, $graphite);
    my $config_file='/etc/voipnow/management.conf';

    my %Config = ();
    &parse_config_file ($config_file, \%Config);

    my @results = `mysql -u$Config{'dbuser'} -p$Config{'dbpass'} -h$Config{'dbhost'} -P$Config{'dbport'} voipnow -nse 'select nodeid,role from node_role'`;
    my $nnode = &nodeid;

    my $node = trim($nnode);

    if ($send_to_graphite) {
        $graphite = Net::Graphite->new(
	    host                  	=> $graphite_host,
	    port                  	=> 2003,
	    trace                 	=> 1,        
    	    proto                 	=> 'tcp',    
    	    timeout               	=> 1,        
    	    fire_and_forget       	=> 0,        
    	    return_connect_error	=> 0,        
    	    path 		  	=> 'foo.bar.baz',
	);
    }

    for(@results) {
	my @values = split(' ',$_);
	if ($node eq trim($values[0])){
	     $role{trim($values[1])} = 1;
	}
    }

    if ($role{'web'} || $role{'ic'}) {
        $role{'fpm'} = 1;
    }

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


&_stat;


sub _stat {

    my $lxs = Sys::Statistics::Linux->new(\%options );
    sleep(1);
    my $stat = $lxs->get;

    my $hnode =`hostname`;
    my $hname = trim($hnode);
    $hname =~ s/\./_/g;
    my $date = time();

  for my $key ( keys %options ) {
        for my $role ( sort keys %{ $stat->{$key} } ) {
            if (ref($stat->{$key}->{$role}) ne "HASH"){
                if ($send_to_graphite) {
                    $graphite->send(data =>"$hname.$key.$role $stat->{$key}->{$role} $date\n");
                } else {
                    print "$hname.$key.$role $stat->{$key}->{$role} \n";
                }
            } else {
                for my $drole ( sort keys %{ $stat->{$key}->{$role} }){
                    if ($send_to_graphite) {
                        if (ref($stat->{$key}->{$role}->{$drole}) ne "HASH"){
                            $graphite->send(data =>"$hname.$key.$role.$drole $stat->{$key}->{$role}->{$drole} $date\n");
                        } else {
                            for my $crole ( sort keys %{ $stat->{$key}->{$role}->{$drole} }){
                                if (ref($stat->{$key}->{$role}->{$drole}->{$crole}) ne "HASH"){
                                    $graphite->send(data =>"$hname.$key.$role.$drole.$crole $stat->{$key}->{$role}->{$drole}->{$crole} $date\n");
                                } else {
                                    for my $mrole ( sort keys %{ $stat->{$key}->{$role}->{$drole}->{$crole} }){
                                        if (ref($stat->{$key}->{$role}->{$drole}->{$crole}->{$mrole}) eq "HASH" ){
                                            for my $urole ( sort keys %{ $stat->{$key}->{$role}->{$drole}->{$crole}->{$mrole} }){
                                        	$graphite->send(data =>"$hname.$key.$role.$drole.$urole $stat->{$key}->{$role}->{$drole}->{$crole}->{$mrole}->{$urole} $date\n");
                                            }
                                        } else {
                                            $graphite->send(data =>"$hname.$key.$role.$drole.$crole.$mrole $stat->{$key}->{$role}->{$drole}->{$crole}->{$mrole} $date\n");
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if (ref($stat->{$key}->{$role}->{$drole}) ne "HASH"){
                                print "$hname.$key.$role.$drole $stat->{$key}->{$role}->{$drole} \n";
                        } else {
                            for my $crole ( sort keys %{ $stat->{$key}->{$role}->{$drole} }){
                                if (ref($stat->{$key}->{$role}->{$drole}->{$crole}) ne "HASH"){
                                    print "$hname.$key.$role.$drole.$crole $stat->{$key}->{$role}->{$drole}->{$crole} \n";
                                } else {
                                    for my $mrole ( sort keys %{ $stat->{$key}->{$role}->{$drole}->{$crole} }){
                                        if (ref($stat->{$key}->{$role}->{$drole}->{$crole}->{$mrole}) eq "HASH" ){
                                            for my $urole ( sort keys %{ $stat->{$key}->{$role}->{$drole}->{$crole}->{$mrole} }){
                                                print "$hname.$key.$role.$drole.$urole $stat->{$key}->{$role}->{$drole}->{$crole}->{$mrole}->{$urole} \n";
                                            }
                                        } else {
                                            print "$hname.$key.$role.$drole.$crole.$mrole $stat->{$key}->{$role}->{$drole}->{$crole}->{$mrole} \n";
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}



1;
