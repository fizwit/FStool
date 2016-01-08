#!/usr/bin/env perl
#
#  YAML-check.pl
#
#  verify the correctness of the configuration files for fsdata tools
#
#  Two configuration files: FSconfig.yaml and Site.yaml 
#  The list of Site.yaml files in in FSconfig.yaml
#
use strict;
use YAML qw'Dump LoadFile';

my ($vName, $array, $path, $detail );

my %details;

my $CONF = LoadFile( '../etc/FSconfig.yaml' );
print "<index.html>\n";
print "  Title:    $CONF->{'Title'}\n";
print "  SubTitle: $CONF->{'SubTitle'}\n";
print "  WEBdir:   $CONF->{WEBdir}\n";

my %sites = %{$CONF->{'Sites'}};
foreach my $site ( keys %sites ) {
   print "  $site [$sites{$site}]  Link-> <$site/index.html>\n";
   my $vList = LoadFile( "../etc/$site\.yaml" );    #  Each Site has its own config file

# L1 - $top
@Top = qw(Site Code Title descp groups);
foreach my $top ( keys %$vList ) {
   if ( exists $vList->{$top}{'descp'} ) {
      print "descp=$vList->{$top}{'descp'}\n";
   } else { 
       print "Error: Group->$top does not have field 'descp'\n";
   }
   if ( exists $vList->{$top}{'Title'} ) {
      print "descp=$vList->{$top}{'descp'}\n";
   } else {
       print "Error: Group->$top does not have field 'Title'\n";
   }
   print "Site=$vList->{$top}{'Site'}\n";
   # L2 $project is a Project Name (or description of Group)
   print "  <$site/index.html>:\n";
   print "    Group: $top\n";
   print "    Title: $vList->{$top}{'Title'}\n";
   print "    Descr: $vList->{$top}{'descp'}\n";
   
   foreach my $project ( sort( keys %{$vList->{$top}} )  ) {
      if ( $project =~ /descp/ || $project =~ /Title/ ){
         next;
      }
      #      123456
      print "      Project: $project\n";
      print "      Descrip: $vList->{$top}{$project}{'desp'}\n"; 
      #  Volume Level
      foreach $vName ( sort( keys %{$vList->{$top}->{$project}} ) ) {
         if ( $vName =~ /descp/ ) { next; }
         $path = $vList->{$top}{$project}{$vName}{'path'} ;
         $array =  $vList->{$top}{$project}{$vName}{'array'} ;
         printf( "      %-15s %-15s %s Link -><%s>\n", $vName, $array, $path, "$vName.html" ); 
         if ( exists $vList->{$top}{$project}{$vName}{'detail'} ) {
            my $hash_ref = $vList->{$top}{$project}{$vName}{'detail'};
            %details = %$hash_ref;
            foreach $detail ( keys %details ) {
               printf( "      %-15s %-15s %s Link -><%s>\n", "$vName-$detail", $array, 
                     $details{$detail}, "$vName\_$detail.html" ); 
            }
         }
      }
   }
}
}

