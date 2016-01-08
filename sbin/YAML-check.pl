#!/usr/bin/perl
#
#  YAML-check.pl
#
#  verify the correctness of the configuration files for fsdata tools
#
#  Two configuration files: FSconfig.yaml and FileSystems.yaml 
#
use strict;
use YAML qw'Dump LoadFile';

my ($tag, $array, $volume, $detail );

my $vList = LoadFile( '../etc/FileSystems.yaml' );
my %details;

print "Verifying Config file: FileSystems.yaml\n\n";


foreach my $group ( keys %$vList ) {
   unless ( exists $vList->{$group}{'description'} ) {
       print "Error: Group->$group does not have field 'description'\n";
   }
   unless ( exists $vList->{$group}{'Title'} ) {
       print "Error: Group->$group does not have field 'Title'\n";
   }
   printf ("Group: %-20s Title: %s\n", $group, $vList->{$group}{'Title'} );
   printf ("Description: %s\n", $vList->{$group}{'description'} );
   # $project is a Project Name (or description of Group)
   foreach my $project ( sort( keys %{$vList->{$group}} )  ) {
         unless ( $project =~ /description/ || $project =~ /Title/ ){
             printf( "  Project: %-13s: ", $project );
             if ( exists $vList->{$group}{$project}{'description'} ) {
                 print "$vList->{$group}{$project}{'description'}\n";
             } else { 
                 print "\n"; 
             }
             # tag 
             foreach $tag ( sort( keys %{$vList->{$group}->{$project}} ) ) {
                 unless ( $tag =~ /description/ ) { 
                     printf( "    tag: %-13s\n", $tag );
                     $volume = $vList->{$group}{$project}{$tag}{'volume'} ;
                     printf ("      volume: %s\n", $volume ); 
                     unless ( -d $volume ) {
                          print "Error Volume: $volume does not exist; Plase check FileSystems.yaml\n";
                     }
                     $array =  $vList->{$group}{$project}{$tag}{'array'} ;
                     print "      array : $array\n" ; 
                     if ( exists $vList->{$group}{$project}{$tag}{'detail'} ) {
                        if ( ref($vList->{$group}{$project}{$tag}{'detail'}) eq "HASH" ){
                           my $hash_ref = $vList->{$group}{$project}{$tag}{'detail'};
                           %details = %$hash_ref;
                           foreach $detail ( keys %details ) {
                              print "      H detail: $detail: $details{$detail}\n"; }
                        } else {
                           $detail = $vList->{$group}{$project}{$tag}{'detail'};
                           print "      S detail: $detail\n";
                        }
                     }
                 }
             }
         }
  }
}

