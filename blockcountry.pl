#!/usr/bin/perl

#Copyright devel@4psa.com
#Requirements (from epel):
# yum install perl-Locale-SubCountry   perl-libwww-perl 

use strict;
use LWP::UserAgent;
use Locale::SubCountry;
$| = 1;

my $url = "http://www.ipdeny.com/ipblocks/data/countries/";
my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;

my $world = Locale::SubCountry::World->new();
my %all_country_keyed_by_code   = $world->code_full_name_hash;

#configure countries you want to block
my @countries = (
        "PS",
        "SA",
        "TR",
        );

my $policy = "reject"; # possible value: accept/reject
# in case accpet is used the global policy in the server must be set on DROP

unless (-e '/usr/sbin/ipset' && -e '/usr/sbin/iptables') {
    print "Error: ipset and iptables rpm packages must be installed!\n run: \n\t yum install ipset iptables \n\n before running this script\n";
    exit 1;
}

foreach my $country (@countries) {
        my $country_name = $all_country_keyed_by_code{$country};
        $country_name =~ s/\,//g;
        $country_name =~ s/\ /_/g;
        open(my $fh, '>', $country_name.".conf") or die "Could not open file  $!";
        print $fh "create $country_name hash:net family inet hashsize 2048 maxelem 65536 \n";
        my $response = $ua->get($url."/".lc($country).".zone");

        if ($response->is_success) {
            my @lines = split /\n/, $response->decoded_content;
            print "Write set files and enable rules for $all_country_keyed_by_code{$country} ";
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
    system ("/usr/sbin/ipset restore -! < " .trim($set).".conf");
    my $cip = `/usr/sbin/iptables -nL | grep "$set" | awk '{print $4}'`;
    if ($cip) {
        if ($policy eq 'reject') {
            system("/usr/sbin/iptables -D INPUT -m set --match-set ". trim($set). " src -j REJECT --reject-with icmp-host-unreachable");
        } elsif ($policy eq 'accept') {
            system("/usr/sbin/iptables -D INPUT -m set --match-set ". trim($set). " src -j ACCEPT");
        }
    }
    if ($policy eq 'reject') {
        system("/usr/sbin/iptables -I INPUT -m set --match-set ". trim($set). " src -j REJECT --reject-with icmp-host-unreachable");
    } elsif ($policy eq 'accept') {
        system("/usr/sbin/iptables -I INPUT -m set --match-set ". trim($set). " src -j ACCEPT");
    }

    print "....done\n";
}

sub trim {
    $_=$_[0];
    s/^\s+//;
    s/\s+$//;
    return $_
}

1;
