#!/usr/bin/perl
#
#  notify.pl (C) copyright 2010, 2011, 2012 John F. Dey all rights reserved.
#
#  Send e-mail to biggest users of home dir space 
#
# 1.0.0  Dec 2011 john dey 
#
my $Version = "1.1.0 notify.pl Dec 3 2011";
$Version = "1.2.0 notify_home.pl Dec 7 2015";

# make the report more flexable; choice of volume is a command line argument
# 

use strict;
use YAML qw'Dump LoadFile';
use Time::Local;
my $CONF = LoadFile( '../etc/FSconfig.yaml' );
use lib "$CONF->{'FSbase'}/sbin";
use FStools;
use Mail::Sendmail;

my $vList = LoadFile( '../etc/FileSystems.yaml' );

my $tag = 'tmp60days';  #Volume tag for fsdata DB
my $Days = 60;

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

my $tableName = "CTCB_home";
my $reportDate = localtime;

FSdebugSet( 'no', 'status' );
FSconnect( $CONF->{DBusername}, $CONF->{DBpasswd}, $CONF->{DBname}, $CONF->{DBhost} );


my $Title = $CONF->{'Title'};
my $SubTitle = $CONF->{'SubTitle'};
my $summary = "CTCB Cluster User Home directory storage usage report";
my $from = 'john_dey@merck.com';
my $mailto;
my $subject = "$Title: tmp60days Usage Report";
my $message .= "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" " .
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
$message .= "CTCB /home volume is over 90% full. ";
$message .= "Please try to cleanup storage in your local /home directory that you do need.";
$message .= "<h2 class=\"cent\">$Title</h2>\n";
$message .= "<h3>$SubTitle<br />$summary</h3><br />Report Date: $reportDate<br />Version: $Version<br /></h3>\n";
$message .= "<table>\n<tr>";
$message .= "<th>User</th><th>ISID</th><th>UID</th><th>File Count</th><th>Size</th></tr>\n";

my $query = "SELECT b.gcos, b.uname, a.uid, SUM(size) as Size, count(*) " .
                  "from $table a LEFT OUTER JOIN UID b " .
          "on a.uid = b.uid " .
          "group by a.uid " .
          "order by Size DESC LIMIT 12";

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

#for ( my $i =0; $i < $rows ; $i++ ) {
#    $query = "select email, gcos from UID where uid = $FStools::data[$i][2]";
#    my ( $email, $gcos ) = FSquerySingle( $query );
#    if ( length( $email ) > 0 and $email ne 'none' ) {
#        print "mailing: $email \'$gcos\' \n";
#        sendMailMessage( $email, $from, $subject, $message );
#    }
#}
