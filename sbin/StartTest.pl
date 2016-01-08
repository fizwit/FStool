#!/usr/bin/perl
#
#  StartWalk.pl
#  dirived from StartWalk.sh
#
#  This scirpt starts a copy of walk for each direcotry listed in the 
#  configuration file "walk.conf"
#
#  Collect "stat" info from a file system
#  2009.04.12  john dey
#  2009.05.15  Add support for configuration file "walk.conf"
#  2009.05.18  start a walk wrapper scipt to run walkv3. Having a secondary
#              script run walk will allow post processing on a per thread basis
#  2010.01.09  remove echo statments; Make the script quite so it can run from cron
#              remove the "disown" not required if start by cron as root
#  2010.01.27  source dir and output dir have been separated. changes made for pwalk
#              Source is kept on NetApp (snapshots and bckups)
#              Output data written to Isilon (no backup)
#  2010.02.05  "run script" has been replaced by this scirpt. This is the only
#               script that starts walk. "RunWalk.sh" has been deleted and replaced
#               by this script. 
#               New Feature: pid file is created for each envocation of walk.
#  2010.06.08  john dey; Update to support walking of many volumes
#  2010.06.09  john dey; convert to Perl there is way too much going on to manage with shell
#  2010.10.12  john dey; Add support for YAML configuration file format.
#
use strict;
use YAML qw'Dump LoadFile';
use Time::Local;
use File::Copy;
use FStools;

my $DEBUG = 'yes';
my $TEST = 'yes';
my $Version = '2.0.2 StartWalk.pl Jan  1, 2011';

my $CONF = LoadFile( '../etc/FSconfig.yaml' );
my $FSbase  = $CONF->{'FSbase'};
my $WEBbase = $CONF->{'WEBbase'}; 
my $csvDir = "$FSbase/CSV-DB";
my $logDir = "$FSbase/logs";
my $conf =   "$FSbase/etc/FileSystems.yaml";
my $walk =   "$FSbase/bin/pwalk";
my $sBin =   "$FSbase/sbin";

my ($group, $project, $array, $volume, $tag);
my $outDir;
my $dirDate;
if ( $#ARGV == 0 ) {
   $dirDate = $ARGV[0];
} elsif ( $#ARGV == -1 ) {
   $dirDate =`date '+%y.%m.%d'`;
   chop $dirDate;
} else {
   print STDERR "StartWalk.pl [YY.MM.DD]\n";
}

my $tableDate = $dirDate; $tableDate =~ s/\.//g;
my $tableName;
my %details;
my $detail;
my $directory;

sub startWalk {
    $tag = shift;

    my $fout=$outDir . "/" . $tag . ".csv";
    my $ferr=$outDir . "/" . $tag . ".err";
    unless ( -d $volume ) { 
        print STDERR "Error: volume does not exist: $volume\n"; 
        return;
    }
    my $status = FSscanStatus( $tableName );
    unless ( $status eq 'complete' || $status eq 'scanned' ) {
#        FSscanStart( $array, $volume, $tag, $tableName );
        FSdebug( "->stating: pwalk $volume $array $tag.csv $tableName" );
#        system( "$walk $volume >$fout 2>$ferr" );
        FSdebug( "-->ending: pwalk $walk $volume" );
#        FSscanEnd( $array, $volume, $tag, $tableName );
    }
    FSdebug( "StartReports.pl $dirDate $array $volume $tag" );
#    system( "$sBin/StartReports.pl $dirDate $array $volume $tag >$logDir/report_$tag.log 2>&1" );
}

#----------------------------------
#  The Fun Starts Here
#----------------------------------

# Create Output directory for the CSV files
$outDir = $csvDir . "/" . $dirDate;
unless (  -d $outDir ) {
    mkdir $outDir;  
    chmod 0755, $outDir;
}

FSconnect( $CONF->{DBusername}, $CONF->{DBpasswd}, $CONF->{DBname}, $CONF->{DBhost} );
FSdebugSet( 'yes', 'StartWalk' );
my $vList = LoadFile( $conf );
foreach my $group ( keys %$vList ) {
   foreach my $project ( keys %{$vList->{$group}} ) {
      unless ( $project =~ /description/ || $project =~ /Title/ ){
         foreach $tag ( keys  %{$vList->{$group}->{$project}} ) {
            next if ( $tag =~ /description/ );
            $volume = $vList->{$group}{$project}{$tag}{'volume'} ;
            $array =  $vList->{$group}{$project}{$tag}{'array'} ;
            $tableName = "$tableDate\_$tag\_data";
            FSdebug( "call walk: $tag" );
            startWalk( $tag );
            if ( exists $vList->{$group}{$project}{$tag}{'detail'} ) { 
               if ( ref($vList->{$group}{$project}{$tag}{'detail'}) eq "HASH" ){
                   my $hash_ref = $vList->{$group}{$project}{$tag}{'detail'};
                   %details = %$hash_ref;
                   foreach $directory ( keys %details ) {
                      $detail = $details{$directory};
                      FSdebug( "detail: detail.pl $dirDate $directory $tag $detail" );
#                      system( "$sBin/detail.pl $dirDate $directory $tag $detail " . 
#                             "> $logDir/dir_$tag\_$detail.log 2>&1" ); 
                   }
               } else {
                  $directory = $vList->{$group}{$project}{$tag}{'detail'};
                  FSdebug( "noDetail: detail.pl $dirDate $directory $tag" );
#                  system( "$sBin/detail.pl $dirDate $directory $tag " . 
#                         "> $logDir/dir_$tag.log 2>&1" );
               }
            }
            FSscanSet( "complete", $tableName );
         }
      }
   }
}
FSdebug( "complete: Main Loop!" );

my $WEBpage = "$WEBbase/index.html";
#system( "$sBin/summaryPage.pl 2>$logDir/summary.log" );
chmod 0644, $WEBpage;
FSdebug( "Finished!" );
