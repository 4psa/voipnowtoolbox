
package Sys::Statistics::Linux::AMQPStat;

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
    my $version = &version;
    my @results = `/usr/sbin/rabbitmqctl status`;
    my %stats;

    for(@results) {
        $_ =~ s/^\s+//;
	if ($_ =~ m{\{total,}){
            $_ =~ s/\{//g && s/\[//g && s/\}//g && s/\]//g;
            $_ =~ s/\[{//;
            my @cp = split(',',$_);
            $stats{"memory_total"} = trim($cp[1]);
        } elsif ($_ =~ m{\{connection_procs}) {
            $_ =~ s/\{//;
            $_ =~ s/\}//;
            my @cp = split(',',$_);
            $stats{trim($cp[0])} = trim($cp[1]);
        } elsif ($_ =~ m{\{total_limit}) {
            $_ =~ s/\{//;
            $_ =~ s/\}//;
            my @cp = split(',',$_);
            if ($version < 350) {
                $stats{"file_descriptors.total_limit"} = trim($cp[2]);
            } else {
                $stats{"file_descriptors.total_limit"} = trim($cp[1]);
            }
        } elsif ($_ =~ m{\{total_used}) {
            $_ =~ s/\{//;
            $_ =~ s/\}//;
            my @cp = split(',',$_);
            $stats{"file_descriptors.total_used"} = trim($cp[1]);
        } elsif ($_ =~ m{\{sockets_limit}) {
            $_ =~ s/\{//;
            $_ =~ s/\}//;
            my @cp = split(',',$_);
            $stats{trim($cp[0])} = trim($cp[1]);
        } elsif ($_ =~ m{\{sockets_used}) {
            $_ =~ s/\{//;
            $_ =~ s/\}]}//g;
            my @cp = split(',',$_);
            $stats{trim($cp[0])} = trim($cp[1]);
        } elsif ($_ =~ m{\{processes}) {
            $_ =~ s/\{//g && s/\[//g && s/\}//g && s/\]//g;
            my @cp = split(',',$_);
            $stats{trim($cp[0])."_".trim($cp[1])} = trim($cp[2]);
            $stats{trim($cp[0])."_".trim($cp[3])} = trim($cp[4]);
        }

    }
    return \%stats;
}


1;
