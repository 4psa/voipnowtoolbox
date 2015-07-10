
package Sys::Statistics::Linux::PHPFPMStat;

use strict;
use warnings;
use Carp qw(croak);
use HTTP::Request::Common;
use LWP::UserAgent;
use JSON;
use aModule;


our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $opts  = ref($_[0]) ? shift : {@_};
    my %self;
    return bless \%self, $class;
}

sub get {

    my $uri = 'https://127.0.0.1/status-fpm';
    my $req = HTTP::Request->new( 'GET' => $uri );
    my $lwp = LWP::UserAgent->new;
    $lwp->ssl_opts( verify_hostname => 0 ,SSL_verify_mode => 0x00);
    my $response  = $lwp->request($req);
    my %stats;

    if ($response->is_success) {
	my @lines = split /\n/, $response->decoded_content;
        foreach my $line( @lines ) {
    	    $line =~ s/^\s+//;
    	    $line =~ s/\n//g;
            my @values = split(':',$line);
            $values[0] =~ s/\s/_/g;;
            $stats{trim($values[0])} = trim($values[1]);
	}
    } else {
	  print "PHPFpm status error\n";

    }
    return \%stats;
}


1;
