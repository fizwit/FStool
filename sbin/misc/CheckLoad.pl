#!/usr/bin/perl
#
#  CheckLoad.pl
#
#  2014.08.04 john dey
#  
#  check the collection time of data;
#  pwalk touches .fstool file in the top level dir before the collection begins.
#  mtime of the file is start time of the collection
 
use strict;
use YAML qw'Dump LoadFile';
use FStools;
use Time::Local;
use Time::Piece;
use File::Copy;

my $DEBUG = 'yes';
my $Version = '1.0.0 CheckLoad.pl Aug  4, 2014';
my $CONF = LoadFile( '../etc/FSconfig.yaml' );


FSconnect( $CONF->{DBusername}, $CONF->{DBpasswd}, $CONF->{DBname}, $CONF->{DBhost} );
#FSdebugSet( 'yes', "LoadDate" );

my $rows = FSquery( "show tables like 'CTC_%'" );

for ( my $i =0; $i < $rows; $i++ ) {
    my $table = $FStools::data[$i][0]; 
    my $query = "select mtime from $table where fname like '%/.fstool'";
    my ($mtime) = FSquerySingle($query);
    if ( $mtime eq 'no rows') {
      print "No Date: $table \n"; 
    } else { 
      my $collDate = localtime($mtime)->strftime('%F %T'); # adjust format to taste
      print "$collDate ($mtime)  $table \n"; 
    }
} 
