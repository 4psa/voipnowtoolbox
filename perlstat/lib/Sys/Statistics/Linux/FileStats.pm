=head1 NAME

Sys::Statistics::Linux::FileStats - Collect linux file statistics.

=head1 SYNOPSIS

    use Sys::Statistics::Linux::FileStats;

    my $lxs  = Sys::Statistics::Linux::FileStats->new;
    my $stat = $lxs->get;

=head1 DESCRIPTION

Sys::Statistics::Linux::FileStats gathers file statistics from the virtual F</proc> filesystem (procfs).

For more information read the documentation of the front-end module L<Sys::Statistics::Linux>.

=head1 FILE STATISTICS

Generated by F</proc/sys/fs/file-nr>, F</proc/sys/fs/inode-nr> and F</proc/sys/fs/dentry-state>.

    fhalloc    -  Number of allocated file handles.
    fhfree     -  Number of free file handles.
    fhmax      -  Number of maximum file handles.
    inalloc    -  Number of allocated inodes.
    infree     -  Number of free inodes.
    inmax      -  Number of maximum inodes.
    dentries   -  Dirty directory cache entries.
    unused     -  Free diretory cache size.
    agelimit   -  Time in seconds the dirty cache entries can be reclaimed.
    wantpages  -  Pages that are requested by the system when memory is short.

=head1 METHODS

=head2 new()

Call C<new()> to create a new object.

    my $lxs = Sys::Statistics::Linux::FileStats->new;

It's possible to set the path to the proc filesystem.

     Sys::Statistics::Linux::FileStats->new(
        files => {
            # This is the default
            path     => '/proc',
            file_nr  => 'sys/fs/file-nr',
            inode_nr => 'sys/fs/inode-nr',
            dentries => 'sys/fs/dentry-state',
        }
    );

=head2 get()

Call C<get()> to get the statistics. C<get()> returns the statistics as a hash reference.

    my $stat = $lxs->get;

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

package Sys::Statistics::Linux::FileStats;

use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.09';

sub new {
    my $class = shift;
    my $opts  = ref($_[0]) ? shift : {@_};

    my %self = (
        files => {
            path     => '/proc',
            file_nr  => 'sys/fs/file-nr',
            inode_nr => 'sys/fs/inode-nr',
            dentries => 'sys/fs/dentry-state',
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
    my $stats = { };

    $self->{stats} = $stats;
    $self->_get_file_nr;
    $self->_get_inode_nr;
    $self->_get_dentries;

    return $stats;
}

sub _get_file_nr {
    my $self  = shift;
    my $class = ref $self;
    my $file  = $self->{files};
    my $stats = $self->{stats};

    my $filename = $file->{path} ? "$file->{path}/$file->{file_nr}" : $file->{file_nr};
    open my $fh, '<', $filename or croak "$class: unable to open $filename ($!)";
    @$stats{qw(fhalloc fhfree fhmax)} = (split /\s+/, <$fh>)[0..2];
    close($fh);
}

sub _get_inode_nr {
    my $self  = shift;
    my $class = ref $self;
    my $file  = $self->{files};
    my $stats = $self->{stats};

    my $filename = $file->{path} ? "$file->{path}/$file->{inode_nr}" : $file->{inode_nr};
    open my $fh, '<', $filename or croak "$class: unable to open $filename ($!)";
    @$stats{qw(inalloc infree)} = (split /\s+/, <$fh>)[0..1];
    $stats->{inmax} = $stats->{inalloc} + $stats->{infree};
    close($fh);
}

sub _get_dentries {
    my $self  = shift;
    my $class = ref $self;
    my $file  = $self->{files};
    my $stats = $self->{stats};

    my $filename = $file->{path} ? "$file->{path}/$file->{dentries}" : $file->{dentries};
    open my $fh, '<', $filename or croak "$class: unable to open $filename ($!)";
    @$stats{qw(dentries unused agelimit wantpages)} = (split /\s+/, <$fh>)[0..3];
    close($fh);
}

1;
