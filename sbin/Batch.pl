#!/usr/bin/perl
#
# Batch.pl
#
# read all YAML configuration files. Create bash script to run all nessisary reports 
# 2014.08.20  John Dey
#

use strict;
use Time::Local;
use YAML qw'Dump LoadFile';
use File::Basename;
use File::Spec;
use FStools;

#----------------------------------
#  The Fun Starts Here
#----------------------------------

sub main {
    my $Version = "1.0.0 Batch.pl Aug 20, 2014 ";
    my ( $tableName, $userCurrent, $userLast  );
    my ( $vName, $descp, $fname );
    my @reportTitle;
    my @colFormat;
    my @headerText;

    my $Path = dirname(File::Spec->rel2abs( __FILE__ ));
    my $CONF = LoadFile( "$Path/../etc/FSconfig.yaml" );
    my $dateStr = localtime(); 
    my $csvDir = $CONF->{'csvDir'};
    my $sBin    = $CONF->{'sbin'};
    my $runLog = "$CONF->{'sbin'}/Batch.log";
    my $logDir  = $CONF->{'logDir'};

    # 
    #  Create main index.html - links to reports for each Site/directory
    #
    open( my $BATCH, ">$CONF->{sbin}/fastdu.bash" ) or die $!;
    print $BATCH <<"EOT";
#!/bin/bash
#
# fastdu.bash
# generated $dateStr
runLog=$runLog
source /etc/profile.d/modules.sh
module load perl/5.10.1
echo `date +\"%Y.%m.%dT%H:%M\"` state=start >\$runLog 2>&1
export PERLLIB=\$PERLLIB:/data/fstool/sbin/

# 
EOT

#
#  For each Site; 
#
my %sites = %{$CONF->{'Sites'}};
foreach my $site ( keys %sites ) {
   my $vList = LoadFile( "$Path/../etc/$site\.yaml" );    #  Each Site has its own config file
   # L1 - $group - Level 1
   printf ( "%12s: <%s>\n", $site, $sites{$site} );
   print $BATCH "# SiteCode=$site Site=$sites{$site}\n";
   foreach my $group ( keys %$vList ) {
      print $BATCH "#   group=$group\n";
      print $BATCH "echo `date +\"%Y.%m.%dT%H:%M\"`, site=$site >>\$runLog 2>&1\n";

      # Build Group Index for each Project Level 2 ( L2 ) 
      foreach my $project ( sort( keys %{$vList->{$group}} ) ) {
         next if ( $project =~ /descp/ );
         next if ( $project =~ /Title/ );
         # Volume (L3)
         foreach $vName ( sort( keys %{$vList->{$group}->{$project}} ) ) {
            if ( $vName =~ /descp/ ) { next; } # skip description at same level as vName
            #my ($fname, $group, $descp,$path, $source, $detail, $array, $volOwner) = FSgetVolconf($site,$vName);
            my $report = $vList->{$group}{$project}{$vName}{'report'};
            my $path  = $vList->{$group}{$project}{$vName}{'path'};
            my $fname = $vList->{$group}{$project}{$vName}{'fname'};
            my $descp = $vList->{$group}{$project}{$vName}{'descp'};
            my $array = $vList->{$group}{$project}{$vName}{'array'};
            my $source = $vList->{$group}{$project}{$vName}{'source'};
            my $volOwner = $vList->{$group}{$project}{$vName}{'group'};
            my $tableName = $vList->{$group}{$project}{$vName}{'tableName'};
            if ( $vName ne $fname) {
               print "vName and fname differ($vName,$fname)\n";
            }
#
# OK - we have enough data to build HTML table 
#
            my $dataFile = "";
            if ( $report eq "fastdu" ) { 
                $dataFile = "$csvDir/$site/list.$fname"; 
                unless ( -e $dataFile ) { 
                    print STDERR "site=$site, report=$vName, ";
                    print STDERR "datafile=$dataFile, Error=\'no data file\'\n"
                } else {
                    print $BATCH "$Path/fastdu.pl $site $vName >>\$runLog 2>&1\n";
                }
            } 
         }
      }
    }
} # foreach $site
    print $BATCH "echo `date +\"%Y.%m.%dT%H:%M\"`, state=finished >>\$runLog 2>&1\n";
    close $BATCH;

    # lets run what we made
    chmod 0755, "$sBin/fastdu.bash";
    #system( "$sBin/fastdu.bash >$logDir/fastdu.log 2>&1" );
} #end main

main;
__END__
