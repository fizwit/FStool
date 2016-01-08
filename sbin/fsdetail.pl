#!/usr/bin/perl
#
# fsdatail.pl - mysql reports from pwalk
#  usage: Site ReportName  (ReportName is found in yaml conf for a given Site)
#
#  Given one directory name; Creat a storage report for each
#  sub direcotry 
#  
# 2015.04.06 John Dey - updated to support New Yaml format
# 2014.10.21 John Dey
# 2013.10.11 john dey - Detail reports are run on a single volume,
#       if you need detail reports for a whole site then call from a report generating
#       Arguments - site and volume
#
# 2010.08.23 John Dey - Version one
#
use strict;
use Time::Local;
use File::Basename;
use YAML qw'Dump LoadFile';
use FStools;

my $Version = "2.0.1 dirReport Nov 16 2010";
$Version = "2.1.0 detail Oct 11, 2013";
$Version = "2.1.1 detail Mar 12, 2015"; # add Modify Time column
$Version = "2.1.2 detail Apr  6, 2015"; # YAML changed! update to support new format 

# 
# Arguments: Site Volume 
#
# dir_name becomes a file name of directoes to do reports on <dir_name.dir>
sub cmdARG {
    unless ( $#ARGV == 1 ) {
       die "Usage:  Site Report-Name"; }
    return($ARGV[0], $ARGV[1]);
}

#
# create list of directories to report on
#
sub dirReport {
  my $fname= shift;
  my $table = shift;
  my $query = "select depth from $table where fname = \'$fname\'"; 
  my ($depth) = FSquerySingle($query);
  if ( $depth eq 'no rows') {
     print STDERR "unable to locate $fname in $table\n";
     exit 1;
  }
  $depth++;
  FSdebug("depth=$depth");

  my $today = time();    #Number os seconds since the epoch "Jan 1, 1970"
  my $day = 24 * 60 *60; #Number of seconds in a day
  my $nintyDays = $today - (90 * $day );
  my $sixMonth = $today - (365/2 *  $day );
  my $oneYear = $today - (365 *  $day );

  # Get list of directory names
  $query = "select fname from $table where fname like \'$fname/%\' and depth=$depth and cnt >-1";
  my $rows = FSquery($query);
  FSdebug("Rows=$rows");

  my ($base, $col3, $col4, $col5, $col6);
  for my $i (0 ..$rows-1) {
    my $dir = FSgetData($i, 0);
    $query = "select fname, count(*), sum(size),mtime from $table where fname like \'$dir/%\'";
    my ($dummy, $cnt, $size, $mtime ) = FSquerySingle($query);

    $base = basename($dir);
    FSsetData($i,0,$base);
    FSsetData($i,1,$cnt);
    FSsetData($i,2,$size);
    FSsetData($i,3,$mtime);
    #
    #  Add File Age data to columns 3,4,5,6 of @ldata
    #
#    $query = "select Ninty, SixMon , OneYear, gtOneYear from " .
# "(select sum(size) as Ninty  from $table where fname like \'$dir/%\' AND mtime > $nintyDays) tempa, " .
# "(select sum(size) as SixMon from $table where fname like \'$dir/%\' AND mtime BETWEEN $sixMonth +1 and $nintyDays)  tempb, " .
# "(select sum(size) as OneYear   from $table where fname like \'$dir/%\' AND mtime BETWEEN $oneYear+1  and $sixMonth) tempc, " .
# "(select sum(size) as gtOneYear from $table where fname like \'$dir/%\' AND mtime <= $oneYear) tempd";
#    ($col3, $col4, $col5, $col6) = FSquerySingle( $query );
#    if ( $depth eq 'no rows') {
#       print STDERR "detail=$dir no rows\n";
#    }
#    FSsetData($i,3,$col3);
#    FSsetData($i,4,$col4);
#    FSsetData($i,5,$col5);
#    FSsetData($i,6,$col6);
  }
  FSdebug( "==== Leaving dirReport ====");
}

sub getDetailConf {
  my $site = shift;
  my $name = shift;

  my $yam = LoadFile( "../etc/$site\.yaml" );
  foreach my $vol ( sort(keys %{$yam}) ) {
    if ( exists $yam->{$vol}{detail} ) {
       my $list = $yam->{$vol}{detail};
       foreach my $d ( @$list ) {
          if ( $d->{name} eq $name ) {
             return ($vol, $yam->{$vol}{source}, $yam->{$vol}{path}, 
                     $yam->{$vol}{table}, $d->{descp}, $d->{path});
             print STDERR "    desp: $d->{descp} Path: $yam->{$vol}{path}$d->{path}\n";
          }
       }
    }
}
} 

#----------------------------------
#  The Fun Starts Here
#----------------------------------

sub main {
  FSdebugSet( 'yes', 'fsdetail' );
  my ( $site, $Name) = cmdARG();

  my $CONF = LoadFile( '../etc/FSconfig.yaml' );
  FSconnect( $CONF->{DBusername}, $CONF->{DBpasswd}, $CONF->{DBname}, $CONF->{DBhost} );

  my ($vol, $source, $volPath, $table, $descp, $path) = getDetailConf($site, $Name); 
  my $reportDir = ($path eq "/")? $source : $source . $path; 
  dirReport( "$reportDir", $table );

  my $Title    = $CONF->{'Title'};
  my $SubTitle = $CONF->{'SubTitle'};
  my $WEBdir   = $CONF->{WEBdir};
  my $outFile = "$WEBdir/$site/detail_$vol.html";

  my @reportTitle = ( 0, "Directory: $volPath" . "$path",
                       "",
                       $outFile, 
                       "Storage Report $descp"); 
  my @headerText = ("Folder", "#Files", "Size GB", "Modify Time");
# , "#Files", "<90dys(GB)", "90dy - 6mon(GB)", "6mon - 1yr(GB)", ">1yr(GB)" ); 
  my @colFormat = qw(text commaRight GBRight epoch);  #GBRight GBRight GBRight GBRight );
  FSprintTable( \@reportTitle, \@headerText, \@colFormat );
  chmod 0644, $outFile; 
  FSdebug( "Finished" );
}

main;
__END__
