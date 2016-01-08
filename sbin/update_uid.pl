#!/usr/bin/perl
#
#  update_uid.pl 
#
#  FStool
#  update the UID table 
#
#  search fsdata Database for UID's that are missing from UID table.
#  query local LDAP for GCOS, uname, email
#  insert missing records into UID table 
#
use strict; 

use YAML qw'Dump LoadFile';
use FStools;

sub createUID 
{
  if ( $_[0] eq 'LDAP err' ) {
      FSdebug("skipping: $_[3]");
      return;
   }
   my $query = "insert into UID set GCOS=\'$_[0]\', uname=\'$_[1]\', email=\'$_[2]\', " .
               "uid=$_[3], stat=1";
   my $rows = FSqueryDo($query);
} 

sub main
{
    my $CONF = LoadFile( '../etc/FSconfig.yaml' );
    FSdebugSet( 'yes', 'update_UID' );
    FSconnect( $CONF->{DBusername},
           $CONF->{DBpasswd},
           $CONF->{DBname},
           $CONF->{DBhost} );

    #
    # collect all know UID's in FSdata UID table
    #
    FSdebug( "Step 1 query UID's DB" );
    my %FSUID;
    my $rows = FSquery( "select uid, stat from UID" );
    for ( my $i=0; $i < $rows; $i++ ) {
        $FSUID{$FStools::data[$i][0]} = $FStools::data[$i][1];
    }
    
   
    #
    # collect all know UID's in FSdata UID table; Expect home to have new
    # users and other UID's that are not in the UID table;
    #
    FSdebug( "Step 2 query UID's fsdata DB, Home dir table is used" );
    my @homeUID;
    my $rows = FSquery( "select DISTINCT(uid) from CTCB_home" );
    for ( my $i=0; $i < $rows; $i++ ) {
       $homeUID[$i] = $FStools::data[$i][0];
    }

    #
    #  Compair all sources of UID's to what is known in the UID table
    #  if new UID are found add them to the UID table
    #
    FSdebug( "Step 2 Compare UID from home dir to UID table" ); 
    foreach my $uid ( @homeUID ) {
        unless ( exists $FSUID{$uid} ) {
            if ( $uid < 500 ) { FSdebug( "skipping: $uid" ); next; } 
            my @results = FSgetLDAP( $uid );
            createUID( @results ); 
        }
    }
}

main;
__END__
