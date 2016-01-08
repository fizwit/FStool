#!/usr/bin/perl
#
#  Usage.pl (C) copyright 2010, 2011, 2012 John F. dey all rights reserved.
#
#  Send e-mail to users who have files older than 60 days
#
# 1.0.0  Dec 2011 john dey 
# 
my $Version = "1.1.0 Usage.pl Mar 13 2012";
#
use strict;
use YAML qw'Dump LoadFile';
use Time::Local;
my $CONF = LoadFile( '../etc/FSconfig.yaml' );
use lib "$CONF->{'FSbase'}/sbin";
use FStools;
use Mail::Sendmail;


my $vList = LoadFile( '../etc/FileSystems.yaml' );

my $tag = 'work';  #Volume tag for fsdata DB
my $volume = "/$tag";  # this will break 

my $dfout = `df -P $volume`;
my ($one, $two) = split /\n/, $dfout;
my ($fs, $size , $used, $avail, $percent, $mount) = split /\s+/, $two;


my $dirDate =`date '+%y.%m.%d'`;
my $tableDate = $dirDate; $tableDate =~ s/\.//g;

# Send a mail message
sub sendMailMessage {
    my $to = shift;
    my $from = shift;
    my $subject = shift;
    my $body = shift;

    my %mail = (
         from => $from,
      to => $to,
       subject => $subject,
        message => $body,
    );
    $mail{'content-type'} = 'text/html; charset="iso-8859-1"';
    sendmail(%mail) or print STDERR "Error: $Mail::Sendmail::error\n";
}


#-------------------------
#
#  The Fun Starts Here
#
#-------------------------

if ( $#ARGV == 0 ) {
   $dirDate = $ARGV[0];
} else {
   $dirDate =`date '+%y.%m.%d'`;
   chop $dirDate;
}
$tableDate = $dirDate; 
$tableDate =~ s/\.//g;
my $tableName = "$tableDate\_$tag\_data";
my $reportDate = localtime;

FSdebugSet( 'no', 'status' );
FSconnect( $CONF->{DBusername}, $CONF->{DBpasswd}, $CONF->{DBname}, $CONF->{DBhost} );


my $Title = $CONF->{'Title'};
my $SubTitle = $CONF->{'SubTitle'};
my $summary = "$volume usage report<br>$volume at $percent capacity";
my $from = 'john_dey@merck.com';
my $mailto;
my $subject = "$Title: $volume Usage Report";
my $message  = "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" " .
            "\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-trnsitional.dtd\">";
$message .= "<html><head>\n";
$message .= "  <meta http-equiv=\"Content-Type\" ";
$message .= "content=\"text/html; charset=UTF-8\">\n";
$message .= "  <title>FStool Daily Status Report</title>\n";
$message .= "  <style type=\"text/css\">p{font-family:Arial, Helvetica}\n";
$message .= "    body{font-family:Arial, Helvetica}\n";
$message .= "  table { border-collapse:collapse; }\n";
$message .= "  table, th, td{border:1px solid black; padding:5px; empty-cell: show;}\n";
$message .= "  td.right { text-align: right; }\n";
$message .= "  td.left { text-align: left; }\n";
$message .= "  td.crit { background-color: red; }\n";
$message .= "  td.eight { background-color: yellow; }\n";
$message .= "  h2.cent { text-align: center; }\n";
$message .= "  </style>\n";
$message .= "</head>\n";
$message .= "<body>\n";
$message .= "<h2 class=\"cent\">$Title</h2>\n";
$message .= "<h3>$SubTitle<br>$summary</h3><br>Report Date: $reportDate<br>Version: $Version<br></h3>\n";
$message .= "<table>\n<tr>";
$message .= "<th>User</th><th>ISID</th><th>UID</th><th>File Count</th><th>Size</th></tr>\n";

my $query = "select UID.gcos, UID.uname, $tableName.uid, count(*), sum(size) as sz " .
  "from $tableName, UID " .
  "where UID.uid = $tableName.uid " . 
  "group by uid order by sz DESC";

my $rows = FSquery( $query );
print "number of rows: $rows\n";

for ( my $i =0; $i < $rows; $i++ ) { 
    my $cnt = FScommify($FStools::data[$i][3]);
    my $size = FShuman($FStools::data[$i][4]);
    $message .= "<tr><th>$FStools::data[$i][0]</th>" .
                    "<th>$FStools::data[$i][1]</th>" .
                    "<th>$FStools::data[$i][2]</th>" .
                    "<th>$cnt</th>" .
                    "<th>$size</th></tr>\n";
}

$message .= "</table>\n</body>\n</html>\n";
sendMailMessage( 'john_dey@merck.com', $from, $subject, $message );

for ( my $i =0; $i < 20 ; $i++ ) {
    $query = "select email, gcos, stat from UID where uid = $FStools::data[$i][2]";
    my ( $email, $gcos, $stat ) = FSquerySingle( $query );
    if ( $stat == 1 AND length( $email ) > 0 AND $email ne 'none' ) {
        print "mailing: $email \'$gcos\' \n";
        sendMailMessage( $email, $from, $subject, $message );
    }
}
