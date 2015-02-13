#!/usr/bin/perl	

# require:
#	perl-DBD-mysql 
#	perl-File-Copy-Recursive
#	perl-File-Remove
#	perl-DateTime
#	perl-Archive-Tar
#	perl-DBD-mysql

use strict;
use DBD::mysql; 
use DateTime;
use Archive::Tar;
use File::Copy::Recursive qw(fcopy pathrm pathmk);
use File::Remove qw(remove);

# --- set disabled to 0 otherwise files are NOT removed
my $disabled = 1;

# --- recording older than this values will be removed if $disabled is set to 0
my $older = 1; #month

#------- keep files into a backup: 1 - yes /0 -no
my $archive_files = 1;

#------- VoipNow config files and DB Connection ------
my %Config = ();
my $config_file='/etc/voipnow/main.conf';
my $sqlbase = '/etc/voipnow/sqldbase.conf';
&parse_config_file ($config_file, \%Config);

my $cdt = DateTime->from_epoch( epoch => time() );
$cdt->set_time_zone('UTC');

my $y = $older/12;
my $year = $cdt->clone->subtract(years => $y)->strftime("%Y");
my $month = $cdt->clone->subtract(months => $older)->strftime("%m");
my $ndate=$year."-".$month."-".$cdt->day;

my $backupdir = "/backup/".$cdt->ymd."-".$cdt->hms;

my $dsn = "dbi:mysql:$Config{'db'}:$Config{'dbhost'}:$Config{'dbport'}";
my $dbh = DBI->connect($dsn, $Config{'dbuser'}, $Config{'dbpass'});

#if ($ARGV[0] eq '') {

&recordings;

#}

#---------------------------------

sub recordings {
    
    my $tar = Archive::Tar->new();
    my $tarname = "older-than-$ndate.tar";
    my $dirpath = "/$backupdir/" or die $!;
    if ($archive_files) {
	if ( -d $dirpath ) {
            pathrm( $dirpath, 1 );
        }
	pathmk( $dirpath, 1 ) or die "wrong $!";
    }
    my (@dfiles,@qry,$i,$eid,$extended_number, $rid, $rse,$rext, $cr_date, $flow,$filename,$filesize,$unread,$callerid,$party,$length,$callid,$info,$az );
    my $rquery=("select extension.id,extension.extended_number, extension_recording.id, extension_recording.se,extension_recording.ext, extension_recording.cr_date, extension_recording.flow, extension_recording.filename,
		    extension_recording.filesize,extension_recording.unread,extension_recording.callerid,extension_recording.party,extension_recording.length,extension_recording.callid,extension_recording.info,extension_recording.az
		    from client,extension,extension_recording where extension_recording.extension_id=extension.id and extension.client_id=client.id and extension_recording.se='posix' and extension_recording.cr_date < '".$ndate." ".$cdt->hms."'");
    my $rth = $dbh->prepare($rquery);
    $rth->execute();
    $rth->bind_columns(\($eid,$extended_number, $rid, $rse,$rext,$cr_date,$flow,$filename,$filesize,$unread,$callerid,$party,$length,$callid,$info,$az));

    if ($archive_files) {
        open (FILE, "> $dirpath/$tarname.log");
    }

    while ( $rth->fetch) {
        if ($archive_files) {
	    print FILE 'insert into extension_recordings value ("'.$rid.'","'.$eid.'","'.$flow.'","'.$filename.'","'.$filesize.'","'.$unread.'","'.$cr_date.'","'.$callerid.'","'.$party.'","'.$length.'","'.$callid.'","'.$info.'","'.$rext.'","'.$rse.'","'.$az.'")'."\n";
	}
	push (@dfiles,"/var/spool/asterisk/monitor/$extended_number/$rid.$rext");
	push (@qry,"delete from extension_recording where id=$rid");
    }

    if ($archive_files) {
	$tar->add_files(@dfiles);
        $tar->write( $dirpath.'/'.$tarname );	
    }

    print "---------------------------------------------\n";
    print "   Removing files older that $ndate 		\n";
    print "---------------------------------------------\n";

    my $size = @qry;
    for ($i=0; $i<$size;$i++) {
	my $sth = $dbh->prepare($qry[$i]);
        if (-e $dfiles[$i] and -s $dfiles[$i]){
    	    unless ($disabled) {
	        print "Removed $dfiles[$i] ....done!\n";
		unlink $dfiles[$i];
	    }
	}

	unless ($disabled) {
		print "Removed entry from mysql for file $rid.$rext ...done!\n";
        	$sth->execute();
	}
    }

  close (FILE);
}


sub parse_config_file {
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

