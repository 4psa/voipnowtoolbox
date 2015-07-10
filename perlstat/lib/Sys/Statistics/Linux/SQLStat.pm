
package Sys::Statistics::Linux::SQLStat;

use strict;
use warnings;
use Carp qw(croak);
use aModule;
our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $opts  = ref($_[0]) ? shift : {@_};
    my %self;
    return bless \%self, $class;
}

sub get {

my $config_file='/etc/voipnow/main.conf';

my %Config = ();
&parse_config_file ($config_file, \%Config);
    my @results = `mysql -u$Config{'dbuser'} -p$Config{'dbpass'} -h$Config{'dbhost'} -P$Config{'dbport'} -nse 'show global status'`;
    my %stats;
    for(@results) {
    	    my @values = split(' ',$_);
	    if (trim($values[0]) =~ m{Threads_connected}gs){
		    $stats{trim($values[0])} = trim($values[1]);
	    } elsif (trim($values[0]) =~ m{Slow_queries}gs){
		    $stats{trim($values[0])} = trim($values[1]);
	    } elsif (trim($values[0]) =~ m{Questions}gs){
		    my @madm = `mysqladmin -u$Config{'dbuser'} -p$Config{'dbpass'} -h$Config{'dbhost'} -P$Config{'dbport'} status`;
		    my @maval = split(' ',$madm[0]);
		    if (trim($maval[0]) =~ m{Uptime:}gs){
    			my @mvl = split(':',$maval[0]);
			$stats{'QPS'} = trim($values[1]/$maval[1]);
		    }	    
	    } elsif (trim($values[0]) =~ m{Threads_running}gs){
		    $stats{trim($values[0])} = trim($values[1]);
	    } elsif (trim($values[0]) =~ m{Open_tables}gs){
		    $stats{trim($values[0])} = trim($values[1]);
	    } elsif (trim($values[0]) =~ m{Innodb_rows_read}gs){
		    $stats{trim($values[0])} = trim($values[1]);
	    } elsif (trim($values[0]) =~ m{Connections}gs){
		    $stats{trim($values[0])} = trim($values[1]);
	    } elsif (trim($values[0]) =~ m{Aborted_connects}gs){
		    $stats{trim($values[0])} = trim($values[1]);
	    } elsif (trim($values[0]) =~ m{Aborted_clients}gs){
		    $stats{trim($values[0])} = trim($values[1]);
	    } elsif (trim($values[0]) =~ m{Queries}gs){
		    $stats{trim($values[0])} = trim($values[1]);
	    } elsif (trim($values[0]) =~ m{Com_select}gs){
		    $stats{trim($values[0])} = trim($values[1]);
	    } elsif (trim($values[0]) =~ m{Com_update}gs){
		    $stats{trim($values[0])} = trim($values[1]);
	    } elsif (trim($values[0]) =~ m{Com_insert}gs){
		    $stats{trim($values[0])} = trim($values[1]);
	    } elsif (trim($values[0]) =~ m{Com_delete}gs){
		    $stats{trim($values[0])} = trim($values[1]);
	    } elsif (trim($values[0]) =~ m{Qcache_hits}gs){
		    $stats{trim($values[0])} = trim($values[1]);
	    } 
    }
    return \%stats;
}


1;
