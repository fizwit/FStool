#!/bin/env perl
#
# fsreport.pl
#
# 
# fs-graph "File System Graph"
# produce pie graphs of file system data
# Source data is "fsdata" contained in MySql database
# fsdata is a complete dump of inode data
#
# 2009.12.11  John Dey
# 2010.03.22 John Dey Various formating changes; absolute path for png added
# 2010.06.20 If second argument is not provided to not run historic reports
#            Add third argement to allow indetification of each volum name <$vName>
#            Argument List: vName Date Past
# 2010.10.28 add FSconfig.yaml features to turn on and off reports;
# 2013.10.22 john dey - removed dirDate features; tag replaced by vName, 
#                     Added LEFT OUTER JOIN to all reports that use UID;
#            Next generation reports should refreance LDAP and remove referances to UID/GID tables
# 2014.08.07 john dey - Collction data is set based on mtime from "%/.fstool" file data
# 2014.10.22 john dey - Major change: Config data only from YAML;
#            <Rname> Report Name is the Key from YAML. 
# 2014.11.03 john dey - Add style sheet; change query for mtime from 'like' to equal' 3000 times faster
# 2015.03.31 john dey - Add Histogram for file mtime report. Add library for Mysql fetch and FSqueryOnly
#            improved runtime performance of Hist report

use strict;
use Time::Local;
use Time::Piece;
use YAML qw'Dump LoadFile';
use FStools; 

my $CONF = LoadFile( '../etc/FSconfig.yaml' );
#my $Version = "1.3.0 Nov  3, 2014";
#  $Version = "1.4.0 Oct 20, 2014";
#  $Version = "fsreport.pl 1.5.0 Oct 20, 2014";
my $Version = "fsreport.pl 1.5.1 Apr  6, 2015";
my $MakePie = 'Not today';
my $WEBdir  = $CONF->{'WEBdir'};

my ($Site, $Rname, $Rpath);
sub cmdARG {
    unless ( $#ARGV == 1 ) {
        die "Args: site Rname\n";
    }
    $Site = $ARGV[0];
    $Rname = $ARGV[1];
}

sub Header {
    my $conf = FSgetVolconf($Site,$Rname);
    my $todaysDate = localtime;

    my $query = "select fname, mtime from $conf->{table} where fname = '$conf->{source}/.fstool'";
    my ($touchFile, $mtime) = FSquerySingle( $query );
    my $collDate = localtime($mtime)->strftime('%F %T'); # adjust format to taste

    FSdebug( "Main web page: $WEBdir/$Rname\.html" );
    open( HTML, ">$WEBdir/$Rname.html" ) or die "could not open: $WEBdir/$Rname.html";
    print HTML <<"EOT";
<html>
  <head>
    <title>Storage Reports -- rhyhpc</title>
    <link rel="stylesheet" type="text/css" href="/fsdata/css/fstool.css"/>
  </head>
  <body>
    <h1 align="center">$CONF->{Title}</h1>
    <h2 align="center">Path: $conf->{source}</h2><hr>
    <h2>Table of Contents</h2>
    <div>
      <h3 class="box">Reports</h3>
    </div>
    <a href=$Rname\_UID.html>Utilization by User</a><br>
    <a href=$Rname\_GIDsize.html>Utilization by Group</a><br>
    <a href=$Rname\_Extension.html>File Extension Profile</a><br>
    <a href=$Rname\_Hist.html>File Age by Modification Time</a><br>
    <a href=$Rname\_WideDir.html>Huge Directories by File Count</a><br>
    <a href=$Rname\_FatDir.html>Huge Directories by Size</a><br>

    <footer>\n<strong>Report Date: </strong>$todaysDate
      &nbsp<strong>Data Collection Date:</strong> mtime: $collDate
      &nbsp<strong>Version:</strong> $Version
    </footer>
  </body>
</html>
EOT
   close HTML;
   chmod 0644, "$WEBdir/$Rname.html";
}



=head3 UID

  UID report 

=cut
sub UID {
  my $table = shift;
  if ( defined $CONF->{'TableUID'} && $CONF->{'TableUID'} == /yes/i ) {
    my $query = "SELECT b.uname, a.uid, SUM(size) as Size, count(*) " .
		  "from $table a LEFT OUTER JOIN UID b " .
          "on a.uid = b.uid " .
          "group by a.uid " .
          "order by Size DESC";
    FSdebug( "Report: UID Report" );
    FSquery( $query ); 
    FScomputeCost( 2, 10737418240.0 ); #This addes a column to $data
    #column Index 4 is stat (status)  set if >0 Not Set 0=Flag
    my @reportTitle = (0, "Utilization by User", "",
            "$WEBdir/$Rname\_UID.html", $Rpath ); 
    my @headerText = ("User", "UID", "Size GB", "Number of Files", "Cost/Month" );
    my @colFormat = qw(text textRight GBRight commaRight moneyRight);
    FSprintTable( \@reportTitle, \@headerText, \@colFormat ); 
  }
}

=head3 GIDSize

  GID: Group sorted by amount used 

=cut
sub GIDsize {
   my $table = shift;
   my $query = "SELECT b.gidName, a.gid, count(*) as Cnt, SUM(size) as Size, b.stat " .
          "from $table a LEFT OUTER JOIN GID b " .
          "on a.gid = b.gid " .
          "group by a.gid " .
          "order by Size DESC";
   FSquery( $query ); # Column ID 4 is column "stat"
   my @headerText = ("Group", "GID", "Number of Files", "Size GB" );
   my @colFormat = qw(text text commaRight GBRight );
   my @reportTitle = ( 0, "Utilization by Group", "",
           "$WEBdir/$Rname\_GIDsize.html", $Rpath  );
   FSprintTable( \@reportTitle, \@headerText, \@colFormat );
}


=head3 Exten

  File Extension Report 

=cut
sub Exten {
   my $table = shift;
   FSdebug( "File Extennsion" );
   my $query = "select extension, sum(size) as Sum, count(*) as cnt " .
      " from $table " .
      " group by extension ".
      " order by cnt DESC" .
      " LIMIT 1000";
   FSquery( $query ); 
   my @headerText = ("Extension", "Sum GB", "File Count");
   my @colFormat = qw(text GBRight commaRight );
   my @reportTitle = ( 0, "File Extension Profile", "",
           "$WEBdir/$Rname\_Extension.html", $Rpath  );
   FSprintTable( \@reportTitle, \@headerText, \@colFormat );
}

=head3 WideDir
   Directories with the largest number of files 
=cut 
sub WideDir {
  my $table = shift;
  FSdebug( "Wide directories" );
  if ( defined $CONF->{'TableFatCnt'} && 
               $CONF->{'TableFatCnt'} == /yes/i ) {

    my $query = "select a.uid, b.uname, cnt, fname from $table a LEFT OUTER JOIN UID b " .
         "on a.uid = b.uid " .
         "where cnt > 8000 order by cnt DESC";
   FSquery( $query );  # Nothing to Flag!
   my @headerText = ( "UID", "User", "File Count", "Directory Name" );
   my @colFormat = qw(text text commaRight text );
   my @reportTitle = ( 0, "Huge Directories", "Directories with more that 8,000 files", 
            "$WEBdir/$Rname\_WideDir.html", $Rpath );
   FSprintTable( \@reportTitle, \@headerText, \@colFormat );
 }
}


=head3 Hist

 Histogram File age (mtime) 

=cut
sub Hist  {
   my $table = shift;
   if ( defined $CONF->{'TableHist'} && 
               $CONF->{'TableHist'} == /yes/i ) {
      FSdebug( "Hist Report" );
      my $today = time();    #Number os seconds since the epoch "Jan 1, 1970"
      my $day = 24 * 60 *60; #Number of seconds in a day
      my $nintyDays = $today - (90 * $day );
      my $sixMonth = $today - (365/2 *  $day );
      my $oneYear = $today - (365 *  $day );
      my $twoYear = $today - (365 * 2 * $day);
      my ($ninSum,$sixSum,$oneSum,$twoSum,$gt2Sum);
      my ($ninCnt,$sixCnt,$oneCnt,$twoCnt,$gt2Cnt);

      my $query = "select size, mtime from $table"; 
      my $rows = FSqueryOnly( $query );
      FSdebug( "rows=$rows" );
      while ( my $aref = FSfetch() ) {
         for my $row ( @{$aref} ) {
            if ( ${$row}[1] > $nintyDays )   { $ninSum += ${$row}[0]; $ninCnt++ }
            elsif ( ${$row}[1] > $sixMonth ) { $sixSum += ${$row}[0]; $sixCnt++ }
            elsif ( ${$row}[1] > $oneYear )  { $oneSum += ${$row}[0]; $oneCnt++ }
            elsif ( ${$row}[1] > $twoYear )  { $twoSum += ${$row}[0]; $twoCnt++ }
            else { $gt2Sum += ${$row}[0]; $gt2Cnt++; }
          }
      }
      FSdebug( "Hist Data read complete" );
      FSsetData(0,0, "Less than 90days");         FSsetData(0,1,$ninSum); FSsetData(0,2,$ninCnt);
      FSsetData(1,0, "Between 90days and 6mon");  FSsetData(1,1,$sixSum); FSsetData(1,2,$sixCnt);
      FSsetData(2,0, "Between 6mon and 1year");   FSsetData(2,1,$oneSum); FSsetData(2,2,$oneCnt);
      FSsetData(3,0, "Between 1year and 2years"); FSsetData(3,1,$twoSum); FSsetData(3,2,$twoCnt);
      FSsetData(4,0, "Greater than 2years"); FSsetData(4,1,$gt2Sum); FSsetData(4,2,$gt2Cnt);
      FSsetData(5,0, "Total"); 
      FSsetData(5,1,$ninSum+$sixSum+$oneSum+$twoSum+$gt2Sum);
      FSsetData(5,2,$ninCnt+$sixCnt+$oneCnt+$twoCnt+$gt2Cnt);
      $FStools::DBcols = 3;
      $FStools::DBrows = 6;
      my @reportTitle = ( 0, "File Ages", "Size and Count of Files Based on Modify Time", 
            "$WEBdir/$Rname\_Hist.html", $Rpath );
      my @headerText = ( "Date Range", "Size GB", "File Count" );
      my @colFormat =  qw( text GBRight commaRight);
      FSprintTable( \@reportTitle, \@headerText, \@colFormat );
   }
}

=head3 FatDir

  Fat Directories;  Bigest size in Bytes 

=cut
sub FatDir {
  my $table = shift;
  if ( defined $CONF->{'TableFatSz'} && 
              $CONF->{'TableFatSz'} == /yes/i ) {
    FSdebug( "Fat directories" );
    my $query = "select b.uname, a.uid, FROM_UNIXTIME(mtime), dirSz, fname " .
                "from $table a LEFT OUTER JOIN UID b " .
                "on a.uid = b.uid order by dirSz DESC LIMIT 0,25";
    FSquery( $query );
    my @reportTitle = ( 0, "Huge Directories", "Biggest 25 Directories", 
            "$WEBdir/$Rname\_FatDir.html", $Rpath );
    my @headerText = ( "User", "UID", "Date Modified", "Size GB", "Directory Name" );
    my @colFormat =  qw( text text text GBRight text );
    FSprintTable( \@reportTitle, \@headerText, \@colFormat );
  }
}

=head2 main
   
   
=cut
sub main {

  FSdebugSet( 'yes', 'fsreport' );
  cmdARG();
  FSconnect( $CONF->{DBusername}, $CONF->{DBpasswd}, $CONF->{DBname}, $CONF->{DBhost} );

  my $conf = FSgetVolconf($Site, $Rname);
  exit 1 if ( $conf eq 'not-found');

  FSdebug( "Table=$conf->{table}" );

  $Rpath ="$Site:$conf->{path}";
  $WEBdir = $WEBdir . '/' . $Site;
  unless ( -d $WEBdir ) {
    mkdir $WEBdir;
    chmod 0755, $WEBdir;
  }

  Header( );
  
  # Run Reports
  UID($conf->{table});
  GIDsize($conf->{table});
  Exten($conf->{table});
  WideDir($conf->{table});
  Hist($conf->{table});
  FatDir($conf->{table});
}

main;
__END__
