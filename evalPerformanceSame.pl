#!/usr/bin/perl

#use ProcessAdapter;
use JSON;

##########################################
# Check arguments
##########################################
$argc = @ARGV;

if ($argc < 1) {
  print "Usage: " . $0 . " [filepath]\n";
  exit 0;
}
$path = $ARGV[0];

my %DOMLoad = ();
my %Start = ();

$ps = `ls $path`;

@arr = split(/\n/, $ps);

@plts = ();

my $page = "";
foreach $file (@arr) {
  $file = $path . "/" . $file;
  #print $file . "\n\n\n";

  $a_page = undef;
  $a_domload = undef;
  $a_start = undef;
  open FP, $file;
  while ($line = <FP>) {
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

    %h = %{decode_json($line)};
    if ($h{"page"}) { 
      $page = $h{"page"};
      #$page = $file;
      @tmp = split(/\/\//, $page);
      $num = @tmp;
      if ($num > 1) {
        $page = $tmp[1];
        $page =~ s/\//\_/g;
      }
      $a_page = $h{"page"};

    } elsif ($h{"DOMLoad"}) {
      $DOMLoad{$page} = $h{"DOMLoad"};
      #print "page\t" . $page . "\t" . $DOMLoad{$page} . "\n";
      $a_domload = $h{"DOMLoad"};
    } elsif ($h{"Resource"}) {
      $url = $h{"Resource"}{"url"};
      $time = $h{"Resource"}{"sentTime"};

      @tmp = split(/\/\//, $url);
      $url = $tmp[1];
      $url =~ s/\//\_/g;
      $Start{$url} = $time;
      if ($url eq $a_page) {
        $a_start = $time;
        #print $url . "\t" . $time . "\n";
      }
    }

  }
  push(@plts, 1000 * ($a_domload - $a_start));
  #print 1000 * ($a_domload - $a_start) . "\n";
  close FP;
}

@plts = sort {$a <=> $b} @plts;
$n = @plts;

foreach $plt (@plts) {
  #print $plt . "\n";
}

print "min:\t" . $plts[0] . "\n";
print "med:\t" . $plts[$n / 2] . "\n";
print "max:\t" . $plts[$n - 1] . "\n";

