
package Sys::Statistics::Linux::NFScStat;

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
            nfsc => 'net/rpc/nfs',
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
    my %nfsc  = ();

    my $filename = $file->{path} ? "$file->{path}/$file->{nfsc}" : $file->{nfsc};
    if (-e $filename) {
	open my $fh, '<', $filename or croak "$class: unable to open $filename ($!)";
	while (my $line = <$fh>) {
	    if ($line =~ /rpc/) {
		($nfsc{calls},$nfsc{retrans},$nfsc{authrefrsh}) = (split /\s+/, $line)[1..3];
	    }
	}
	close($fh);
	return \%nfsc;
    }

}

1;
