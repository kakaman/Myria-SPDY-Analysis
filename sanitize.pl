#!/usr/bin/perl

use Switch;
use JSON;

##########################################
# Check arguments
##########################################
$argc = @ARGV;

if ($argc < 2) {
  print "Usage: " . $0 . " [path]\n";
  exit 0;
}

$path1 = $ARGV[0];
$path2 = $ARGV[1];

%pages = ();

$ls = `ls $path1`;
@hars = split(/\n/, $ls);

foreach $har (@hars) {
  @arr = split(/\-/, $har);
  $url = $arr[0];
  $pages{$url} = 1;

  #print $url . "\n";
  # write to file
  #$f = "$path_pro/$page";
  #open(FH, ">$f");
  #print FH $buf;
  #close FH;
}

$ls = `ls $path2`;
@hars = split(/\n/, $ls);

%counts = ();

foreach $har (@hars) {
  @arr = split(/\-/, $har);
  $url = $arr[0];
  if ($pages{$url}) {
    if ($counts{$url}) {
      $counts{$url}++;
    } else {
      $counts{$url} = 1;
    }
    if ($counts{$url} == 6) {
      print "delete: " . $har . "\n";
      print `rm $path2/$har`;
    }
  } else {
    # delete!
    print "delete: " . $har . "\n";
    print `rm $path2/$har`;
  }
}
