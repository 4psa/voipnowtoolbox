package Sys::Statistics::Linux::SIPStat;

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
    my @results = `/usr/sbin/kamctl fifo get_statistics all`;
    my %stats;
    for(@results) {
            my @values = split('=',$_);
            if (trim($values[0]) =~ m{tmx:}gs ||
                trim($values[0]) =~ m{core:fwd_requests}gs ||
                trim($values[0]) =~ m{core:unsupported_methods}gs ||
                trim($values[0]) =~ m{registrar:accepted_regs}gs ||
                trim($values[0]) =~ m{dialog:processed_dialogs}gs ||
                trim($values[0]) =~ m{dialog:failed_dialogs}gs ||
                trim($values[0]) =~ m{mysql:driver_errors}gs ||
                trim($values[0]) =~ m{tcp:established}gs ||
                trim($values[0]) =~ m{tcp:con_reset}gs ||
                trim($values[0]) =~ m{tcp:current_opened_connections}gs ||
                trim($values[0]) =~ m{tcp:passive_open}gs ||
                trim($values[0]) =~ m{shmem:}gs ||
                trim($values[0]) =~ m{websocket:}gs ){
                    my @nnval = split(':',$values[0]);
                    $values[0] =~ s/:/_/;
                    $stats{trim($values[0])} = trim($values[1]);
            }
    }
    return \%stats;
}


1;
