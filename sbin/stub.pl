#!/usr/bin/env perl

use strict;
use FStools;

my $site='CTC-B';

my $vList = FSgetvList( $site );
my $conf;

for my $vol (@$vList) {
  print "vol=$vol\n";
  $conf = FSgetconf( $site, $vol);
  foreach my $item (keys %$conf) {
    print "  $item=$conf->{$item}\n";
  }
}
