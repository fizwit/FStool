#!/usr/bin/perl
#
# history.pl 
#
# 2010.05.05  John Dey
# 
#  keep historic data from fsdata DB
#
#  fsdata tables are generated and droped on a 9 day rotation.
#  Keep historic data in two differnt tables;
#
#  volumehist contains history data for each volume being monitored
#  userhist contains history data by user
#
#  This program is designed to be run once per day with 'date' as the
#  command argument.
#  We also have all the subroutines that were used to create the tables
#  and do the inital population
use strict;
use DBI;
use DBD::mysql;


my $dbh;

my $DEBUG = 'yes';
my $TEST = 'yes';

my (@data, $query, $Total );
my $userTable ='data';
my ($tag, $dir, $tableDate, $dataTable, $userTable, $userCurrent, $userLast );

sub cmdARG {
   unless ( $#ARGV eq 1 ) {
       die "expected two arguments: tag YY.MM.DD\n";
   }
   my ($yr, $mn, $dy) = split '\.', $ARGV[0];
   my @mon = qw(BLK Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
   my $dateStr = $mon[$mn] . " " . $dy . ", 20" . $yr;
   $tag = $ARGV[0];
   $dir = $ARGV[1];
   $tableDate = $dir; $tableDate =~ s/\.//g;
   $dataTable = "$tableDate\_$tag\_data";
   $userTable = "$tableDate\_$tag\_user";
}


#  Global: $dbh
#  Connect to Database and return database DBI handle
#
sub DB_Connect {
    my $username="deyjohn";
    my $passwd="mypasswd";
    my $database = "fsdata";
    my $hostname = "lctcvh6002";

    my $dsn = "DBI:mysql:database=$database;host=$hostname";

    $dbh = DBI->connect($dsn, $username, $passwd)
      or die "Cant connect to the database Doh!\n";
}

#
#  These tables are perminate and this routine only needs to be run once
#  it listed in the source to document how it was built
#
sub CreatHist {
    $query = "CREATE TABLE `userhist` (" .
      "`array` char(30) default NULL, " .
      "`volume` char(40) default NULL, " .
      "`date` DATE, " .
      "`uid` bigint(10) default NULL, " .
      "`cnt` bigint(20) default NULL," .
      "`size` bigint(20) default NULL )";
    my $rows= $dbh->do( $query ) or die "Can't create userhist table\n";
    print "history: User History Table Created: $rows\n";

    $query = "CREATE TABLE `volumehist` (" .
      "`array` char(30) default NULL, " .
      "`volume` char(40) default NULL, " .
      "`date` DATE, " .
      "`cnt` bigint(20) default NULL," .
      "`size` bigint(20) default NULL )";
    my $rows= $dbh->do( $query ) or die "Can't create volhist table\n";
    print "User Table Created: $rows\n";
}

#
# lets query all the existing data tables; mine the data
# then use to populate the volumehist table
#
sub PopulateVol {
    my $table = shift;
    my ($Tcount, $Tsize);

    $query = "show tables like \'$table\'";
    my $sth = $dbh->prepare( $query ) or die "bad: $query: " . $dbh->errstr;
    $sth->execute() or die "Couldn't execute statement: " . $sth->errstr;
    my $tablename;
while (  $tablename = $sth->fetchrow_array() ) {
    my $year = substr $tablename, 4, 2;
    $year = "20" . $year;
    my $month = substr $tablename, 6, 2;
    my $day = substr $tablename, 8, 2;
    my $subquery="select count(*), sum(size) from $tablename";
    my $statesearch = $dbh->prepare( $subquery )
        or die "Couldn't prepare statement: " . $dbh->errstr;
    $statesearch->execute() or die $statesearch->errstr . "$subquery\n";
    if ( $statesearch->rows() != 1  ) {
       die "subquery failed: $$subquery\n";
    }
    ($Tcount, $Tsize) = $statesearch->fetchrow_array();
    $subquery = "insert into volumehist set array='CTC Isilon', " .
      "volume='/walk', " .
      "date=\'$year-$month-$day\', " .
      "cnt=$Tcount, size=$Tsize";
    print "$subquery\n";
    my $rows = $dbh->do( $subquery ) or die "insert: $subquery\n";
}
}

sub PopulateUser {
    my $table = shift;
    my ($Tcount, $Tsize);
    my ($uid, $cnt, $size, $insert);
    my %Top15;

    $query = "show tables like \'$table\'";
    my $sth = $dbh->prepare( $query ) or die "bad: $query: " . $dbh->errstr;
    $sth->execute() or die "Couldn't execute statement: " . $sth->errstr;
    my $tablename;
while (  $tablename = $sth->fetchrow_array() ) {
    next if ( $tablename =~ /userhist/ );
    my $year = substr $tablename, 4, 2;
    $year = "20" . $year;
    my $month = substr $tablename, 6, 2;
    my $day = substr $tablename, 8, 2;

    my $subquery="select uid, cnt, size from $tablename order by size DESC";
    my $statesearch = $dbh->prepare( $subquery )
        or die "Couldn't prepare statement: " . $dbh->errstr;
    $statesearch->execute() or die $statesearch->errstr . "$subquery\n";
    my $Top =0;
    while ( ($uid, $cnt, $size) = $statesearch->fetchrow_array() ) {
        if ( $Top < 15 ) {
            $Top = $Top + 1;
            $Top15{$uid} = $Top; 
        } else {
            $Tsize = $Tsize + $size;
            $Tcount = $Tcount + $cnt;
            next;
        }
        $insert = "insert into userhist set array='CTC Isilon', " .
          "volume='/walk', " .
          "date=\'$year-$month-$day\', " .
          "uid=$uid, cnt=$cnt, size=$size";
        print "$insert\n";
        my $rows = $dbh->do( $insert ) or die "insert: $subquery\n";
    }

    my $subquery="select uid, cnt, size from $tablename order by cnt DESC";
    my $statesearch = $dbh->prepare( $subquery )
        or die "Couldn't prepare statement: " . $dbh->errstr;
    $statesearch->execute() or die $statesearch->errstr . "$subquery\n";
    $Top =0;
    while ( ($uid, $cnt, $size) = $statesearch->fetchrow_array() ) {
        if ( $Top < 15 ) {
            $Top = $Top + 1;
            next if  exists $Top15{$uid};
            $Tsize = $Tsize - $size;
            $Tcount = $Tcount - $cnt;
        } else {
            last;
        }
        $insert = "insert into userhist set array='CTC Isilon', " .
         "volume='/walk', " .
         "date=\'$year-$month-$day\', " .
              "uid=$uid, cnt=$cnt, size=$size";
        print "CNT: $insert\n";
        my $rows = $dbh->do( $insert ) or die "insert: $subquery\n";
    }
    $insert = "insert into userhist set array='CTC Isilon', " .
    "volume='/walk', " .
    "date=\'$year-$month-$day\', " .
    "uid=-1, cnt=$Tcount, size=$Tsize";
    print "Other: $insert\n";
    my $rows = $dbh->do( $insert ) or die "insert: $subquery\n";
    $Tcount =0; $Tsize =0;
    $Top = {};  #clear all entries in the hash
}

}

cmdARG();
DB_Connect();
#CreatHist();    # Run once
#PopulateVol( 'data%' );  # 'data%' will update all data tables 
#PopulateVol( $dataTable );  # 'data%' will update all data tables 
#PopulateUser( 'user%' ); # used once on inital build 
PopulateUser( $userTable ); # 'user%' will update all user tables
