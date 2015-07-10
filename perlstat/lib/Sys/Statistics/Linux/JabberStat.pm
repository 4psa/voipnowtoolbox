
package Sys::Statistics::Linux::JabberStat;

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
    my $nnode = &nodeid;
    my $node;

    if ($version < 350) {
        $node ='ejabberd';
    } else {
	$node = trim($nnode);
    }

    my @results = `/usr/sbin/ejabberdctl --node $node\@localhost connected_users_number`;
    my %stats;
    for(@results) {
	my @values = split(' ',$_);
	if (trim($values[0]) =~ m{falied}gs){
	exit;
	    print 'shit';

	}
    $stats{trim('Connected_Users')} = trim($values[0]);
    }
    return \%stats;
}

1;
