#!/usr/bin/env perl
#
# uidTest.pl 
#
# 2014.08.21  John Dey
# 

use strict;
use YAML qw'Dump LoadFile';
use FStools; 

my @results;

sub updateUID
{
   if ( $_[0] == 'LDAP err' ) {
      return;
   }
   my $query = "insert into UID set GCOS=\'$_[0]\', uname=$_[1], email=$_[2], " .
               "uid=$_[3], stat=1";
   print $query;
   print "\n";
}


if ( $#ARGV == 0 ) {
   @results = FSuid( $ARGV[0] );
   updateUID(@results);
} 

