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
my %all = ();

$ps = `ls $path`;

@arr = split(/\n/, $ps);

my $page = "";
foreach $file (@arr) {
  $file1 = $path . "/" . $file;
  #print $file . "\n";
  open FP, $file1;
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
      @tmp = split(/\/\//, $page);
      $num = @tmp;
      if ($num > 1) {
        $page = $tmp[1];
        $page =~ s/\//\_/g;
      }

    } elsif ($h{"DOMLoad"}) {
      $DOMLoad{$file} = $h{"DOMLoad"};
      #$DOMLoad{$page} = $h{"DOMLoad"};
      #print "page\t" . $page . "\t" . $DOMLoad . "\n";
    } elsif ($h{"Resource"}) {
      $url = $h{"Resource"}{"url"};
      $time = $h{"Resource"}{"sentTime"};

      @tmp = split(/\/\//, $url);
      $url = $tmp[1];
      $url =~ s/\//\_/g;
      $Start{$file} = $time;
      #$Start{$url} = $time;
      #print $url . "\t" . $time . "\n";
    }
  }
  @arrr = split(/\-/, $file);
  $u = $arrr[0];
  if (!$all{$u}) {
    $all{$u} = $DOMLoad{$file} - $Start{$file};
  } elsif ($DOMLoad{$file} - $Start{$file} < $all{$u}) {
    $all{$u} = $DOMLoad{$file} - $Start{$file};
  }
  #print $u . " " . $all{$u} . "\n";
  close FP;
}

@cdf = ();
foreach $key (keys %all) {
  $time = $all{$key};
  #print $key . "\t" . $time . "\n";
  push(@cdf, $time);
}
@cdf = sort {$a <=> $b} @cdf;
$n = @cdf;

$i = 0;
for $time (@cdf) {
  $i++;
  print $time . "\t" . ($i/$n) . "\n";
}
