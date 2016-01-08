#!/usr/bin/perl
#
# UserDir.pl
#
# 
# 2010.03.22 John Dey Various formating changes; absolute path for png added
# 2010.06.20 If second argument is not provided to not run historic reports
#            Add third argement to allow indetification of each volum name <$vName>
#            Argument List: vName Date Past
# 2010.10.28 add FSconfig.yaml features to turn on and off reports;
# 2013.09.25 morphed from hogs.pl  
#            find largest dirs by User (UID)
#            create one report by for each UID; read UIDs from a file
#            
#        Example:  ./UserDir.pl 13.09.19 project CTCB uidlist
#
#
use strict;
use Time::Local;
use YAML qw'Dump LoadFile';
use FStools; 

my $CONF = LoadFile( '../etc/FSconfig.yaml' );
my $Version = "1.2.0 Aug 21, 2010";
my $WEBbase = $CONF->{'WEBbase'}; 
my $WEBdir  = $CONF->{'WEBdir'};

my ($query, $uid, $uidFile);
my ($dir, $dirDate, $table, $volumeName, $userCurrent, $vName );


# Arguments to FSprintTable
my @reportTitle;
my @colFormat;
my @headerText;

# YY.MM.DD is the format for command line arguments to fsdata utilities
# Recycle this code; Usages: Chart labels, table names and directory names
# dates refer to the time of data collection (walk is run)
# Directory names: YY.MM.DD
# Table names: dataYYMMDD
# Lables: YYYY Jan DD
#  [vName date historic_date]
sub cmdARG {
    unless ( $#ARGV == 3 ) {
        die "Args: YY.MM.DD vName site file_ofUIDs\n";
    }
    $dir = $ARGV[0];
    $dirDate = $dir; $dirDate =~ s/\.//g;
    $vName = $ARGV[1];
    my $site = $ARGV[2];
    $uidFile = $ARGV[3];
    $WEBdir = $WEBdir . '/' . $dir . '/' . "user";
FSdebug( "dirDate: $dirDate" );
    $table = "$dirDate\_$site$vName\_data";
    $userCurrent = "$dirDate\_$site$vName\_user";
    my ($yr, $mn, $dy) = split '\.', $ARGV[0];
    my $currentTD = timelocal(0,0,0, $dy, $mn-1, $yr+2000 );
    my @mon = qw(BLK Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec); 
}


#----------------------------------
#  The Fun Starts Here
#----------------------------------

FSdebugSet( 'yes', 'UserDir' );
cmdARG();
FSconnect( $CONF->{DBusername}, 
           $CONF->{DBpasswd}, 
           $CONF->{DBname}, 
           $CONF->{DBhost} );
my ($vList) = LoadFile( '../etc/FileSystems.yaml' );

foreach my $group ( keys %$vList ) {
   print "Group: $group\n";
   foreach my $vproject ( sort( keys %{$vList->{$group}} ) ) {
      next if ( $vproject =~ /description/ );
      next if ( $vproject =~ /Title/ );
      print "vProject: $vproject\n";
      foreach my $volume( sort( keys %{$vList->{$group}->{$vproject}} ) ) {
         if ( $vName eq $volume ) {
            $volumeName =  $vList->{$group}{$vproject}{$volume}{'path'};
         }
      }
   }
}

unless ( -d $WEBdir ) {
    mkdir $WEBdir;
    chmod 0755, $WEBdir;
}

open ( FILE, "<", $uidFile ) || die "could not open $uidFile\n";
while ( <FILE> ) {
    chop;
    $uid = $_;

$query = "select gcos, uname from UID where uid=\'$uid\'";
my ($gcos, $uname) = FSquerySingle( $query );

FSdebug( "Table: $table Path:  $volumeName User: $uname, $gcos\n" );

#----------------------------------
# Ad-Hoc Report 
#----------------------------------
    $query = "select substring(fname, 1,65) as Name, count(*), sum(size) as 'Sum' " .
             "from $table where uid=$uid " .
             "group by name order by 3 DESC limit 100";

    FSdebug( "Report: User Report for Big Directores" );
    FSquery( $query );

    @reportTitle = (0, "$volumeName Storge report for $gcos", 
                       "Usage grouped by path",
            "$WEBdir/$uname\_$vName\_UserPath.html", $volumeName );
    @headerText = ("File Path", "#Files", "Amt Used GB"  );
    @colFormat = qw(text commaRight humanRight );
    FSprintTable( \@reportTitle, \@headerText, \@colFormat ); 
}
