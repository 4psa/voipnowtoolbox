
package Sys::Statistics::Linux::HubringStat;

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

    my @results = `hr-cli -h $Config{'rhost'} -p $Config{'rport'} -n $Config{'rdb'} -dp $Config{'rpass'} info`;
    my %stats;
    for(@results) {
    	    my @values = split(':',$_);
	    if (trim($values[0]) =~ m{mem_fragmentation_ratio}gs){
		    $stats{trim($values[0])} = trim($values[1]);
	    } elsif (trim($values[0]) =~ m{keyspace_hits}gs){
		    $stats{trim($values[0])} = trim($values[1]);
	    } elsif (trim($values[0]) =~ m{keyspace_misses}gs){
		    $stats{trim($values[0])} = trim($values[1]);
	    } elsif (trim($values[0]) =~ m{used_memory}gs){
		    $stats{trim($values[0])} = trim($values[1]);
	    } elsif (trim($values[0]) =~ m{used_memory_human}gs){
		    $stats{trim($values[0])} = trim($values[1]);
	    } elsif (trim($values[0]) =~ m{used_cpu_sys}gs){
		    $stats{trim($values[0])} = trim($values[1]);
	    } elsif (trim($values[0]) =~ m{used_cpu_user}gs){
		    $stats{trim($values[0])} = trim($values[1]);
	    } elsif (trim($values[0]) =~ m{connected_clients}gs){
		    $stats{trim($values[0])} = trim($values[1]);
	    } elsif (trim($values[0]) =~ m{total_connections_received}gs){
		    $stats{trim($values[0])} = trim($values[1]);
	    } elsif (trim($values[0]) =~ m{total_commands_processed}gs){
		    $stats{trim($values[0])} = trim($values[1]);
	    } 
    }
    return \%stats;
}

1;
