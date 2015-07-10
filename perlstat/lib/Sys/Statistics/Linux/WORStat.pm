
package Sys::Statistics::Linux::WORStat;

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

    my $config_file='/etc/voipnow/queue.conf';
    my %Config = ();
    &parse_config_file ($config_file, \%Config);
     my $uri = 'amqp://'.$Config{'amqpuser'}.':'.$Config{'amqppass'}.'@'.$Config{'amqphost'}.':'.$Config{'amqpport'}.'/voipnow';
     my $data =`celery -b $uri inspect stats | grep -v 'OK'`;
     my $results = decode_json( $data );
     my %stats;
        $stats{"Rusage.MaxRSS"} = $results->{'rusage'}->{'maxrss'};
        $stats{"Rusage.MinFLT"} = $results->{'rusage'}->{'minflt'};
        if ($results->{'total'}->{'voipnow.savetocallhistory'}){
                $stats{"Total.VoipNow.SaveToCallHistory"} = $results->{'total'}->{'voipnow.savetocallhistory'};
        }
        if ($results->{'total'}->{'voipnow.un'}){
                $stats{"Total.VoipNow.SaveToCallHistory"} = $results->{'total'}->{'voipnow.un'};
        }
        $stats{"Writes.Avg"} = $results->{'pool'}->{'writes'}->{'avg'};
        $stats{"Writes.All"} = $results->{'pool'}->{'writes'}->{'all'};

        $stats{"Writes.InQueues.Active"} = $results->{'pool'}->{'writes'}->{'inqueues'}->{'active'};
        $stats{"Writes.InQueues.Total"} = $results->{'pool'}->{'writes'}->{'inqueues'}->{'total'};

    return \%stats;
}


1;
