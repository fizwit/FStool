#!/usr/bin/perl
#
#  uid-update.pl 
#
#  FStool
#  update the UID table 
#  usage: uid-update.pl passwd-file
#
#  Add all UID's found in the FScollect; 
#  Compair missing UID's to /etc/passwd; Populate ISID and GCOS if
#  available
#
use strict; 

use DBI;
use DBD::mysql;
use YAML qw'Dump LoadFile';
use FStools;

my $CONF = LoadFile( '../etc/FSconfig.yaml' );

my ( $uname,$pass,$uid,$gid,$gcos,$home,$shell );
my $query;
my %UID;
my %GCOS;
my %ISID;

sub cmdARG {
    unless ( $#ARGV == 0 ) {  # one arg is requird
       die "Args: passwd-file\n"; 
    }
}

cmdARG();
FSdebugSet( 'yes', 'update_UID' );
FSconnect( $CONF->{DBusername},
           $CONF->{DBpasswd},
           $CONF->{DBname},
           $CONF->{DBhost} );

FSdebug( "Step 1 collect all the underware (uids)" );
open ( PASSWD, $ARGV[0] ) || die "Could not open passwd ";
while ( <PASSWD> ) {
    chop;
    ($uname,$pass,$uid,$gid,$gcos,$home,$shell) = split( ":" );
    $UID{$uid} = 1;
    $GCOS{$uid} = $gcos if ( length($gcos) );
    $ISID{$uid} = $uname;
}
close PASSWD;

#
# collect all know UID's in FSdata UID table
#
FSdebug( "Step 2 query UID's DB" ); 
my %FSUID;
my $rows = FSquery( "select uid, stat from UID" );
for ( my $i=0; $i < $rows; $i++ ) {
    $FSUID{$FStools::data[$i][0]} = $FStools::data[$i][1];
}

#
#  Compair all sources of UID's to what is known in the UID table
#  if new UID are found add them to the UID table
#
FSdebug( "Step 5 Compare" ); 
foreach $uid ( keys %UID ) {
    unless ( exists $FSUID{$uid} ) {
        if ( $uid < 500 ) { FSdebug( "skipping: $uid, $ISID{$uid}" ); next; } 
        if ( $UID{$uid} >= 0 ) {
            my $query = "insert into UID (uid,uname,gcos,stat) values " .
                    "($uid, \'$ISID{$uid}\', \'$GCOS{$uid}\',1);\n " ;
            print $query;
        } 
    }
}
