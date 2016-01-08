#!/usr/bin/env perl
#
#   
use strict;
use YAML qw'Dump LoadFile';
use FStools;

my $site = 'Test';

my $yam = LoadFile( "../etc/$site\.yaml" );
foreach my $vol ( sort(keys %{$yam}) ) {
    print STDERR "volume=$vol\n"; 
    print STDERR "    $yam->{$vol}{path}\n";
    print STDERR "    $yam->{$vol}{fname}\n";
    print STDERR "    $yam->{$vol}{table}\n";
    if ( exists $yam->{$vol}{detail} ) {
       my $list = $yam->{$vol}{detail};
       foreach my $d ( @$list ) {
          print STDERR "    desp: $d->{descp} Path: $yam->{$vol}{path}$d->{path}\n";
       } 
    }
}

