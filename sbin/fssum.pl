#!/usr/bin/perl
#
# fssum.pl
#
# create grand total of file count and sizes for a single site
#
# 2015.04.07 john dey
#
# produce single html page. 
#

use strict;
use Time::Local;
use Time::Piece;
use POSIX qw(strftime);
use YAML qw'Dump LoadFile';
use File::Basename;
use FStools;

my $Version = "1.0.0 fssum Apr  7, 2015";

sub cmdARG {
    if ( $#ARGV != 0 ) {
        print STDERR "usage: site-code\n";
        exit;
    }
    return $ARGV[0];
}

sub Header {
    my $OUT = shift;
    my $Title = shift;
    my $PageTitle = shift;

    print $OUT "<html>\n<head>\n<title>$Title</title>\n";
    print $OUT "<link rel=\"stylesheet\" type=\"text/css\" href=\"/fsdata/css/fstool.css\"/>\n";
    print $OUT "<body>\n";
    print $OUT "  <h1 align=\"center\">$Title</h1>\n";
    print $OUT "  <h2 align=\"center\">$PageTitle</h2><hr>\n";
}


=head 3 CloseHTML

  argument: file pointer
  write closing html tags to open file pointer,
  close file pointer 
=cut
sub CloseHTML {
    my $OUT = shift;
    my $todaysDate = localtime;
    print $OUT "<footer>\n<strong>Page Update: </strong>$todaysDate";
    print $OUT "    &nbsp<strong>Version: </strong>$Version</span> \n";
    print $OUT "</footer>\n";
    print $OUT "</body>\n</html>\n";
    close $OUT;
}


#----------------------------------
#  The Fun Starts Here
#----------------------------------

sub main {
  my $site = cmdARG(); 
  my $CONF = LoadFile( '../etc/FSconfig.yaml' );
  FSconnect( $CONF->{DBusername}, $CONF->{DBpasswd}, $CONF->{DBname}, $CONF->{DBhost} );
  FSdebugSet( 'yes', 'fssum' );

  FSdebug( "  open: <$CONF->{WEBdir}/$site/sum.html>" );
  open( my $SITE, ">$CONF->{WEBdir}/$site/sum.html" ) or die $!;

  my %sites = %{$CONF->{'Sites'}};
  Header( $SITE, $CONF->{'Title'}, "$site: $sites{$site}" );
  
  print $SITE "<h3>$site Summary Storage Report</h3>\n";
  print $SITE "<table id=\"$site\" >\n<thead>\n";
  print $SITE "<tr><th>Volume</th><th>Size GB</th><th>File count</th>" .
                  "<th>Data Collection Time</th></tr>\n";
 
  my ($gb, $human, $Tsum, $Tcount); 
  my $yam = LoadFile( "../etc/$site\.yaml" );
  foreach my $vol ( sort(keys %{$yam}) ) {
    my $query = "select count(*), sum(size) from $yam->{$vol}{table}";
    my ($count, $sum) = FSquerySingle( $query );
    print $SITE "<tr><td>$yam->{$vol}{path}</td>";
    $gb = FSgb($sum);
    $human = FShuman($count);
    $Tsum += $sum;
    $Tcount += $count;
    $query = "select fname, mtime from $yam->{$vol}{table} where fname ='$yam->{$vol}{source}/.fstool'";
    my ($fname, $mtime) = FSquerySingle( $query );
    my $collDate = localtime($mtime)->strftime('%F %T'); # adjust format to taste
    print $SITE "<td class=right>$gb</td><td class=right>$human</td><td>$collDate</td>\n</tr>";
  }
  $gb    = FSgb($Tsum);
  $human = FShuman($Tcount);
  print $SITE "<tr><td>Sum</td>";
  print $SITE "<td class=right>$gb</td><td class=right>$human</td>\n</tr>";
  print $SITE "</table>\n";
  FSdebug("File Count: $Tcount");
  CloseHTML ( $SITE );
  chmod 0644, "$CONF->{WEBdir}/$site/sum.html"; 
}

main;
__END__

