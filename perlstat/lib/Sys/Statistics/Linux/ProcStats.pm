=head1 NAME

Sys::Statistics::Linux::ProcStats - Collect linux process statistics.

=head1 SYNOPSIS

    use Sys::Statistics::Linux::ProcStats;

    my $lxs = Sys::Statistics::Linux::ProcStats->new;
    $lxs->init;
    sleep 1;
    my $stat = $lxs->get;

Or

    my $lxs = Sys::Statistics::Linux::ProcStats->new(initfile => $file);
    $lxs->init;
    my $stat = $lxs->get;

=head1 DESCRIPTION

Sys::Statistics::Linux::ProcStats gathers process statistics from the virtual F</proc> filesystem (procfs).

For more information read the documentation of the front-end module L<Sys::Statistics::Linux>.

=head1 IMPORTANT

I renamed key C<procs_blocked> to C<blocked>!

=head1 LOAD AVERAGE STATISTICS

Generated by F</proc/stat> and F</proc/loadavg>.

    new       -  Number of new processes that were produced per second.
    runqueue  -  The number of currently executing kernel scheduling entities (processes, threads).
    count     -  The number of kernel scheduling entities that currently exist on the system (processes, threads).
    blocked   -  Number of processes blocked waiting for I/O to complete (Linux 2.5.45 onwards).
    running   -  Number of processes in runnable state (Linux 2.5.45 onwards).

=head1 METHODS

=head2 new()

Call C<new()> to create a new object.

    my $lxs = Sys::Statistics::Linux::ProcStats->new;

Maybe you want to store/load the initial statistics to/from a file:

    my $lxs = Sys::Statistics::Linux::ProcStats->new(initfile => '/tmp/procstats.yml');

If you set C<initfile> it's not necessary to call sleep before C<get()>.

It's also possible to set the path to the proc filesystem.

     Sys::Statistics::Linux::ProcStats->new(
        files => {
            # This is the default
            path    => '/proc',
            loadavg => 'loadavg',
            stat    => 'stat',
        }
    );

=head2 init()

Call C<init()> to initialize the statistics.

    $lxs->init;

=head2 get()

Call C<get()> to get the statistics. C<get()> returns the statistics as a hash reference.

    my $stat = $lxs->get;

=head2 raw()

Get raw values.

=head1 EXPORTS

No exports.

=head1 SEE ALSO

B<proc(5)>

=head1 REPORTING BUGS

Please report all bugs to <jschulz.cpan(at)bloonix.de>.

=head1 AUTHOR

Jonny Schulz <jschulz.cpan(at)bloonix.de>.

=head1 COPYRIGHT

Copyright (c) 2006, 2007 by Jonny Schulz. All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

package Sys::Statistics::Linux::ProcStats;

use strict;
use warnings;
use Carp qw(croak);
use Time::HiRes;

our $VERSION = '0.20';

sub new {
    my $class = shift;
    my $opts  = ref($_[0]) ? shift : {@_};

    my %self = (
        files => {
            path    => '/proc',
            loadavg => 'loadavg',
            stat    => 'stat',
        }
    );

    if (defined $opts->{initfile}) {
        require YAML::Syck;
        $self{initfile} = $opts->{initfile};
    }

    foreach my $file (keys %{ $opts->{files} }) {
        $self{files}{$file} = $opts->{files}->{$file};
    }

    return bless \%self, $class;
}

sub init {
    my $self = shift;

    if ($self->{initfile} && -r $self->{initfile}) {
        $self->{init} = YAML::Syck::LoadFile($self->{initfile});
        $self->{time} = delete $self->{init}->{time};
    } else {
        $self->{time} = Time::HiRes::gettimeofday();
        $self->{init} = $self->_load;
    }
}

sub get {
    my $self  = shift;
    my $class = ref $self;

    if (!exists $self->{init}) {
        croak "$class: there are no initial statistics defined";
    }

    $self->{stats} = $self->_load;
    $self->_deltas;

    if ($self->{initfile}) {
        $self->{init}->{time} = $self->{time};
        YAML::Syck::DumpFile($self->{initfile}, $self->{init});
    }

    return $self->{stats};
}

sub raw {
    my $self = shift;
    my $stat = $self->_load;

    return $stat;
}

#
# private stuff
#

sub _load {
    my $self  = shift;
    my $class = ref $self;
    my $file  = $self->{files};
    my $lavg  = $self->_procs;

    my $filename = $file->{path} ? "$file->{path}/$file->{loadavg}" : $file->{loadavg};
    open my $fh, '<', $filename or croak "$class: unable to open $filename ($!)";
    ($lavg->{runqueue}, $lavg->{count}) = (split m@/@, (split /\s+/, <$fh>)[3]);
    close($fh);

    return $lavg;
}

sub _procs {
    my $self  = shift;
    my $class = ref $self;
    my $file  = $self->{files};
    my %stat  = ();

    my $filename = $file->{path} ? "$file->{path}/$file->{stat}" : $file->{stat};
    open my $fh, '<', $filename or croak "$class: unable to open $filename ($!)";

    while (my $line = <$fh>) {
        if ($line =~ /^processes\s+(\d+)/) {
            $stat{new} = $1;
        } elsif ($line =~ /^procs_(blocked|running)\s+(\d+)/) {
            $stat{$1} = $2;
        }
    }

    close($fh);
    return \%stat;
}

sub _deltas {
    my $self  = shift;
    my $class = ref $self;
    my $istat = $self->{init};
    my $lstat = $self->{stats};
    my $time  = Time::HiRes::gettimeofday();
    my $delta = sprintf('%.2f', $time - $self->{time});
    $self->{time} = $time;

    if (!defined $istat->{new} || !defined $lstat->{new}) {
        croak "$class: not defined key found 'new'";
    }
    if ($istat->{new} !~ /^\d+\z/ || $lstat->{new} !~ /^\d+\z/) {
        croak "$class: invalid value for key 'new'";
    }

    my $new_init = $lstat->{new};

    if ($lstat->{new} == $istat->{new} || $istat->{new} > $lstat->{new}) {
        $lstat->{new} = sprintf('%.2f', 0);
    } elsif ($delta > 0) {
        $lstat->{new} = sprintf('%.2f', ($new_init - $istat->{new}) / $delta );
    } else {
        $lstat->{new} = sprintf('%.2f', $new_init - $istat->{new});
    }

    $istat->{new} = $new_init;
}

1;