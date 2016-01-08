#!/usr/bin/perl
#
# summaryPage.pl
#
# produce single html page. Page supports multi volumes. volume names are links
# to detailed reports for each volume.
#
# 2009.12.11  John Dey
# 2010.03.22 John Dey Various formating changes; absolute path for png added
# 2010.06.20 If second argument is not provided to not run historic reports
#            Add third argement to allow indetification of each volum name <$vName>>
#            Argument List: vName Date Past
# 2010.06.23  john dey
# 2010.10.11  john dey Work in progress;
#     convert routines to FStools.pm support;
#     Add support for YAML config file
#     Created more complex web page structure;
#     Call dirReport from this script; Call dirReport of each project report.
# 2010.11.03  Add support for detail reports.  This project will generate the top level
#   web page for "lists of detail" reports. There are two types of detail reports;  
#   Create a direct link when there is only one report per Volume (supports RHY with 
#   one report per volume).  Create an Intermideate web page if there are multi detail 
#   reports per volume. (supports CTC where we have 4 reports for Work)
# 2011.01.12  check all chmod for new files; Make sure blobs are not used for chmod
# 2013.10.09  john dey - Complete re-write
# 2014.11.03  john dey - Reformatting of html,  Standardize look to match hpc-dashboard: No functional changes
#             add css to all pages; make top of page cleaner; remove "subtitle"; 
#             put vesion and update info in footer; add footer to css

use strict;
use Time::Local;
use YAML qw'Dump LoadFile';
use File::Basename;
use FStools;

my $CONF = LoadFile( '../etc/FSconfig.yaml' );
my $Version = "2.1.1 summaryPage Nov 24, 2010 ";
   $Version = "2.2.0 summaryPage Nov  3, 2014 ";
   $Version = "2.2.1 summaryPage Apr  6, 2015 "; # New Yaml Format;
my $query;

my ($Title);
#my ( $tableName, $userCurrent, $userLast  );
#my ( $vName, $descp, $fname );

my $reportLength; # Number of days between this report and the last
my $dateStr;      # Date String of data collection date

my @reportTitle;
my @colFormat;
my @headerText;

# YY.MM.DD is the format for command line arguments to all fsdata utilities
# Recycle this code; Usages: Chart labels, table names and directory names
# dates refer to the time of data collection (walk is run)
# Directory names: YY.MM.DD
# Table names: dataYYMMDD
# Lables: YYYY Jan DD
sub cmdARG {
    my $dir = `date '+%y.%m.%d'`;
    chop $dir;
    if ( $#ARGV == 0 ) {
        $dir = $ARGV[0];
    }
    my ($yr, $mn, $dy) = split '\.', $dir;
    my @mon = qw(BLK Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
}

sub Header {
    my $OUT = shift;
    my $PageTitle = shift;
    print $OUT "<html>\n<head>\n<title>$Title</title>\n";
    print $OUT "<link rel=\"stylesheet\" type=\"text/css\" href=\"/fsdata/css/fstool.css\"/>\n";
    print $OUT "<body>\n";
    print $OUT "  <h1 align=\"center\">$Title</h1>\n";
    print $OUT "  <h2 align=\"center\">$PageTitle</h2><hr>\n";
}


=head 3 CloseHTML

  argument: file pointer
  write closing html tags to open file pointer,
  close file pointer 
=cut
sub CloseHTML {
    my $OUT = shift;
    my $todaysDate = localtime;
    print $OUT "<footer>\n<strong>Page Update: </strong>$todaysDate";
    print $OUT "    &nbsp<strong>Version: </strong>$Version</span> \n";
    print $OUT "</footer>\n";
    print $OUT "</body>\n</html>\n";
    close $OUT;
}


#----------------------------------
#  The Fun Starts Here
#----------------------------------

$dateStr = localtime(); 
FSconnect( $CONF->{DBusername}, $CONF->{DBpasswd}, $CONF->{DBname}, $CONF->{DBhost} );
FSdebugSet( 'no', 'summaryPage' );

$Title = $CONF->{'Title'};

# 
#  Create main index.html - links to reports for each Site/directory
#
open( my $MAIN, ">$CONF->{WEBdir}/index.html" ) or die $!;
FSdebug( "open: $CONF->{WEBdir}/index.html" );
Header( $MAIN,  $CONF->{SubTitle} );
print $MAIN "<h2>Sites</h2>\n";
print $MAIN "<table id=\"main\"><thead>\n";
print $MAIN "<tr> <th>Sites</th> <th>Description</th> </tr>\n</thead>\n";

my %sites = %{$CONF->{'Sites'}};
foreach my $site ( keys %sites ) {
   my $siteIndex = "$site/index.html";
   print "creating: $site/index.html";
   print " Loading YAML: $site\.yaml\n";
   my $vList = LoadFile( "../etc/$site\.yaml" );    #  Each Site has its own config file
   print $MAIN "<tr><td><a href=$siteIndex>$site</a></td>\n";
   print $MAIN "<td>$sites{$site}</td> </tr>\n";
   my $fullsubdir = "$CONF->{WEBdir}/$site" ;
   unless ( -d $fullsubdir ) {
      mkdir $fullsubdir;
      chown 0755, $fullsubdir;
   }
}
print $MAIN "</table>\n";
CloseHTML($MAIN);

#
#  For each Site; Build index file;
#      For each Group per Site build a Group.html index file Group.html
#
foreach my $site ( keys %sites ) {
   FSdebug( "  open: <$CONF->{WEBdir}/$site/index.html>" );
   open( my $SITE, ">$CONF->{WEBdir}/$site/index.html" ) or die $!;
   Header( $SITE, "$site: $sites{$site}" );
   printf STDERR ( "%12s: <%s>\n", $site, $sites{$site} );

   print $SITE "<h3>Storage Reports</h3>\n";
   print $SITE "<table id=\"$site\" >\n<thead>\n";
   print $SITE "<tr><th>Path</th><th>Type</th><th>Description</th></tr>\n";

   my $yam = LoadFile( "../etc/$site\.yaml" );
   foreach my $vol ( sort(keys %{$yam}) ) {
      print $SITE "<tr><td>$yam->{$vol}{path}</td><td>Volume</td>\n";
      print $SITE "    <td><a href=$vol.html>$yam->{$vol}{descp}</a></td>\n</tr>";
      if ( exists $yam->{$vol}{detail} ) {
         my $list = $yam->{$vol}{detail};
         foreach my $d ( @$list ) {
         print $SITE "<tr><td>$yam->{$vol}{path}" . "$d->{path}</td><td>Folder</td>\n";
         print $SITE "    <td><a href=detail_$vol.html>$d->{descp}</a></td>\n</tr>";
       }
      }
   }
   print $SITE "</table>\n";
   CloseHTML ( $SITE );
   chmod 0644, "$CONF->{WEBdir}/$site/index.html"; 
} # foreach $site
