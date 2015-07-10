
package Sys::Statistics::Linux::HTTPStat;

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

    my $uri = 'http://127.0.0.1/vn_status/';
    my $req = HTTP::Request->new( 'GET' => $uri );
    my $lwp = LWP::UserAgent->new;
    my $response  = $lwp->request($req);
    my %stats;

    if ($response->is_success) {
	for($response->decoded_content) {
    	    $_ =~ s/^\s+//;
    	    $_ =~ s/\n//g;
    	    my @values = split(' ',$_);

            $stats{"Active_connections"} = trim($values[2]);
	    $stats{"Accepted_conections"} = trim($values[7]);
    	    $stats{"Handled_conections"} = trim($values[8]);
    	    $stats{"Requests_handeled"} = trim($values[9]);
        }
    } else {
	print "vn_status missing from configuration\n";

    }
    return \%stats;
}


1;
