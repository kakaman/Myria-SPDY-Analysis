#!/usr/bin/perl

use Switch;
use JSON;
use DBI;

##########################################
# Check arguments
##########################################
$argc = @ARGV;

if ($argc < 1) {
  print "Usage: " . $0 . " [path]\n";
  exit 0;
}

$path = $ARGV[0];
$suffix = "_pro";
$path_pro = $path . $suffix;

print `mkdir $path_pro`;

$ls = `ls $path`;
@hars = split(/\n/, $ls);

foreach $har (@hars) {
  my $file = "$path/$har";
  print $file . "\n";
  #open(FP, $file) || die("Couldn't open file!\n");
  $db = DBI->connect("dbi:SQLite:dbname=$file", "", "", {RaiseError => 1, AutoCommit => 1});
  $items = $db->selectall_arrayref("select * from wprof_logs");

  my $line;
  my $buf = "";
  my $page = "_";
  my %pages = ();
  foreach $item (@$items) {
    ($id, $ts, $line) = @$item;

    # Do not consider other stderr info
    $c = substr($line, 0, 1);
    if ($c ne "{") {
      next;
    }
    $c = substr($line, length($line) - 2, 1);
    if ($c ne "}") {
      next;
    }
    @a = split(/\n/, $line);
    $line = $a[0];
    $line =~ s/World's/Worlds/g;
    $line =~ s/world's/worlds/g;
    $line =~ s/What's/Whats/g;
    $line =~ s/Life's/Lifes/g;
    $line =~ s/&png='http/&png=http/g;
    $line =~ s/CH%253D'/CH%253D/g;
    $line =~ s/'\)%3B/\)%3B/g;
    $line =~ s/document.write\('/document.write\(/g;
    $line =~ s/'&pip=''&tpi='http/&pip=&tpi=http/g;
    $line =~ s/&png='http/&png=http/g;
    $line =~ s/33'&/33&/g;
    $line =~ s/'&pip=''&tpi='/&pip=&tpi=/g;
    $line =~ s/%3D10606672%24%24'/%3D10606672%24%24/g;
    $line =~ s/'tp_CampaignName/tp_CampaignName/g;
    $line =~ s/'pw_post_1'/pw_post_1/g;
    $line =~ s/''/0/g;
    $line =~ s/____CH.253D'./____CH.253D./g;
    $line =~ s/29'.455890320/29.455890320/g;
    $line =~ s/29'.370756285/29.370756285/g;
    $line =~ s/29'.47473439/29.47473439/g;
    $line =~ s/29'.209734307/29.209734307/g;
    $line =~ s/scriptsrc="includes/scriptsrc=includes/g;
    $line =~ s/Government's/Governments/g;
    $line =~ s/.ca.'&r=''/.ca.&r=/g;
    $line =~ s/p='http/p=http/g;
    $line =~ s/Finest's/Finests/g;
    $line =~ s/29'.918966657/29.918966657/g;
    $line =~ s/Carl's/Carls/g;
    $line =~ s/Let's/Lets/g;
    $line =~ s/Crkiye'nin/Crkiyenin/g;
    $line =~ s/'getTransport'/getTransport/g;
    $line =~ s/Complete'/Complete"/g;
    $line =~ s/web's/webs/g;
    #$line =~ s/'/"/g;


    $line =~ s/WprofHTMLTag/ObjectHash/g;

    $buf .= $line . "\n";

    %h = %{decode_json($line)};
    if ($h{"page"}) {
      $page = $h{"page"};
    } elsif ($h{"Complete"}) {
      #print $h{"Complete"} . "\n";

      if ($pages{$page}) {
        $pages{$page} += 1;
      } else {
        $pages{$page} = 1;
      }

      $time = $pages{$page};
      # write to file
      $f = "$path_pro/$page-$ts-$time";
      open(FH, ">$f");
      print FH $buf;
      close FH;

      # clear buffer
      $buf = "";
    }
  }

  close FP;
}
