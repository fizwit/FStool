#!/usr/bin/env perl

use strict;
use warnings;

my %fconf = do 'FSconfig.pl';

print "Title: $fconf{Title}\n";

for my $site (keys %{$fconf{Sites}}) {
   print "$site: $fconf{Sites}{$site}\n";
}
