#!/usr/bin/perl
#
#  status2.pl
#
#  verify that the fstool has run and collected data
#
#  Based on the configuration files: FileSystems.yaml 
#
use strict;
use YAML qw'Dump LoadFile';
use Time::Local;
my $CONF = LoadFile( '../etc/FSconfig.yaml' );
use lib "$CONF->{'FSbase'}/sbin";
use FStools;

my $Version = "1.0.1 status2 Nov 19 2010";
my ( $array, $volume, $detail );
my $vList = LoadFile( '../etc/FileSystems.yaml' );
my %details;
my ( $dirDate, $tableDate, $tableName, $status );
my ( $TotDF, $TotUsed, $TotB, $TotCnt );
my @mon = qw(BLK Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

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
      printf( "%-18s %61s\n", $dir, "No Data" ); 
      return; }

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
  printf( "%-18.18s %6s %6s %5s %7s %15s %9s %s\n", $dir, $dfsize, $dfused, $percent,
        $used, FScommify($file_cnt), FScommify($statSec), $status ); 
  
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
printf ( "Report Date: %s %2d, 20%02d\n",
  $mon[substr( $dirDate,3,2)],   #Month
   int(substr( $dirDate,6,2)),   #Day
   int(substr( $dirDate,0,2)) ); #Year
$tableDate = $dirDate; $tableDate =~ s/\.//g;
$tableName;

FSdebugSet( 'no', 'status' );
FSconnect( $CONF->{DBusername}, $CONF->{DBpasswd}, $CONF->{DBname}, $CONF->{DBhost} );
printf( "%-18s %6s %6s %5s %7s %15s %9s %s\n",
   "Volume", "DFSize", "DFused", "%Used", "File SZ", "#Files", "Files/Sec", "Status" ); 
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
               }
           }
       }
   }
}
print "\n";
print "           Total Size: ", GB($TotDF,3), "T\n";
print "           Total Used: ", GB($TotUsed,3), "T\n";
print "Total File Space Used: ", GB($TotB,4), "T\n";
print "Total Number of files: ", FScommify( $TotCnt ), "\n";
