package FStools;
#
# 2009.12.11  John Dey
# 2010.03.22 John Dey Various formating changes; absolute path for png added
# 2010.06.20 If second argument is not provided to not run historic reports
#          Add third argement to allow indetification of each volum name <$tag>
#           Argument List: tag Date Past
# 2010.09.12 john dey epoch for FStools.pm; Written from recylced fstools
#            routines
# 2010.10.11 john dey add RefLnk feature
# 2015.03.12 john dey epoch format feature to for FSprintTable ; (modify time)

use strict;
#use warnings;
use DBI;
use DBD::mysql;
use Net::LDAP;
use Net::LDAP::Util qw(ldap_error_text);
use Net::LDAP::Search;
use Time::Local;
use POSIX qw(strftime);
use YAML qw'Dump LoadFile';
use Exporter;
use File::Basename;
use base 'Exporter';

our @EXPORT = qw(FSconnect FSdisconnect FSrenameTable FSquery FSqueryOnly FSfetch FSsetData FSgetData FSuid FSgetLDAP FSprintTable FSquerySingle FSdebug FScomputeCost FSdebugSet FSscanStart FSscanEnd FSscanSet FSscanStatus FSpurgeTables FShuman FSmoney FScommify FSgb FSqueryDo FSgetVolList FSgetVolconf );
our @data;                 # rows and col data from DB query
our ($DBrows, $DBcols);  # set row & col sizes after query

#my $VERSION = "1.3.0 Oct 11, 2010";
#my $VERSION = "1.4.0 Jan 21, 2014";  # FSfetch
my $VERSION = "1.4.1 Mar 12, 2015";  # epoch feature to FSprintTable 
my $DBconnected =0;
my $LDAPconnected =0;
my $FSdebug = 'no';
my $FSwhoami = 'none';
# MySQL
my $dbh;
my $DBptr;
# LDAP
my $ldaphost = 'ctchpcva001';
my $ldap;   #LDAP object


=head1 Name

FStools - A collection of MYSQL tools for querying MySQL Databases
and creating HTML reports. These modules were created to support
FStools (File System Tools)

=head1 SYNOPSIS

    use Keystone::FStools;

=head1 DESCRIPTION

A collection of tools to query MySQL and create HTML tables. General purpose
query accepts SQL Select statements. Data is stored within the module. 
A general purpose printTable function creates HTML table output into a
single file each time it is called. printTable funciton allows simple
table formatting [left right, coma, human, htmlLink] It is expected that 
query and print table functions will be called in pairs.

=head2 Functions

FStools Functions

=head3 FSdebugSet

    Turn debugging on/off and set the name of the program
    arguments ['yes'|'no'] (program name)
    output: none
    return value: none

    examples: 
    FSdebugSet( 'yes', 'account.pl' );
    FSdebugSet( 'no' );

=cut

sub FSdebugSet {
    unless ( $#_ == 0 || $#_ == 1 ) {
        die "$#_ FSdebugSet ['yes'|'no'] (program name)\n";
    }
    if ( $#_ >= 0 ) {
       $FSdebug = shift;
    }
    if ( $#_ >=0 ) {
       $FSwhoami = shift;
    }
}

=head3 FSdebug

    Arguments: single scalar passed as an argument (without newline)
    Return: None
    Output: output is written to STDERR with Format: DateTime Stamp ProgramName String
    Summary:  I really miss having a D in column 6 (FORTRAN). This routine 
    allows you to keep embeded debug statements in Perl programs. 
    They can be turned on/off with FSdebugSet(). No code is ever realy finished
    so its nice to have debug statements in place when fixing or adding 
    features. With FSdebugSet you can not turn on/off within a program so you 
    can have them in the area you work working on. 

=cut

sub FSdebug{
    if ( $FSdebug eq 'yes' ) {
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);
        ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
        printf STDERR "%4d-%02d-%02d %02d:%02d:%02d %s: %s\n",
               $year+1900, $mon+1, $mday, $hour, $min, $sec, $FSwhoami, shift;
    }
}

# put som comma's in the numbers to make it easy to read
#
sub FScommify {
   local $_ = shift;
   1 while  s/^([-+]?\d+)(\d{3})/$1,$2/;
   # Alternative - $number =~ s/(\d)(?=(\d{3})+(\D|$))/$1\,/g;
   return $_;
}

=head3 FSmoney
  FSmoney formats a number as money. Dollar sign prepended; Always formated as
  two deceimal points
=cut
sub FSmoney {
   my $val = shift;
   my $num = sprintf( "%.2f", $val ); 
   1 while $num =~  s/^([+-]?\d+?)(\d{3})(?>((?:,|\.|$)\d?))(.*)$/$1,$2$3$4/;
   return '$' . $num; 
}

=head3 FSgb
  FSgb convert number of bytes into number of Gigabytes
  input is bytes
  output is rounded to nearest GB returned as integer 
=cut
sub FSgb {
    my $bytes = shift;
    $bytes = $bytes / 1073741824.0;
    my $round = int( $bytes * 10 + .5);
    $bytes = int($round/10);
    $bytes = FScommify($bytes);
    return "$bytes";
}

=head3
   Print human readable sufix on data. Input is asumed to be bytes. Other
   units can be used by passing the unit base. 1024 based calculations
   1024  = 1KB
   "G",1024 = 1TB
=cut
sub FShuman {
  my $base = "B";
  if ( $#_ == 1 ) {$base = shift; }
  my $bytes = shift;
  my $factor =0;
  my $sign = "";
  my @SUFFIXES = ( 'B', 'K', 'M', 'G', 'T', 'P', 'E', 'Z', 'Y');

  for ( $base ) {
    if ( /^B/ ) { $factor =0; }
    elsif ( /K/ ) { $factor =1; }
    elsif ( /M/ ) { $factor =2; }
    elsif ( /G/ ) { $factor =3; }
  }
  if ( $bytes < 0 ) {
    $sign='-';
    $bytes = - $bytes;
  }
  while ( $bytes > 1024 && $factor < 8 ) {
    $bytes = $bytes / 1024;
    $factor = $factor+1;
  }
  my $round = int( $bytes * 10 + .5);
  $bytes = $round/10;
  return $sign . $bytes . $SUFFIXES[$factor];
}

=head3
    PrivateConnect
    Create DB connection if not currently connected. 
=cut
sub PrivateConnect {
    if (  $DBconnected == 1 ) {
        return;
    }
    my $CONF = LoadFile( '../etc/FSconfig.yaml' );
    FSconnect( $CONF->{DBusername}, $CONF->{DBpasswd}, $CONF->{DBname}, $CONF->{DBhost} );
}

=head3 FSconnect

    Connect to mysql Database 
    Arguments: username, passwd, database, hostname 
    Return Value: none

    example: FSconnect( "fsuser", "mypasswd", "fsdata", "lctcsh6008" );

=cut

sub FSconnect {
    my $username = shift;
    my $passwd = shift;
    my $database = shift;
    my $hostname = shift; 

    if ( $DBconnected == 1 ) {
        return;
    }
    my $dsn = "DBI:mysql:database=$database;host=$hostname";

    $dbh = DBI->connect($dsn, $username, $passwd) 
      or die "Cant connect to the database Doh!\n";
    $DBconnected = 1;
    return;
}

=head3 FSdisconnect

    disconnect session to mysql

=cut

sub FSdisconnect {
    if ( $DBconnected == 0 ) {
        print STDERR "can't disconnect: already disconnected\n";
        return;
    }
    $dbh->disconnect() or warn "Disconnection failed: $DBI::errstr\n";
    $DBconnected = 0;
}

=head3

    FSgetLDAP
    search by UID number
    return GECOS, uname, email

=cut
sub FSgetLDAP {
    my $luid = shift;
    # Account numbers below 999 reserved for system accounts
    if ( $luid == 0 ) {
       return ("System Acct", "root", 0 );
    }
    
    $ldap = Net::LDAP->new( $ldaphost ) or die "$@";
    my $base = 'dc=ctchpc,dc=merck,dc=com';
    my $mesg = $ldap->search(
             base => "$base",
             filter => "uidNumber=$luid"
              );
    if ( $mesg->code )  {
        print ldap_error_text($mesg->code);
        return ("LDAP err", "error", 0); 
    }
    my @cn = []; my @Isid = []; my @GECOS = []; my @mail =[];
    $Isid[0] = ""; @GECOS[0] = ""; @mail[0] = "";
    foreach my $entry ( $mesg->entries) {
       #print "entry: ", $entry;
       @GECOS = $entry->get("gecos");
       @Isid = $entry->get("uid");
       @cn   = $entry->get("cn");
       @mail = $entry->get("mail");
    }
    FSdebug("GECOS: $GECOS[0], ISID: $Isid[0], uid: $luid");
    if (length($Isid[0]) == 0 ) {
       return ("LDAP err", "error", "", $luid);
    }
    if ( length($GECOS[0]) == 0 ) {
       $GECOS[0] = "na";
    }
    if ( length($mail[0]) == 0 ) {
       $mail[0] = " ";
    }
    return ( ($GECOS[0], $Isid[0], @mail[0], $luid) );
}

=head3
    FSuid
    lookup UID information from UID table 
    GECOS, uname, uid
=cut
sub FSuid {
    my $luid = shift;
    # Account numbers below 999 reserved for system accounts
    if ( $luid == 0 ) {
       return ("System Acct", "root", 0 );
    }
    #  Check FStool Database for old accounts
    PrivateConnect();
    my @results = FSquerySingle( "select GCOS, uname, uid from UID where uid=$luid" );
    unless ( $results[0] eq "no rows" ) {
       return @results;
    }
    #  Return an low system IDs as system accounts
    if ( $luid < 999 ) {
       return ("System UID", "~$luid", $luid  );
    }
    #  No luck with DB try LDAP
    if ( $LDAPconnected == 0 ) {
        $ldap = Net::LDAP->new( $ldaphost ) or die "$@";
        $LDAPconnected = 1;
    }
    my $base = 'dc=ctchpc,dc=merck,dc=com';
    my $mesg = $ldap->search(
             base => "$base",
             filter => "uidNumber=$luid"
              );
    if ( $mesg->code )  {
        print ldap_error_text($mesg->code);
        return ("LDAP err", "error", 0); 
    }
    my @Isid = []; my @GECOS = []; my @mail =[];
    foreach my $entry ( $mesg->entries) {
       #print "entry: ", $entry;
       @Isid = $entry->get("uid");
       @GECOS = $entry->get("gecos");
       @mail = $entry->get("mail");
       return ( ($GECOS[0], $Isid[0], @mail[0], $luid) );
    }
}

=head3 FSrenameTable

    Argument: old_table new_table
    We do not care about the result
    The main purpuse of rename table is to garontee that
    a create table does not fail with duplicate name errors

=cut

sub FSrenameTable {
    my $old = shift;
    my $new = shift;
    my $query = "RENAME TABLE  $old TO $new";
    my $stat = $dbh->do( $query );
    FSdebug( "RenameTable Result: $stat" );
    return $stat;
}

=head3 FSquery

    Argument: Single scalar with SQL select statement
    Output: @data[x][y] (not exported)
    return values: none

    Example: FSquery( 'select GCOS, uname, uid from UID' );
    Summary: It is assumed that FSquery and FSprintTable are always
    in pairs.  If FSquery is run twice the data from the first query
    is overwritten in @data.

=cut

sub FSquery {
   my $query = shift;

   FSdebug( $query ); 
   my ($i, $j);
   my $sth = $dbh->prepare( $query )
     or die "Couldn't prepare statement: " . $dbh->errstr;

   $sth->execute() or die "Couldn't execute statement: " . $sth->errstr;
   $DBrows = $sth->rows();
   FSdebug( "Number of rows returned: $DBrows\n" ) ;

   $i =0;
   while ( my @elements = $sth->fetchrow_array() ) {
      @elements= map { defined ($_) ? $_ : "Null" } @elements;
      if ( $i == 0 ) { $DBcols = $#elements; }
      for $j ( 0 .. $#elements ) {
          $data[$i][$j] = $elements[$j];
      }
      $i = $i +1;
   }
   return $DBrows;
}

=head3 FSqueryOnly

    Query with no fetch or data load 

=cut
sub FSqueryOnly{
   my $query = shift;

   my $sth = $dbh->prepare( $query )
     or die "Couldn't prepare statement: " . $dbh->errstr;
   $sth->execute() or die "Couldn't execute statement: " . $sth->errstr;
   $DBrows = $sth->rows();
   $DBptr = $sth;
   return $DBrows;
}

=head3 FSfetch

    return array pointer of Max rows 
    each succuessive call returns the next group of rows 

=cut
sub FSfetch {
    my $max_rows = 5000;
    my $aref = $DBptr->fetchall_arrayref(undef, $max_rows);
    return $aref;
}

=head3 FSquerySingle

    Return a list of values from a MYSQL select statment. The select statement
    should be designed to return only one row.

=cut

sub FSquerySingle {
    my $query = shift;
    FSdebug( "Single: $query" );
    my $sth = $dbh->prepare( $query )
    or die "Couldn't prepare statement: " . $dbh->errstr;

    $sth->execute() or die "Couldn't execute statement: " . $sth->errstr;
    my $rows = $sth->rows();
    FSdebug( "FSquerySingle: rows=<$rows>" ) ;

    if ( $rows == 1 ) {
        my @elements = $sth->fetchrow_array();
        return @elements;
    } else {
       return ( "no rows" );
    }
}

=head3 FSqueryDo

    Implement dbh->do( query ); query returns nothing; 
    die on failure; Use for insert, update, create etc...

=cut

sub FSqueryDo {
    my $query = shift;
    FSdebug( "Do: $query" );

    my $stat = $dbh->do( $query ) or die "Couldn't DO : " . $dbh->errstr;
    return $stat;
}

=head3 FSgetData FSsetData

   manipulate FStool data structure

=cut
sub FSgetData {
    my $row = shift;
    my $col = shift;
    return $data[$row][$col];
}
sub FSsetData {
    my $row = shift;
    my $col = shift;
    my $value = shift;
    $data[$row][$col] = $value;
}

=head3 FScomputeCost

    Add a new colum to $data
    Arguments: $index, $factor
    new column is computed from existing column 
    new column = $data[$][$index] * $factor

=cut
sub FScomputeCost {
   my $index = shift;
   my $factor = shift;

   $DBcols += 1;
   my $i;
   for $i ( 0 .. $DBrows ) {
      if ( $data[$i][$index] <= $factor ) {
          $data[$i][$DBcols] = 0.10;
      } else {
          $data[$i][$DBcols] = $data[$i][$index] / $factor;     
      }
   }
}

sub FScomputeTotal {
     
}

=head3 FSprintTable

    Write the results from a query. Output is in html table format. Each call
    to FSprintTable produces a single output file that is a stand alone web
    page. The parameters are messy. Look at the example first.

    Three Arguments; Each are lists. Note the lists (arrays) need to be escaped so that
    three lists are passwd and not the concatenation of 3 lists. 
    FSprintTable( \@reportTitle, \@headerText, \@colFormat );


    Arg One: List containing; Item Flag (explained later), Header Text, Title Text, 
    File name, Name of Volume (or the object you are reporting on. 
      element 0: flag ID; Use column value to flag a row
      element 1: "Title"
      element 2: "Sub Title"
      element 3: "file name"
      element 4: "volumenName"

    Arg Two:  List of Header Text; One element for each column

    Arg Three: List of Column Formats; One element for each column

    Example: 
    @reportTitle = (4, "File System Utilization", "Utilization by User",
             "$outDir/$tag\_UIDsize.html", $volumeName );
    # <4> indicates that the 4th column is treated as a flag.  If flag > 0 the row is
    # higlighed if value is <0> no high light; If your query does not have "status" flag
    # set flag to 0. (zero).
    @headerText = ("User", "UID", "Amt Used", "Number of Files" );
    @colFormat = qw(text text humanRight commaRight );
    FSprintTable( \@reportTitle, \@headerText, \@colFormat );

=cut

sub FSprintTable {
    my @title = @{ $_[0] };
    my @headerText = @{ $_[1] }; 
    my @colFormat = @{ $_[2] };

    my ($flag,$i, $j, $align, $size, $cnt, $cell);

    FSdebug( "output file: $title[3]" );
    $flag = $title[0];
    open( RPT, ">$title[3]" ) or die "could not open: $title[3]";
    my $todaysDate = localtime;
    my $htmlID = fileparse($title[3], qr/\.[^.]*/);
print RPT <<"EOT";
<!DOCTYPE html>
<html>
  <head>
    <link rel="stylesheet" type="text/css" href="/fsdata/css/fstool.css" />
    <script type="text/javascript" src="/fsdata/js/sorttable.js"></script>
    <title>fstool storage reports</title>
  </head>
  <body>
    <center><h2>$title[4]</h2>
       <h3><b>Report Date: </b> $todaysDate</h3>
    </center>
    <hr>
    <h2>$title[1]</h2>
    $title[2]
EOT
    if ( $flag > 0 ) {
        print RPT <<"EOT2";
    <table border=0>
      <tr>
        <td><img border=1 hspace=3 src='/images/orange.gif'></td>
        <td valign=middle>Disabled Acounts</td> 
      </tr>
    </table>
EOT2
    }
    my $DBcolumns = $#headerText;
    FSdebug("rows=$DBrows, columns=$DBcols" );
    print RPT <<"EOT3";
    <table id="$htmlID" class="sortable" > 
      <thead>
        <tr>
EOT3
    foreach my $col ( @headerText ) {
        print RPT "<th>$col</th>";
    } print RPT "</tr>\n    </thead>\n";
    for ( $i = 0; $i < $DBrows; $i++ ) {
        if ( $flag > 0 && $data[$i][$flag] == 0 ) {
            print RPT "<tr  bgcolor=#ff6800>"; 
        } else {
            print RPT "<tr>"; }
        for $j ( 0 .. $DBcolumns  ) {
            $data[$i][$j] = "&nbsp" if ( length( $data[$i][$j]) == 0 );
            $align = 'left';
            for( $colFormat[$j] ) {
              if ( /text/ )  { $cell = $data[$i][$j]; }
              elsif ( /human/ ) { $cell = FShuman($data[$i][$j]); }
              elsif ( /GB/ ) { $cell = FSgb( $data[$i][$j] ); }
              elsif ( /comma/ ) { $cell = FScommify($data[$i][$j]); }
              elsif ( /percent/ ) { $cell = sprintf( "%02d%%", int( $data[$i][$j]*100)); }
              elsif ( /money/ ) { $cell = FSmoney($data[$i][$j]);  } 
              elsif ( /epoch/ ) { $cell = strftime( "%Y-%m-%d %H:%M", localtime($data[$i][$j])); }
              elsif ( /hide/ ) { $align = 'hide' }
              if ( /Right/ ) {$align='right'}
              if ( /Link/ )  {
                      my $arg =~ /Link(.*)/;
                      $cell = "<a href=$1>$cell</a>"; 
              }
              # RefLnk; subsitute a column value for token <#> in text
              # Format: ReflnkNString  N: column index; String is href
              if ( /RefLnk/ ) { # RefLnk: subsitute a column value for token
                                # token: # in string
                                # RefLnkN  N: column value
                  my $arg =~ /RefLnk(.)(.*)/;
                  $1 =~ s/#/$data[$i][$2]/;
                  $cell = "<a href=$2>$cell</a>";
              }
            }
            print RPT "<td class=$align>$cell</td>" unless ( $align eq 'hide' );
       }
       print RPT "</tr>\n";
    }
    print RPT "   </table></body></html>\n";
    close RPT;
    chmod 0644, $title[3];
}

=head3 FSscanStatus
=over 4

Return scalar value of "state" from scan table 
arg1: table name 

=cut

sub FSscanStatus {
    my $table_name = shift;
    my $state;

    my $query = "select state from scan where table_name = \'$table_name\'";
    my $sth = $dbh->prepare( $query ) or die "died preparing scanStatus" . $dbh->errstr;
    $sth->execute() or die "Couldn't execute statement: " . $sth->errstr;
    if ( $sth->rows() != 1 ) {
       return "none";
    }  
    my @elements = $sth->fetchrow_array();
    $state = $elements[0];
    return $state;
}

=head3 FSscanStart
=over 4

Write a record into the 'scan' table before call pwalk.

Arg1: array name
arg2: volume name
arg3: tag
arg4: table name (that will hold output data from pwalk)

=cut

sub FSscanStart {
    my $array = shift;
    my $volume = shift;
    my $tag = shift;
    my $tableName = shift;
    my $host = shift;

    # get the df infor for the volume
    my $dfout = `df -P $volume`;
    my ($one, $two) = split /\n/, $dfout;
    my ($fs, $size , $used, $avail, $percent, $mount) = split /\s+/, $two;
    my $query = "insert into scan set array=\'$array\', " .
    "volume = \'$volume\', " .
    "tag = \'$tag\', " .
    "table_name = \'$tableName\', " .
    "walk_host = \'$host\', " .
    "walk_start = NOW(), state = 'scanning', " .
    "dfsize = $size, dfavail = $avail, dfused = $used ";
    #FSdebug( "FSscanStart: $query" );
    my $rows = $dbh->do( $query )
        or die "scanStart: insert into scan table\n";
}

=head3 FSscanSet
=over 4

Set the 'state' field in the scan table

Arg1: table_name YYMMDD_TAG_[data/user] 
arg2: state [

=cut

sub FSscanSet {
    my $state = shift;
    my $tableName = shift;

    my $query = "update scan set state = \'$state\' " .
       "where table_name = \'$tableName\'";
    my $rows = $dbh->do( $query )
        or die "Can't update scan table\n";
}


=head3 FSscanEnd
=over 4

Write a record into the 'scan' table after pwalk completes

Arg1: array name
arg2

=cut

sub FSscanEnd {
    my $tableName = shift;

    my $query = "update scan set walk_end = NOW(), state='scanned' where " .
                "table_name = \'$tableName\'";
    #FSdebug( "FSscanEnd: $query" );
    my $rows = $dbh->do( $query )
        or die "Can't update scan table\n";
}

=head3 FSpurgeTables
=over 4

Single argument is a select statement to specify a table name.
Each table is droped so be careful.
Each table name is marked as 'purged' in the scan table if it exists.

=cut

sub FSpurgeTables {
   my $query = shift;
   my $sth = $dbh->prepare( $query )
     or die "Couldn't prepare statement: " . $dbh->errstr;

   $sth->execute() or die "Couldn't execute statement: " . $sth->errstr;
   $DBrows = $sth->rows();
   FSdebug( "Number of rows returned: $DBrows\n" ) ;

   my $rows;
   while ( my $table = $sth->fetchrow_array() ) {;
      $query = "update scan set state = 'purged' where table_name = \'$table\'";
      $rows = $dbh->do( $query )
        or die "Can't update scan table: $query\n";
      FSdebug( "Drop Table: $table" );
      $query = "drop table $table";
      $rows = $dbh->do( $query )
        or FSdebug( "Can't drop table: $table"); 
   }
}

=head2 FSgetvList

  Get Volume List
  read YAML site config file and return a 'list' of volume names
  Arguments: Site name
  Site name is used to create YAML configuration file name

=cut
sub FSgetVolList {
   my $site = shift;
   my @vlist;
   my %yam;
   my $yam = LoadFile( "../etc/$site\.yaml" );    #  Each Site has its own config file
   # L1 - $group - Level 1
   foreach my $vName ( keys %{$yam} ) {
      push (@vlist, $vName);
   }
   return \@vlist;
}

sub FSgetVolconf {
   my $site = shift;
   my $Rname = shift;

   my %conf;
   my @items = qw(fname table descp source path array);
   my $yam = LoadFile( "../etc/$site\.yaml" );    #  Each Site has its own config file
   # L1 - $volume - Level 1
   foreach my $vol (keys %$yam) {
      if ( $vol eq $Rname ) {
         $conf{vol} = $vol;
         for my $item (@items) {
            if ( exists $yam->{$vol}{$item} ) {
               $conf{$item} =  $yam->{$vol}{$item};
            }
         }
         return \%conf; 
      }
   }
   return ("not-found");
}

=head1 BUG REPORTS
=over 4

    Report bugs to john@fuzzdog.com john_dey@merck.com

    AUTHOR

    This module written by John Dey john@fuzzdog.com

=cut
1;
