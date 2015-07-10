#!/usr/bin/perl

package aModule;

use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

our $VERSION     = 1.00;

@ISA         = qw(Exporter);
@EXPORT      = qw(trim parse_config_file version nodeid);
@EXPORT_OK   = qw(trim parse_config_file version nodeid);
                 
sub trim {
    $_=$_[0];
    s/^\s+//;
    s/\s+$//;
    return $_
}

sub version {
    my @version =`cat /usr/local/voipnow/.version`;
    my $vnvers;
    if ($version[0]) {
	my @ver = split(' ',$version[0]);
	$ver[0] =~ s/\.//g;
	$vnvers = $ver[0];
    } else {
	$vnvers=350;
    }
    return $vnvers;
}


sub nodeid {
    my $nnode =`cat /etc/voipnownode/nodeid`;
    return $nnode;
}


sub parse_config_file {
    my $sqlbase = '/etc/voipnow/sqldbase.conf';
    my $disdbase = '/etc/voipnow/disdbase.conf';
    my $esrole = '/etc/voipnow/es.conf';
    my $qrole = '/etc/voipnow/amqp.conf';
    my ($config_line, $CName, $Value);
    my ($File, $Config) = @_;
    open (CONFIG, "$File") or die "ERROR: Config file not found : $File";
    while (<CONFIG>) {
        $config_line=$_;
        trim ($config_line);
        $config_line =~ s/^\s*//;
        $config_line =~ s/\s*$//;
        if ( ($config_line !~ /^#/) && ($config_line ne "")){
                my @param = split (/:/, $config_line);
                my @value = split (/\s+/, $param[0]);
                if (trim($value[0]) eq "DB_CREDENTIALS") {
                    $$Config{dbuser} = $param[1];
                    $$Config{dbpass} = $param[2];
                    $$Config{db} = $param[3];

                    open (SQLCONFIG, $sqlbase) or die "ERROR: Config file not found";
                    while (<SQLCONFIG>) {
                        my $sfile = trim($_);
                        if ( ($sfile !~ /^#/) && ($sfile ne "")){
                            my @svalue = split (/\s+/, trim($sfile));
                            if (trim($svalue[0]) eq "DB_MASTER") {
                                my @slines = split (/:/, trim($svalue[1]));
                                $$Config{dbhost} = $slines[1];
                                $$Config{dbport} = $slines[2];
                            }
                        }
                    }
                close(SQLCONFIG);
                }
                 if (trim($value[0]) eq "DISDBASE_CREDENTIALS") {
                    my ($port,$host);
                    $$Config{rdb} = $param[3];
                    $$Config{rpass} = $param[2];
                    open (DISCONFIG, $disdbase) or die "ERROR: Config file not found";
                    while (<DISCONFIG>) {
                        my $nfile = trim($_);
                        if ( ($nfile !~ /^#/) && ($nfile ne "")){
                            my @lines = split (/:/, $nfile);
                            $$Config{rhost} = $lines[3];
                            $$Config{rport} = $lines[4];

                        }
                    }
                close(DISCONFIG);
                }
		 if (trim($value[0]) eq "ES_CREDENTIALS") {
                    $$Config{esuser} = $param[1];
                    $$Config{espass} = $param[2];

                    open (ESROLE, $esrole) or die "ERROR: Config file not found";
                    while (<ESROLE>) {
                        my $sfile = trim($_);
                        if ( ($sfile !~ /^#/) && ($sfile ne "")){
                            my @svalue = split (/\s+/, trim($sfile));
                            if (trim($svalue[0]) eq "ES_HOST") {
                                my @slines = split (/:/, trim($svalue[1]));
                                $$Config{eshost} = $slines[1];
                                $$Config{esport} = $slines[2];
                            }
                        }
                    }
                close(ESROLE);
                }
		if (trim($value[0]) eq "AMQP_CREDENTIALS") {
                    $$Config{amqpuser} = $param[1];
                    $$Config{amqppass} = $param[2];
                    open (QROLE, $qrole) or die "ERROR: Config file not found";
                    while (<QROLE>) {
                        my $sfile = trim($_);
                        if ( ($sfile !~ /^#/) && ($sfile ne "")){
                            my @svalue = split (/\s+/, trim($sfile));
                            if (trim($svalue[0]) eq "AMQP_HOST") {
                                my @slines = split (/:/, trim($svalue[1]));
                                $$Config{amqphost} = $slines[1];
                                $$Config{amqpport} = $slines[2];
                            }
                        }
                    }
                close(QROLE);
                }



        }
    }
    close(CONFIG);
}



1;
