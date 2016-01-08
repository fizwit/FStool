#!/usr/bin/perl
#
# FSbatch.pl
#
#
#  Just read CTCB configs for pwalk
#
# process CSV files from pwalk
#  - check what needs to be done - checks for new csv files
#  - load CSV into mysql
#  - Generate reports from mysql data
#
# 2014.08.20  John Dey
# 2014.10.20  John Dey
# 2014.11.11  John Dey
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

sub cmdARG {
      if ( $#ARGV != 0 ) {
      print "usage $0: Site\n";
      exit 1;
   }
   return $ARGV[0];
}

# create list of csv files to process
# based on files
sub getCSVfiles {
  my $site = shift; 
  my $CONF = LoadFile( "../etc/FSconfig.yaml" );
  my $csvDir = $CONF->{'csvDir'};
  $csvDir .= qq|/$site|; 
  my $startf = "$csvDir/coll-end";

  if ( ! -d $csvDir ) {
   print STDERR "missing: $csvDir\n"; 
   exit 1;
  } 
  my %files;
  my @list = glob qq|$csvDir/*.csv|;
  for my $file (@list) {
    if ( -M $file > -M $startf  ) {
       my $name = basename($file);
       $files{"$name"} = 1;
    }
  }
  if (!%files) { # empty hash
      print STDERR "no files to load\n";
      exit 1;
  }
  return %files;
}

sub main {
   #my $Version = "1.0.0 FSbatch.pl Oct 21, 2014 ";
   #my $Version = "1.1.0 FSbatch.pl Nov 11, 2014 ";
    my $Version = "1.2.0 FSbatch.pl Apr  3, 2015 ";  #Fix Detail reports
    my $debug =1;

    my $Path = dirname(File::Spec->rel2abs( __FILE__ ));
    my $CONF = LoadFile( "$Path/../etc/FSconfig.yaml" );
    my $dateStr = localtime(); 
    my $sBin    = $CONF->{'sbin'};
    my $logDir  = $CONF->{'logDir'};
    my $runLog = $CONF->{'logDir'} . '/' . $CONF->{'batchlog'}; 
    my $fsbatch = $CONF->{'batch'};

    my $site = cmdARG;
    my %files = getCSVfiles($site); 

    # 
    #  Create bash script 
    #
    my $script = basename($fsbatch);
    open( my $BATCH, ">$fsbatch" ) or die $!;
    print $BATCH <<"EOT";
#!/bin/bash
#
# File: $script
# generated $dateStr
runLog=$runLog
LogDir=$logDir
source /etc/profile.d/modules.sh
module load perl/5.10.1
echo `date +\"%Y.%m.%dT%H:%M\"` state=start >\$runLog 2>&1
export PERLLIB=\$PERLLIB:/data/fstool/sbin/

# 
EOT

   my $yam = LoadFile( "$Path/../etc/$site.yaml" );
   foreach my $vol ( sort(keys %{$yam}) ) {
      print STDERR "load: $yam->{$vol}{fname}, table=$yam->{$vol}{table}\n" if ($debug);
      print $BATCH "# $vol \n"; 
      print $BATCH "($sBin/update.pl --load $site $yam->{$vol}{fname} $yam->{$vol}{table} " .
                   "> \$LogDir/$vol.log ;\\\n";
      print $BATCH " $sBin/update.pl --index $site $yam->{$vol}{fname} $yam->{$vol}{table} " . 
                   ">> \$LogDir/$vol.log ;\\\n";
      print $BATCH " $sBin/fsreport.pl $site $vol " . 
                   ">> \$LogDir/$vol.log ;\\\n";
      if ( exists $yam->{$vol}{detail} ) { 
         my $list = $yam->{$vol}{detail};
         foreach my $d ( @$list ) {
            print STDERR "  desp: $d->{descp} Path: $yam->{path}$d->{path}\n"; 
            print $BATCH "    $sBin/fsdetail.pl $site $d->{name} " .
                   ">> \$LogDir/$vol.log ;\\\n";
         }
      }
      if ( exists $yam->{$vol}{background} && $yam->{$vol}{background} eq 'yes' ) {
         print $BATCH ") &\n";
      } else {
         print $BATCH ")\n";
      }
   }
   print $BATCH "echo `date +\"%Y.%m.%dT%H:%M\"`, state=finished >>\$runLog 2>&1\n";
   close $BATCH;

# lets run what we made
    chmod 0755, $fsbatch;
    #system( "$fsbatch >$runLog 2>&1" );
} #end main

main;
__END__
