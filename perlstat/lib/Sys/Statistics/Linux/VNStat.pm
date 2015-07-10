
package Sys::Statistics::Linux::VNStat;

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

    my @results = `mysql -u$Config{'dbuser'} -p$Config{'dbpass'} -h$Config{'dbhost'} -P$Config{'dbport'} voipnow -nse 'select count(*), type from extension group by type'`;
    my @channels = `mysql -u$Config{'dbuser'} -p$Config{'dbpass'} -h$Config{'dbhost'} -P$Config{'dbport'} voipnow -nse 'select count(*), type from channel where status=1  AND (channel.name != "chan_webrtc" ) group by type'`;
    my @hresults = `hr-cli -h $Config{'rhost'} -p $Config{'rport'} -n $Config{'rdb'} -dp $Config{'rpass'} keys rtl:sta:ext:*`;
    my @trunks = `mysql -u$Config{'dbuser'} -p$Config{'dbpass'} -h$Config{'dbhost'} -P$Config{'dbport'} voipnow -nse " SELECT client_prefs.value, client.id as client_id,  extension.extended_number, client.name FROM extension, client_prefs, extension_prefs, client WHERE extension.id = extension_prefs.extension_id AND client.id = extension.client_id AND client.status = '1' AND client_prefs.client_id = extension.client_id AND client_prefs.param = 'max_concurent' AND extension_prefs.param = 'pbx_connected' AND extension_prefs.value = '1' "`;
    my $counter=0;

    for(@hresults) {
    	my @values = split(':',$_);
    	if ($values[3]) {
		my $command = "hr-cli -h $Config{'rhost'} -p $Config{'rport'} -n $Config{'rdb'} -dp $Config{'rpass'} mhmget rtl:sta:ext:".trim($values[3])." '' 'stl' ";
		my @exts = `$command`;
		for (@exts) {
		    my $state = $_;
		    if (trim($state) eq "online") {
			++$counter;		
		    }
		}    
	}
    }
    my (%stats,$tip,$t);
    $stats{"extensions.online"} = $counter;
    my @q= ("select count(*) from client where level=10" ,"select count(*) from client where level=50 ", "select count(*) from client where level=100");
    my $all=0;

    my $taccounts =0;
    foreach my $query (@q) {
        ++$all;
	my @accounts = `mysql -u$Config{'dbuser'} -p$Config{'dbpass'} -h$Config{'dbhost'} -P$Config{'dbport'} voipnow -nse '$query'`;
	for (@accounts) {
            if ($all == 1){
                $tip="sp";
            } elsif ($all == 2){
                $tip="org";
            } elsif( $all == 3){
                $tip="user";
            }
	    $stats{"accounts.$tip"} = trim($_);
	    $taccounts += $_;
        }
    }
    $stats{"accounts.total_number"} = trim($taccounts);

    my $ttrunks=0;
    for (@trunks) {
	my @values = split(' ',$_);
	$stats{"extensions.siptrunk.".trim($values[2])} = trim($values[0]);
	$ttrunks += trim($values[0]);
    }
    $stats{"extensions.siptrunk.total_channels"} = trim($ttrunks);

    my $textensions =0;
    for(@results) {
    	my @values = split(' ',$_);
	$stats{"extensions.".trim($values[1])} = trim($values[0]);
	$textensions += trim($values[0]);
    }
    $stats{"extensions.total_number"} = trim($textensions);

    my $tchannels=0;
    for(@channels) {
    	my @values = split(' ',$_);
	$stats{"channels.".trim($values[1])} = trim($values[0]);
	$tchannels += trim($values[0]);
    }
    $stats{"channels.total_number"} = trim($tchannels);

    return \%stats;
}



1;
