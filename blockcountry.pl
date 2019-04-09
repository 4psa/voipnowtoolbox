#!/usr/bin/perl

#Copyright devel@4psa.com
#Requirements (from base and epel repositories on centos7 or base and rpmforge on centos6):
# yum install perl-Locale-SubCountry  perl-libwww-perl 

use strict;
use LWP::UserAgent;
use Locale::SubCountry;
use Cwd qw(abs_path);
use File::Basename qw( dirname );

$| = 1;

my $url = "http://www.ipdeny.com/ipblocks/data/countries/";
my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;

my $world = Locale::SubCountry::World->new();
my %all_country_keyed_by_code   = $world->code_full_name_hash;

my ($switch,$options,$j,$param,$policy,$iptables,$ipset,$grep,$awk,$cat);
my $wpath = dirname(abs_path($0));

open(my $rh, '<', "/etc/redhat-release") or die "Could not open file  $!";
while (my $row = <$rh>) {
    my @ver = split('release',$row);
    $ver[1]=~ s/\D//g;
    if (substr($ver[1],0,1) eq '7'){
	$iptables = "/usr/sbin/iptables";
	$ipset = "/usr/sbin/ipset";
	$grep ="/usr/bin/grep";
	$awk ="/usr/bin/awk";
	$cat ="/usr/bin/cat"
    } elsif (substr($ver[1],0,1) eq '6'){
	$iptables = "/sbin/iptables";
	$ipset = "/usr/sbin/ipset";
	$grep ="/bin/grep";
	$awk ="/bin/awk";
	$cat="/bin/cat";
    }
}

#configure countries you want to block
my @countries = (
        "PS",
        "SA",
        "TR",
        );

if (-e "$wpath/.alsoadd") {
    my $ac = `$cat $wpath/.alsoadd`;
    my @chars = split(',',lc($ac));
    foreach my $c (@chars) {
       if ($c eq 'uk') { $c = 'gb';};
       push @countries, uc($c);
    }
}

for(my $i=0; $i<@ARGV; $i++) {
    if(substr($ARGV[$i], 0, 1) eq '-') {
        $switch = $ARGV[$i];
        $options->{$switch} = 1;
    } else {
	if(not length $switch) {
    	    $param++;
    	    $j = "parameter_$param";
    	} else {
    	    $j = $switch;
    	}
    $options->{$j} = $ARGV[$i];
    $switch = '';
    }
}

$options->{'-p'} ? $policy=lc($options->{'-p'}):($policy="reject");
&_params;


foreach my $country (@countries) {
    my $country_name = $all_country_keyed_by_code{$country};
    $country_name =~ s/\,//g;
    $country_name =~ s/\'/_/g;
    $country_name =~ s/\x{0F4}/o/g;
    $country_name =~ s/\x{0E7}/c/g;
    $country_name =~ s/\x{0E9}/e/g;
    $country_name =~ s/\x{0C5}/A/g;
    $country_name =~ s/\)/_/g;
    $country_name =~ s/\(/_/g;
    $country_name =~ s/\ /_/g;
    $country_name = substr($country_name,0,30);

    open(my $fh, '>', $wpath."/".$country_name.".conf") or die "Could not open file  $!";
    print $fh "create $country_name hash:net family inet hashsize 2048 maxelem 65536 \n";
    my $response = $ua->get($url."/".lc($country).".zone");
    if ($response->is_success) {
        my @lines = split /\n/, $response->decoded_content;
        if ($options->{'-r'}) {
	    print " $country_name ";
	} else {
	    print "Write set files and enable rules for $country_name ";
	}
    	foreach my $line( @lines ) {
	    print $fh "add $country_name $line \n";
	}
	close($fh);
    	&_enable_rules($country_name);
    } else {
    	die $response->status_line;
    }
}

sub _enable_rules {
    my ($set) = @_;
    if ($options->{'-r'}) {
        system ($ipset." restore -! < $wpath/" .trim($set).".conf");
	print "....done\n";
    } else {
        system ($ipset." restore -! < $wpath/" .trim($set).".conf");   
	my $cip = `$iptables -nL | $grep "$set" | $awk '{print $4}'`;
	if ($cip) {
	    if ($policy eq 'reject') {
		system($iptables." -D INPUT -m set --match-set ". trim($set). " src -j REJECT --reject-with icmp-host-unreachable");
	    } elsif ($policy eq 'accept') {
        	system($iptables." -D INPUT -m set --match-set ". trim($set). " src -j ACCEPT");
	    } elsif ($policy eq 'drop') {
        	system($iptables." -D INPUT -m set --match-set ". trim($set). " src -j DROP");
	    }
	}
	if ($policy eq 'reject') {
    	    system($iptables." -I INPUT -m set --match-set ". trim($set). " src -j REJECT --reject-with icmp-host-unreachable");
	} elsif ($policy eq 'accept') {
    	    system($iptables." -I INPUT -m set --match-set ". trim($set). " src -j ACCEPT");
	} elsif ($policy eq 'drop') {
        	system($iptables." -I INPUT -m set --match-set ". trim($set). " src -j DROP");
	}
	print "....done\n";
    }
}

sub _params {

    unless ($policy eq "accept" || $policy eq "reject" || $policy eq "drop") {
        print "Wrong Policy: $policy. Check the input!! \n";
        exit;
    }
    unless (-e $ipset && -e $iptables) {
	print "Error: ipset and iptables rpm packages must be installed!\n run: \n\t yum install ipset iptables \n\n before running this script\n";
	exit;
    }



    if ($options->{'-f'}) {
	print 'Flush all the IP sets and iptables rules? [Y/N]';
	chomp ($_=<STDIN>);
	if( /^[Yy](?:es)?$/ ) {
	    print "Flushing now";
	    system($iptables." -F && ".$iptables." -X && ".$ipset." destroy");
	    unlink "$wpath/.alsoadd" or warn "Could not unlink  $!";
	    print "....done\n";
	    exit;
	}  else {
    	    print "Exiting without flushing the existing rules\n";
	    exit;
	}
    }

    if ($options->{'-h'} eq 'countries' || $options->{'-h'} eq 'country') {
    	while (my ($k,$v)=each %all_country_keyed_by_code){print "$k $v\n"}
	exit;
    } elsif ($options->{'-h'} eq 'list_sets') {
	print "Available IP sets: \n";
	my $aset = `$ipset list -n`;
	print $aset;
	exit;
    }

    if ($options->{'-r'}) {
	print "Refresh IP addresses for the loaded sets: \n";
    }
    
    if ($options->{'-c'}) {
	open(my $fh, '>', $wpath."/.alsoadd") or die "Could not open file  $!";
	print $fh $options->{'-c'};
	close($fh);
        my @chars = split(',',lc($options->{'-c'}));
        foreach my $c (@chars) {
           if ($c eq 'uk') { $c = 'gb';};
           push @countries, uc($c);
        }
    }
}

sub trim {
    $_=$_[0];
    s/^\s+//;
    s/\s+$//;
    return $_
}

1;
