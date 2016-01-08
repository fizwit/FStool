#!/usr/bin/perl
#
#  update_gid.pl 
#
#  2011.11.02  john dey
#
use strict;
use YAML qw'Dump LoadFile';
use Time::Local;
use File::Copy;
use FStools;

my $DEBUG = 'yes';
my $TEST = 'yes';
my $Version = '1.0.0 update_gid.pl Nov 2, 2011';

my $CONF  = LoadFile( '../etc/FSconfig.yaml' );
my $FSbase  = $CONF->{'FSbase'};
my $WEBbase = $CONF->{'WEBbase'}; 
my $csvDir  = $CONF->{'csvDir'};
my $logDir  = $CONF->{'logDir'};
my $walk    = "$FSbase/bin/pwalk";
my $sBin    = "$FSbase/sbin";

#my ($group, $project, $array, $volume, $tag);

#----------------------------------
#  The Fun Starts Here
#----------------------------------

# Create Output directory for the CSV files
unless (  -d $csvDir ) {
    mkdir $csvDir;  
    chmod 0755, $csvDir;
}

FSconnect( $CONF->{DBusername}, $CONF->{DBpasswd}, $CONF->{DBname}, $CONF->{DBhost} );
FSdebugSet( 'yes', 'update_GID' );

# Collect GID info from FStool DB
my %GID_DB;
my $rows = FSquery( "select gid, gidName from GID" );
for ( my $i=0; $i < $rows; $i++ ) {
   $GID_DB{$FStools::data[$i][0]} = $FStools::data[$i][1];
}

open (GID, "group" ) or die "can't open group fle";
while ( <GID> ) {
    my($group, $pass, $gid, $members ) = split ':';
    next if ( $gid <1000 || $gid > 5000 );
    next if ( exists  $GID_DB{ $gid } );
    FSqueryDo( "insert into GID set gid=$gid, gidname='$group'" ); 
    print "insert into GID set gid=$gid, gidname='$group'\n" ; 
    $GID_DB{$gid} = $group;
}

my $t = FSquery( "select table_name from scan where state='complete' and walk_end > CURDATE()" );
my @tables;
for ( my $i=0; $i < $t; $i++ ) {
    $tables[$i] = $FStools::data[$i][0];
    print "Table: $tables[$i]\n";
}

for ( my $i=0; $i < $t; $i++ ) {
    $rows = FSquery( "select gid, count(*) as cnt from $tables[$i] group by gid order by cnt DESC");
    for ( my $j=0; $j < $rows; $j++ ) {
        next if exists $GID_DB{$FStools::data[$j][0] };
        print "Table: $tables[$i] has GID: $FStools::data[$j][0] with count: $FStools::data[$j][1]\n";
    }
}
