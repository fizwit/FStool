#!/bin/env perl
#

use strict;

my  $dataDir = '/data/fstool/fsdata';
my $Multi = 'false';
my ($site, $vName);
my @filelist;

if ( $#ARGV == 1 | $#ARGV == 2 ) {
   $site  = $ARGV[0];
   $vName = $ARGV[1];
   if ( $#ARGV == 2 ) {
      $Multi = 'true';
   }
} else {
   die "arguments Site Volume [multi flag]";
}

$dataDir .= "/$site";
#
#  If Multi is true load all files except the vName.csv file
#  UNIX split leaves the orignal file and creates many smaller files
#  just load the small files
#  if !Multi just load the .csv file
#
if ( $Multi eq 'true' ) {
    @filelist = <$dataDir/$vName*>;
    for my $i ( 0 .. $#filelist ) {
       if ( $filelist[$i] =~ /\.csv/ ) { splice @filelist, $i, 1; }
    }
} else {
    @filelist = <$dataDir/$vName\.csv>;
}


unless ( -d $dataDir ) {
    print "Directory does not exist: $dataDir\n";
}

foreach my $file ( @filelist ) {
   print "file: $file\n";
}
