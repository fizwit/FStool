#!/usr/bin/perl
#
# update2.pl
#
# 2010.01.11  John Dey
# 
# update load date data into MySQL DB
# Run this program when a new collection process starts
#
# Ris latest collectiondirerctory name of CSV data
#
# 2013.10.10 john dey - directory structure of fsdata change;
#            remove all referances to table dates;
#            All data is flat in regards to time; 
#            remove directoryes of reports based on date
#            remove date from name of table;
#  TODO - check if table exists - if yes - remove old table first - No history
#         historic data will have to be handeled in some other way
#         remove _data from table names;  All tables are data
# 2013.10.25 john dey - add feature to load mutible files into the same table
#        load is faster if data is broke into 1GB chunks.
#        
#  If Multi is true load all files except the vName.csv file
#  UNIX split leaves the orignal file and creates many smaller files
#  just load the small files
#  if !Multi just load the .csv file
#

use strict;
use YAML qw'Dump LoadFile';
use Time::Local;
use FStools;

my $CONF = LoadFile( '../etc/FSconfig.yaml' );

my $DEBUG = 'yes';
my $TEST = 'yes';
#  $Version = '2.0.0 update.pl Jul 29, 2011';
#my $Version = '2.1.0 update.pl Oct 25, 2013';
my $Version = '2.2.0 update.pl Oct 21, 2014';  # make the program even simplier

my ( @data, $query, $Total );
my ( $FSbase, $csvDir );
my ( $site, $fname, $dir, $DBtable, $UNIX_time );
my $indexOnly = "false";
my $loadOnly = "false";
my @filelist;

sub cmdARG {
   print "$#$ARGV\n";
   if ( $#ARGV != 3 ) {
      print "usage $0: (--index|--load) Site file table\n";
      exit 1;
   }
   $indexOnly = 'true'  if ( $ARGV[0] eq '--index' );
   $loadOnly = 'true'  if ( $ARGV[0] eq '--load' );
   $site = $ARGV[1];
   $fname = $ARGV[2];
   $DBtable = $ARGV[3];
  
   my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
   $UNIX_time = "$year-$mon-$mday $hour:$min:$sec";
   unless ( -d "$csvDir/$site" ) {
      die "Hey! I can't find directory: $csvDir/$site\n";
  }
}

sub indexDataTable {

   my $query = "alter table $DBtable " .
      "add INDEX (inode), " .
      "add INDEX (depth), " .
      "add INDEX (uid), " .
      "add INDEX (gid), " .
      "add INDEX (fname(48)), " .
      "add INDEX (extension)";

   my $rows = FSqueryDo( $query );
   FSdebug( "table=$DBtable, index=$rows" );
}

sub createDataTable {

   my $query = "CREATE TABLE  $DBtable (" .
      "`inode`  bigint NOT NULL," .
      "`pinode` bigint default NULL," .    # -1 is value of root inode
      "`depth`  INT default NULL," .
      "`uid`  INT unsigned default NULL," .
      "`gid`  INT unsigned default NULL," .
      "`size` bigint(20) default NULL," .
      "`blks` bigint(20) default NULL," .
      "`mode` int default NULL," .
      "`atime` INT unsigned default 0," .
      "`mtime` INT unsigned default 0," .
      "`ctime` INT unsigned default 0," .
      "`fname` varchar(4096), " .
      "`extension` char(25),  " .
      "`cnt` int default NULL," .
      "`dirSz` bigint(12) NULL," .
      "`branchSz` bigint(16) NULL," .
      "UNIQUE KEY (inode) " .
    ") ENGINE=innodb DEFAULT CHARSET=latin1 " ; 
    $query .= "PARTITION BY KEY() PARTITIONS 10" if ( $DBtable eq "CTCB_project" );

   my $rows = FSqueryDo( $query );
   FSdebug( "data table: $DBtable  created; Status: $rows" );
}


# return lenght of time between two UNIX time stamps
# "DD HH:MM:SS"
sub diffDate
{
    my $start = shift;
    my $end = shift;
    my $diff = $end - $start;
   
    my $days = int( $diff / (60 * 60 * 24 ));
    if ( $days > 0 ) { $diff = $diff - ($days * (60 * 60 * 24 )); }
    my $hours = int ( $diff / (60 * 60) );
    if ( $hours > 0 ) { $diff = $diff - ($hours *(60 * 60)); }
    my $minutes = int($diff / 60 );
    if ( $minutes > 0 ) { $diff = $diff - ($minutes * 60); }
    return sprintf("%d %02d:%02d:%02d", $days, $hours, $minutes, $diff );
}

#
#  load data 
sub load_data {
    my $file = $csvDir . '/' . $site . '/' . $fname;

    my $startT = time();
    FSdebug( "csvFile=$file" );
    my $query = "load data LOCAL infile \'$file\'  \n" .
      "into table $DBtable \n" .
      "fields terminated by ',' OPTIONALLY enclosed by '\"' " .
      "lines terminated by '\\n' " .
      "(inode, pinode, depth, fname, extension, uid, gid, size, blks, mode, atime, mtime, ctime, cnt, dirSz)";

    my $rows = FSqueryDo( $query );
    FSdebug( "table=$DBtable, rows=$rows" );
    my $dateStr = diffDate( $startT, time() );
    FSdebug( "Load time $file: $dateStr" );
}

=head3 update_scan
=over 4


update count and size info for scan table

=cut
sub update_scan {

    # update "scan" table with row count and total size for each vName
    $query = "select sum(size), count(*) from $DBtable";
    my ($sum, $cnt) = FSquerySingle( $query );

    $query = "update scan set file_cnt = $cnt, vol_sizeB = $sum, state='complete'  " . 
        "where table_name = \'$DBtable' ";
    my $rows = FSqueryDo( $query );

    # update "scan" with Delta information on number of new files and sizes
    $query = "select count(*), sum(size) from $DBtable " .
    "where ctime > (unix_timestamp(\'$UNIX_time\') - 24*60*60)";
    ($cnt, $sum) = FSquerySingle( $query ); 

    if ( $cnt == 0 ) { $sum = 0; }
    $query = "update scan set deltaCNT = $cnt, deltaSize = $sum, state='complete'  " .
        "where table_name = \'$DBtable\' ";
    $rows = FSqueryDo( $query );
}

$FSbase  = $CONF->{'FSbase'};
$csvDir =  $CONF->{'csvDir'};
cmdARG();
FSconnect( $CONF->{DBusername}, $CONF->{DBpasswd}, $CONF->{DBname}, $CONF->{DBhost} );
FSdebugSet( 'yes', 'update.pl' );
if ( $indexOnly eq "false" ) {
   FSrenameTable( $DBtable, "$DBtable\_old" );
   createDataTable();
   load_data();
}
if ( $loadOnly eq "false" ) {
   indexDataTable();
}
