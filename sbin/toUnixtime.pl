#!/usr/bin/env perl
#
#
use Date::Parse;

my $mtime = 1409886594;
my $collDate = localtime($mtime);

print "date=$collDate\n";
#print str2time('2010-04-29 19:49:26.000000'), "\n";

# Perl 5.10

#use Time::Piece;
#my $t = Time::Piece->strptime(shift,"%d %B %Y %H:%M:%S");
#print $t->epoch, "\n";


