#!/usr/bin/perl

use Switch;
use JSON;

##########################################
# Check arguments
##########################################
$argc = @ARGV;

if ($argc < 1) {
  print "Usage: " . $0 . " [path]\n";
  exit 0;
}

$path = $ARGV[0];
$suffix = "";

$hars = `ls $path/har$suffix`;
@hars = split(/\n/, $hars);

@sites = ();
open FP, ">domain_country.txt";

$str1 = "";
foreach $har (@hars) {
  @arr = split(/\+/, $har);
  #print $arr[0] . " " . $sites{$arr[0]} . "\n";
  if (exists $sites{$arr[0]}) {
    $sites{$arr[0]}++;
    next;
  } else {
    $sites{$arr[0]} = 1;
  }

  $domain = $arr[0];
  $tmp = `curl http://my-addr.com/domain/$domain`;
  @arr = split(/\n/, $tmp);
  $s = 0;
  foreach $tmp (@arr) {
    if ($s == 1) {
      @arr1 = split(/\>/, $tmp);
      @arr1 = split(/\</, $arr1[1]);
      print $domain . "\t" . $arr1[0] . "\n";
      print FP $domain . "\t" . $arr1[0] . "\n";
      last;
    }
    if ($tmp =~ /COUNTRY/) {
      $s = 1;
    }
  }

  $filename = "$path/har$suffix/$har";
  open FH, $filename;
  $str = "";
  while (<FH>) {
    $str .= $_;
  }
  %har = %{decode_json($str)};
  #print $filename . "\n";

  # get entries
  @entries = @{$har{"log"}{"entries"}};
  foreach $entry (@entries) {
    %entry = %{$entry};
    $ip = $entry{"serverIPAddress"};
    #print $ip;
    if ($ip) {
      #$info = `curl http://api.hostip.info/get_html.php?ip=$ip`;
      #@arr = split(/\n/, $info);
      #print $ip . "\t" . $arr[0];
      last;
    }
  }
}

close FP;
