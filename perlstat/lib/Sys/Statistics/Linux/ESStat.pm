
package Sys::Statistics::Linux::ESStat;

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
    my $config_file='/etc/voipnow/esrole.conf';
    my %Config = ();
    my %stats;
    &parse_config_file ($config_file, \%Config);
    my $uri = 'http://'.$Config{'esuser'}.':'.$Config{'espass'}.'@'.$Config{'eshost'}.':'.$Config{'esport'}.'/_status';
    my $req = HTTP::Request->new( 'GET' => $uri );
    my $lwp = LWP::UserAgent->new;
    my $response  = $lwp->request($req);

    if ($response->is_success) {
	my $decoded =decode_json($response->decoded_content);
	$stats{'Shards_Total'} = $decoded->{'_shards'}->{'total'};
	$stats{'Shards_Successful'} =$decoded->{'_shards'}->{'successful'};
	$stats{'Shards_Failed'} =$decoded->{'_shards'}->{'failed'};
	if ($decoded->{'indices'}->{'calls'}->{'docs'}->{'num_docs'}) {
	    $stats{'Calls_Num_docs'} =$decoded->{'indices'}->{'calls'}->{'docs'}->{'num_docs'};
	}
	if ($decoded->{'indices'}->{'calls'}->{'index'}->{'primary_size_in_bytes'}) {
		$stats{'Primary_size_in_bytes'} =$decoded->{'indices'}->{'calls'}->{'index'}->{'primary_size_in_bytes'};
	}
	if ($decoded->{'indices'}->{'calls'}->{'index'}->{'primary_size_in_bytes'}) {
	    my $total = $decoded->{'indices'}->{'geodatabase'}->{'index'}->{'primary_size_in_bytes'} + $decoded->{'indices'}->{'calls'}->{'index'}->{'primary_size_in_bytes'};
	    $stats{'Total_Primary_size_in_bytes'} =$total;
	} else {
	    $stats{'Total_Primary_size_in_bytes'} =$decoded->{'indices'}->{'geodatabase'}->{'index'}->{'primary_size_in_bytes'};
	}
    }

    return \%stats;
}


1;
