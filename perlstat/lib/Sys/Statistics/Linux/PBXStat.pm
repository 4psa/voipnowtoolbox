
package Sys::Statistics::Linux::PBXStat;

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
    my @results = `/usr/sbin/asterisk -rx 'voipnow show calls count'`;
    my %stats;
    for(@results) {
    	my @values = split(' ',$_);
	$stats{'Concurent_Calls'} = trim($values[0]);
    }
    my @cscup = `/usr/sbin/asterisk -rx 'core show calls uptime seconds'`;
    for(@cscup) {
    	my @values = split(' ',$_);
	if (trim($values[1]) =~ m{calls}gs){
		$stats{'Processed_Calls'} = trim($values[0]);
            } elsif (trim($values[0]) =~ m{System}gs){
		$stats{'UptimeSec'} = trim($values[2]);
            } 
    }

    return \%stats;
}


1;
