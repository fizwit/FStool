#!/bin/env perl
#
#   fastdu.pl
#
#   scan input from GPFS fastdu.bash and create file system user reports
#
# 2014.08.11 john dey
#
# input data format:
#  156855 130702267 0  17600  18006000 2014-05-16 12:26:45.000000 1528 1001 -- /gridnas/user_shares/kwhome2/porth2/backup/factor11a/factor11a_2014051501_L-005448262-000H001/images/20140515a_0153.osc
#
# [0] = inode
# [1] = GenNumber (gpfs thing)
# [2] = SanpID
# [3] = blocks (stat: 35200 gpfs 17600) 1K size ?
# [4] = Size in Bytes4
# [5] = mtime
# [6] = UID
# [7] = GID
# [8] = '--'
# [9] = full path 

use strict;
use Time::Local;
use Time::Piece;
use YAML qw'Dump LoadFile';
use FStools;

my $CONF = LoadFile( '../etc/FSconfig.yaml' );
my $WhoAmI = "fastdu.pl";
#my $Version = "1.0.0 Aug 11, 2014";
my $Version = "1.1.0 Nov 03, 2014";  # css, cleanup headers; add footer;
my $MakePie = 'Not today';
my $collDate;      # Date String of data collection date

my ($site, $vname);  # Comand line Vars
my ($FSbase, $csvDir, $Title, $SubTitle, $WEBbase, $WEBdir); #Config Vars
my $conf;

#Data Vars
my %UID;
my %GECOS;
my %GID;
my %Path;
my $baseIndex =0;

# Arguments to FSprintTable
my @reportTitle;
my @colFormat;
my @headerText;


sub cmdARG {
    unless ( $#ARGV == 1 ) {
        die "Args: site volume\n";
    }
    $site    = $ARGV[0];
    $vname   = $ARGV[1];
}

sub Header {
    print HTML <<"EOT";
<html>
  <head>
    <title>Storage Reports -- fastdu</title>
    <link rel="stylesheet" type="text/css" href="/fsdata/css/fstool.css" />
  </head>
  <body>
    <h1 align="center">$CONF->{'Title'}</h1>
    <h3 align="center">Path: $conf->{path}</h3>
  <hr>
  <div>
    <h3 class="box">Reports</h3>
  </div>
  <a href=$vname\_PathList.html>Directory Report</a><br>
  <a href=$vname\_UIDList.html>Usage by User</a><br>
EOT
}

sub CloseHTML {
    my $todaysDate = localtime;
    print HTML <<"End";
  <footer>
    <strong>Report Date: </strong>$todaysDate
    <strong>&nbsp Data Collection Date:</strong> mtime: $collDate
    <strong>&nbsp Version:</strong> $Version of $WhoAmI
  </footer>
</body>
</html>
End
    close HTML;
    chmod 0644, "$WEBdir/$vname.html";
}

#----------------------------------
#  The Fun Starts Here
#----------------------------------

cmdARG();
FSdebugSet( 'ye', 'fastdu' );  # 'yes' for Debug
$WEBdir  = $CONF->{'WEBdir'};
$WEBdir  = $WEBdir . '/' . $site;
$FSbase  = $CONF->{'FSbase'};
$csvDir  = $CONF->{'csvDir'};

my $c = LoadFile("../etc/$site.yaml" );
$conf = $c->{$vname};

my $baseIndex = length($conf->{source})+1;
my ($target, $targetLen);
my $detailIndex;
if ( exists $conf->{detail} ) {
    $detailIndex = length($conf->{detail});  # Detail Report TRUE if not zero
    $target = substr $conf->{detail}, $baseIndex;
    $targetLen = length($target); 
    $detailIndex++;
    print "target=$target, targetlen=$targetLen, detailIndex=$detailIndex, " .
          "detail=$conf->{detail}\n"; 
} 

# Note: GPFS list policy creates all output files in the format of list.'listName'
my $inFile = $csvDir . '/' . $site . '/list.' . $conf->{fname};
FSdebug("inFile: $inFile");
open( DATA, "<", "$inFile") or die "can't open $inFile";
print STDERR "Read Data Files: $inFile\n";

my $cnt =0;
my $sumSize=0;
$| = 1;
while(<DATA>) {
  my ($path, $subpath);
  my (@fields) = split(/\s+/, $_);
  my $rindex = index $fields[9], '/', $baseIndex;
  if ( $rindex == -1) {
      $path = substr $fields[9], $baseIndex;  #directory
  } else {
      $path = substr $fields[9], $baseIndex, ($rindex-$baseIndex);
  }
  if ( $path eq ".fstool" ) {
     $collDate = localtime($fields[5]); 
     print "found .fstool=$collDate\n";
     next;  # lets not report this file
  }
  if ( $detailIndex != 0 ) {  # Detail Style report
     $subpath = substr $fields[9], $baseIndex, $targetLen;
     if ( $subpath ne $target ) {  
         next;   # does not match Detail diretory; skip
     }
     my $rindex = index $fields[9], '/', $detailIndex;
     if ( $rindex == -1) { $path = substr $fields[9], $detailIndex;  } #directory
     else { $path = substr $fields[9], $detailIndex, ($rindex-$detailIndex); }
  }
  if ($cnt == 0 ) {
     print "dir=$path, filename=$fields[9]\n";
  
  }
  $Path{$path}{'size'} += $fields[4];
  $Path{$path}{'cnt'} += 1;

  $UID{$fields[7]}{'size'} += $fields[4];
  $UID{$fields[7]}{'cnt'} += 1;

  $sumSize += $fields[4];  #this will be very big number
  $cnt++;

  #if ( ($cnt % 50000) == 0 ) { print "."; }
  #if ( $cnt > 100000 ) { last; }
}

FSdebug("HTML: $WEBdir/$vname.html");
open( HTML, ">$WEBdir/$vname.html" ) or die "could not open: $WEBdir/$vname.html";
Header();

my $i =0;
#printf("%-12s %7s %10s\n", "Path", 'size GB', "File cnt" );
foreach my $path (sort keys(%Path)) {
   $FStools::data[$i][0] = $path;
   $FStools::data[$i][1] = $Path{$path}{'cnt'};
   $FStools::data[$i][2] =  $Path{$path}{'size'};  #bytes
   #printf("%-12s %5.2g %10d\n", $path, $Path{$path}{'size'}/1073741824.0, $Path{$path}{'cnt'} );
   $i++
}
$FStools::DBrows = $i;
$FStools::DBcols = 3;
my $summary = "<pre>Directory Count: $i\n"; 
$i = FScommify($cnt);
$summary .= "Total File Count: $i\n";
$sumSize = int($sumSize/1073741824);
$i = FScommify($sumSize);
$summary .= "Sum File Size: $i GB\n</pre>\n";

@reportTitle = (0, "File System Utilization", $summary,
            "$WEBdir/$vname\_PathList.html", qq|$site:$conf->{path}| );
@headerText = ("Path", "Number of Files", "GB Used"  );
@colFormat = qw(text commaRight GBRight);
FSprintTable( \@reportTitle, \@headerText, \@colFormat );

#=========================
#  User Report
#=========================
foreach my $uid (sort keys(%UID)) {
   my ($gecos, $uname, $luid) = FSuid( $uid );
   $GECOS{$uname}{'uid'} =  $luid; 
   $GECOS{$uname}{'gecos'} = $gecos;
}
      
my $users=0;
foreach my $isid (sort keys(%GECOS)) {
   $FStools::data[$users][0] = $GECOS{$isid}{'gecos'};
   $FStools::data[$users][1] = $isid;
   my $uid = $GECOS{$isid}{'uid'};
   $FStools::data[$users][2] = $uid;
   $FStools::data[$users][3] = $UID{$uid}{'cnt'};
   $FStools::data[$users][4] = $UID{$uid}{'size'};  #bytes
   $users++;
   #printf("%-12s %15d %10d\n", $uid, $UID{$uid}{'size'}/1073741824, $UID{$uid}{'cnt'} ); # G = 2^30
}
$FStools::DBrows = $users;
$FStools::DBcols = 5;
$i = FScommify($users);
$summary = "<pre>\nNumber of Users: $i\n"; 
$i = FScommify($cnt);
$summary .= "Total File Count: $i\n";
$sumSize = int($sumSize/1073741824);
$i = FScommify($sumSize);
$summary .= "Sum File Size: $i GB\n</pre>\n";

@reportTitle = (0, "File System Utilization", $summary, 
            "$WEBdir/$vname\_UIDList.html", qq|$site:$conf->{path}| );
@headerText = ("User", "ISID", "UID", "Number of Files", "GB Used");
@colFormat = qw(text text textRight commaRight GBRight );
FSprintTable( \@reportTitle, \@headerText, \@colFormat );

CloseHTML();
