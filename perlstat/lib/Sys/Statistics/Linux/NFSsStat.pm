
package Sys::Statistics::Linux::NFSsStat;

use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $opts  = ref($_[0]) ? shift : {@_};

    my %self = (
        files => {
            path    => '/proc',
            nfss => 'net/rpc/nfsd',
        }
    );

    foreach my $file (keys %{ $opts->{files} }) {
        $self{files}{$file} = $opts->{files}->{$file};
    }

    return bless \%self, $class;
}

sub get {
    my $self  = shift;
    my $class = ref $self;
    my $file  = $self->{files};
    my %nfss  = ();

    my $filename = $file->{path} ? "$file->{path}/$file->{nfss}" : $file->{nfss};
    if (-e $filename) {
	open my $fh, '<', $filename or croak "$class: unable to open $filename ($!)";
        while (my $line = <$fh>) {
	    if ($line =~ /rpc/) {
		($nfss{calls},$nfss{badcalls},$nfss{badclnt},$nfss{badauth},$nfss{xdrcall}) = (split /\s+/, $line)[1..5];
	    }
	    if ($line =~ /io/) {
		($nfss{"io.read"},$nfss{"io.write"}) = (split /\s+/, $line)[1..2];
	    }
	    if ($line =~ /rc/) {
		($nfss{"rc.cache_hits"},$nfss{"rc.cache_misses"}, $nfss{"rc.nocache"}) = (split /\s+/, $line)[1..3];
	    }
	    if ($line =~ /th/) {
		($nfss{"theard.total"},$nfss{"theard.allinuse"}) = (split /\s+/, $line)[1..2];
	    }
	    if ($line =~ /net/) {
		($nfss{"net.cnt"},$nfss{"net.udpcnt"},$nfss{"net.tcpcnt"},$nfss{"net.tcpcon"} ) = (split /\s+/, $line)[1..4];
	    }
	    if ($line =~ /ra/) {
		($nfss{"ra.cache-size"}) = (split /\s+/, $line)[1];
	    }
	}
	close($fh);
	return \%nfss;
    }
}

1;
