#!/usr/bin/perl
#
#  PurgeTables.pl
#
# '1.0.0 PurgeTable.pl Oct 21, 2010'; First Version
# 1.1.0 Added support for YAML; Keep tables for the first of each month;
#
#  Don't touch this file! Called from Crontab; For adhoc purges make a copy
#  and run.
use strict;
use YAML qw'Dump LoadFile';
use FStools;
use Time::Local;
use File::Copy;

my $DEBUG = 'yes';
my $Version = '1.1.0 PurgeTable.pl Mar 26, 2011';
my $CONF = LoadFile( '../etc/FSconfig.yaml' );


FSconnect( $CONF->{DBusername}, $CONF->{DBpasswd}, $CONF->{DBname}, $CONF->{DBhost} );
FSdebugSet( 'yes', "PurgeTables" );
FSpurgeTables( "select table_name from scan where state = 'complete' and table_name like '1210171\_%')"  ); 
#FSpurgeTables( "select table_name from scan where state = 'complete' and table_name not like '____01\_%' and walk_start < date_sub(now(), interval 10 day)" ); 
