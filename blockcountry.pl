#!/usr/bin/perl

use strict;
use LWP::UserAgent;

my $url = "http://www.ipdeny.com/ipblocks/data/countries/";
my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;

my @countries = (
	    "PS",
	    "SA",
	    "TR",
	    );

foreach my $country (@countries) {
    my $response = $ua->get($url."/".lc($country).".zone");
    if ($response->is_success) {
        my @lines = split /\n/, $response->decoded_content;  
	foreach my $line( @lines ) { 
	    my $cip = `iptables -nL | grep "$line" | awk '{print $4}'`;
	    unless ($cip) {
		#print "iptables -I INPUT -s " .$line ." -j DROP -m comment --comment \"IPs from $country\"" ."\n";
		system("iptables -I INPUT -s " .$line ." -j DROP -m comment --comment \"IPs from $country\"");
	    }
	}
    } else {
        die $response->status_line;
    }
}

1;
