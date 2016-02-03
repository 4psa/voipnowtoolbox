#!/usr/bin/perl

use strict;
use warnings;
use DBD::mysql;
use JSON;
#use Data::Dumper qw(Dumper);

my %Config = ();
my $config_file='/etc/voipnow/main.conf';
my $sqlbase = '/etc/voipnow/sqldbase.conf';

&_parse_config_file ($config_file, \%Config);

my $tfile;
my $dsn = "dbi:mysql:$Config{'db'}:$Config{'dbhost'}:$Config{'dbport'}";
my $dbh = DBI->connect($dsn, $Config{'dbuser'}, $Config{'dbpass'});

    my($p1,$p2,$p3) = @ARGV;
    if (not defined $p1) {
        $p1 = "usage";
    }
    if ($p1 eq "usage" || $p1 eq ''){
	&_usage;
    } elsif($p1 eq 'share'){
	if ($p2 eq '' || $p3 eq '') {
	    &_usage;
	} else {

	    unless ( $p3 =~ /^[+-]?\d+$/ ) { print "AccountID should be a numric value, $p3 it is not\n\n"; exit; };
	    unless ( $p2 =~ /^[+-]?\d+$/ ) { print "AccountID should be a numric value, $p2 it is not\n"; exit; };

	    my $c = "select id from client where id=$p3";
    	    my ($cid) =`mysql -u$Config{'dbuser'} -p$Config{'dbpass'} -h$Config{'dbhost'} -P$Config{'dbport'} $Config{'db'} -nse "$c"`;
	    my $t = "select id from time_interval where id=$p2";
    	    my ($tid) =`mysql -u$Config{'dbuser'} -p$Config{'dbpass'} -h$Config{'dbhost'} -P$Config{'dbport'} $Config{'db'} -nse "$t"`;

    	    if ($cid && $tid) {
		my $tdata = &process($p2);
		&share_timeinteval($tdata);
	    } else {
		print "Wrong AccountId: $p3 or Time Interval Id $p2\n";
		exit;
	    }
	}
    } elsif($p1 eq 'dump'){
	if ($p2 eq '') {
	    &_usage;
	} else {

	    unless ($p2 =~ /^[+-]?\d+$/ ) { print "Time interval ID should be a numric value. $p2 it is not\n"; exit; };
	     my $c = "select id from time_interval where id=$p2";
	     my ($cid) =`mysql -u$Config{'dbuser'} -p$Config{'dbpass'} -h$Config{'dbhost'} -P$Config{'dbport'} $Config{'db'} -nse "$c"`;
            if ($cid) {
		my $tdata = &process($p2);
		if ($p3) {
		    $tfile = $p3.".json";
		} else {
		    $tfile = 'time_interval_dump.json';
		}
		open(my $fh, '>', $tfile) or die "Could not open file '$tfile' $!";
		my $json = JSON->new->allow_nonref;
		my $json_text = $json->encode($tdata);
		print $fh $json_text;
		close $fh;
		print "Time Interval $tdata->{'name'} saved in $tfile\n";

	    } else {
		print "Wrong Time Interval Id: $p2\n";
                exit;
	    }
	}
    } elsif($p1 eq 'restore'){
	if ($p2 eq '') {
	    &_usage;
	} else {
	    if ($p3) {
		$tfile = $p3;
	    } else {
		$tfile = 'time_interval_dump.json';
	    }

	    unless ($p2 =~ /^[+-]?\d+$/ ) { print "AccountId should be a numeric value. $p2 it is not\n"; exit; };
	    my $c = "select id from client where id=$p2";
    	    my ($cid) =`mysql -u$Config{'dbuser'} -p$Config{'dbpass'} -h$Config{'dbhost'} -P$Config{'dbport'} $Config{'db'} -nse "$c"`;
    	    if ($cid) {
		my $json = `cat $tfile`;
		&restore_timeinteval($json);
	    } else {
		print "Wrong AccountId: $p2\n";
		exit;
	    }

	}
    } else {
       &_usage;
    }


sub share_timeinteval {
    my ($data) = @_;
    my $json = JSON->new->allow_nonref;
    my $json_text = $json->encode($data);
    my $curd = time();
    my $tq = "insert into time_interval values('','".$data->{'name'}."','".$p3."','".$data->{'cr_date'}."',FROM_UNIXTIME(".$curd."),'".$data->{'type'}."','".$data->{'timezone_id'}."')";
    my $sth = $dbh->prepare($tq);
    $sth->execute();

    my $q="select id from time_interval where name='".$data->{'name'}."' and client_id='".$p3."' and timezone_id='".$data->{'timezone_id'}."' and mod_date=FROM_UNIXTIME(".$curd.")";
    my ($pid) =`mysql -u$Config{'dbuser'} -p$Config{'dbpass'} -h$Config{'dbhost'} -P$Config{'dbport'} $Config{'db'} -nse "$q"`;
    for ( my $i = 0; $i <= $#{ $data->{'data'} }; $i++ ){
	my $tq = "insert into time_interval_data values('','".trim($pid)."','".$data->{'data'}->[$i]->{'start_time'}."','".$data->{'data'}->[$i]->{'end_time'}."','".$data->{'data'}->[$i]->{'start_wkday'}."','".$data->{'data'}->[$i]->{'end_wkday'}."','".$data->{'data'}->[$i]->{'start_day'}."','".$data->{'data'}->[$i]->{'end_day'}."','".$data->{'data'}->[$i]->{'month'}."')";
	my $sth = $dbh->prepare($tq);
	$sth->execute();
    }
    print "TimeInterval $data->{name} has been added on accountID: $p3\n";
    
}

sub restore_timeinteval {
	my ($data) = @_;
	my $json = JSON->new->allow_nonref;
	my $json_text = $json->decode($data);
        my $curd = time();
	my $tq = "insert into time_interval values('','".$json_text->{'name'}."','".$p2."','".$json_text->{'cr_date'}."',FROM_UNIXTIME(".$curd."),'".$json_text->{'type'}."','".$json_text->{'timezone_id'}."')";
        my $sth = $dbh->prepare($tq);
    	$sth->execute();

        my $q="select id from time_interval where name='".$json_text->{'name'}."' and client_id='".$p2."' and timezone_id='".$json_text->{'timezone_id'}."' and mod_date=FROM_UNIXTIME(".$curd.")";
	my ($pid) =`mysql -u$Config{'dbuser'} -p$Config{'dbpass'} -h$Config{'dbhost'} -P$Config{'dbport'} $Config{'db'} -nse "$q"`;
        for ( my $i = 0; $i <= $#{ $json_text->{'data'} }; $i++ ){
	    my $tq = "insert into time_interval_data values('','".trim($pid)."','".$json_text->{'data'}->[$i]->{'start_time'}."','".$json_text->{'data'}->[$i]->{'end_time'}."','".$json_text->{'data'}->[$i]->{'start_wkday'}."','".$json_text->{'data'}->[$i]->{'end_wkday'}."','".$json_text->{'data'}->[$i]->{'start_day'}."','".$json_text->{'data'}->[$i]->{'end_day'}."','".$json_text->{'data'}->[$i]->{'month'}."')";
	    my $sth = $dbh->prepare($tq);
	    $sth->execute();
	}
        print "TimeInterval $json_text->{name} has been restored on accountID: $p2\n";

}    

sub _usage {
	print "Usage:\n";
        print "Available options: \n";
        print "\t Share a time interval with a differnet account \n";
        print "\t\tperl $0 share <time_interval_id> <client_id> \n";
	print "\t\tE.G.: perl $0 share 2 4\n\n";
        print "\t Dump a time interval to a file \n";
        print "\t\tperl $0 dump <time_interval_id> <file_name or empty>\n";
	print "\t\tE.G.: perl $0 dump 2 afterhours\n\n";
        print "\t Restore a time interval from a file \n";
        print "\t\tperl $0 restore <client_id> <file_name or empty>\n";
	print "\t\tE.G.: perl $0 restore 2 afterhours.json\n";

}

sub process {
    my ($rtid) = @_;
    my ($id,$name,$client_id,$cr_date,$mod_date,$type,$timezone_id,$td_id,$time_interval_id,$start_time,$end_time,$start_wkday,$end_wkday,$start_day,$end_day,$month,@rarray);
    my $q = "select * from time_interval where id=$rtid";
    my $sth = $dbh->prepare($q);
    $sth->execute();
    $sth->bind_columns(\($id,$name,$client_id,$cr_date,$mod_date,$type,$timezone_id));

    while ( $sth->fetch) {
	my $dq = "select * from time_interval_data where time_interval_id=$id";
        my $sth = $dbh->prepare($dq);
	$sth->execute();
	$sth->bind_columns(\($td_id,$time_interval_id,$start_time,$end_time,$start_wkday,$end_wkday,$start_day,$end_day,$month ));
        while ( $sth->fetch) {
	    push(
		@rarray, {
		    "td_id" => $td_id,
            	    "time_interval_id" => $time_interval_id,
            	    "start_time" => $start_time,
            	    "end_time" => $end_time,
            	    "start_wkday" => $start_wkday,
            	    "end_wkday" => $end_wkday,
            	    "start_day" => $start_day,
            	    "end_day" => $end_day,
            	    "month" => $month,
            	}
	    );
	}
    }

    my $arr = {
	'id' => $id,
	'name' => $name,
	'client_id' => $client_id,
	'cr_date' => $cr_date,
	'mod_date' => $mod_date,	
	'type' => $type,	
	'timezone_id' => $timezone_id,	
    	'data' => \@rarray, 
        };

    return $arr;
}



sub _parse_config_file {
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
            }
    }
    close(CONFIG);

}


sub trim {
################################################
#  Classic trim                                #
################################################
    $_=$_[0];
    s/^\s+//;
    s/\s+$//;
    return $_
}
