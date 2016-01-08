#!/usr/bin/perl
#
#  FSstatus.pl
#  based on satus.pl
#
#  Send e-mail to admin staff of fstool processes; collection, loading, reporting
#  Based on the configuration files: FileSystems.yaml 
#
# 1.1.0  Nov 2011 Add html mail with tables
#
use strict;
use YAML qw'Dump LoadFile';
use Time::Local;
my $CONF = LoadFile( '../etc/FSconfig.yaml' );
use lib "$CONF->{'FSbase'}/sbin";
use FStools;
use Mail::Sendmail;


my $Version = "1.1.0 FSstatus.pl Nov 15 2011";
my ( $array, $volume, $detail );
my $vList = LoadFile( '../etc/FileSystems.yaml' );
my %details;
my ( $dirDate, $tableDate, $tableName, $status );
my ( $TotDF, $TotUsed, $TotB, $TotCnt );
my ($Title, $SubTitle );
my $message;
my $out;

sub GB {
  my $num = shift;
  my $power = shift;
  $num = ( $num /(1024 ** $power) );
  $num = ($num * 10) + .5; $num = int($num/10);
  return $num; 
}


sub Scan {
  
  my $tag = shift;
  my $tableName = "$tableDate\_$tag\_data";
  my @path = split '/', $volume;
  my $dir = pop(@path);
  my $query = "show tables like \'$tableName\'";
  $status = FSquerySingle( $query );
  if ( $status eq "0" ) { 
      $out = "  <td class=\"crit\"><b>$dir</b></td>\n  <td></td>\n  <td></td>\n" .
             "  <td></td>\n  <td></td>\n  <td></td>\n  <td></td>\n" .
             "  <td class=\"crit\">No Data</td>\n";
      return; 
  }

  $query = "select state from scan where table_name = \'$tableName\'";
  ( $status ) =  FSquerySingle( $query );
  my ( $dfsize, $dfused, $file_cnt, $statSec, $used, $percent );
  my $query = "select dfsize, dfused, file_cnt, " .
  "(file_cnt/TIME_TO_SEC(TIMEDIFF(walk_end,walk_start))) as 'files/Sec' " .
  "from scan where table_name = \'$tableName\'";
  ($dfsize, $dfused, $file_cnt, $statSec) = FSquerySingle( $query );
  $query = "select sum(size) from $tableName";
  ( $used ) = FSquerySingle( $query );
  if ( $dfsize == 0 ) { 
      $percent = $status; }
  else {
      $percent = int(($dfused/$dfsize) * 1000 +.5)/10;
  }
  $TotDF   = $TotDF + $dfsize;
  $TotUsed = $TotUsed + $dfused;
  $TotB    = $TotB + $used;
  $TotCnt  = $TotCnt + $file_cnt; 
  
  $dfsize = GB($dfsize,2); $dfused = GB($dfused,2); $used = GB($used,3);
  $statSec = int( $statSec );
  my $f_cnt = FScommify($file_cnt);
  my $stat  = FScommify($statSec);
  my $class = ' class="right"';
  if ( $percent > 80 ) { $class = ' class="right eight"'; }
  if ( $percent > 90 ) { $class = ' class="right crit"'; }
  $out = "  <td $class><b>$dir</b></td>\n  <td class=\"right\">$dfsize</td>\n" .
         "  <td class=\"right\">$dfused</td>\n" .
         "  <td $class>$percent</td>\n" .
         "  <td class=\"right\">$used</td>\n" .
         "  <td class=\"right\">$f_cnt</td>\n" .
         "  <td class=\"right\">$stat</td>\n  <td class=\"right\">$status</td>"; 
}

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
$tableName;
my $reportDate = localtime;

FSdebugSet( 'no', 'status' );
FSconnect( $CONF->{DBusername}, $CONF->{DBpasswd}, $CONF->{DBname}, $CONF->{DBhost} );
$Title = $CONF->{'Title'};
$SubTitle = $CONF->{'SubTitle'};
my $summary = "FS Tool Run Status\n";
my $from = 'brian_holt@merck.com';
my $mailto;
my $subject = "FS Tool Status: $Title";

$message  = "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" " .
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
$message .= "<h3>$SubTitle<br>Report Date: $reportDate<br>Version: $Version<br></h3>\n";
$message .= "<table>\n<tr>";
$message .= "<th>Volume</th><th>DFSize</th><th>DFused</th><th>%Used</th><th>File SZ</th><th>#Files</th><th>Files/Sec</th><th>Status</th></tr>\n";

foreach my $group ( keys %$vList ) {
   unless ( exists $vList->{$group}{'description'} ) {
       print "Error: Group->$group does not have field 'description'\n";
   }
   unless ( exists $vList->{$group}{'Title'} ) {
       print "Error: Group->$group does not have field 'Title'\n";
   }
   #printf ("Group: %-20s Title: %s\n", $group, $vList->{$group}{'Title'} );
   #printf ("Description: %s\n", $vList->{$group}{'description'} );
   # $project is a Project Name (or description of Group)
   foreach my $project ( sort( keys %{$vList->{$group}} )  ) {
       unless ( $project =~ /description/ || $project =~ /Title/ ){
           # tag 
           foreach my $tag ( sort( keys %{$vList->{$group}->{$project}} ) ) {
               unless ( $tag =~ /description/ ) { 
                  $volume = $vList->{$group}{$project}{$tag}{'volume'} ;
                  $array =  $vList->{$group}{$project}{$tag}{'array'} ;
                  #FSdebug( "$volume $tag $array" );
                  Scan( $tag );
                  $message .= "<tr>\n$out\n</tr>\n";
               }
           }
       }
   }
}
$message .= "</table>\n<h3>Summary</h3>\n";
my $tmp = GB($TotDF,3);
$message .= "<table>\n";
$message .= "  <tr><td>Total Size</td><td class=\"right\">$tmp TB</td></tr>\n";
$tmp = GB($TotUsed,3);
$message .= "  <tr><td>Total Used</td> <td class=\"right\">$tmp TB</td></tr>\n";
$tmp = GB($TotB,4);
$message .= "  <tr><td>Total File Space Used</td> <td class=\"right\">$tmp TB</td></tr>\n";
$tmp = FScommify( $TotCnt );
$message .= "  <tr><td>Total Number of files</td> <td class=\"right\">$tmp</td></tr>\n";
$message .= "</table>\n</body>\n</html>\n";
sendMailMessage( 'christina.ferguson@merck.com', $from, $subject, $message );
