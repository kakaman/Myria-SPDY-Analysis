#!/usr/bin/perl

use Switch;
use JSON;

##########################################
# Check arguments
##########################################

$filename = "domain_country.txt";

open FP, $filename;

while ($line = <FP>) {
  @arr = split(/\n/, $line);
  @arr = split(/\t/, $arr[0]);
  $domain = $arr[0];
  $c = $arr[1];
  $continent = "";
  if (     $c eq "China"
        or $c eq "Japan"
        or $c eq "India"
        or $c eq "Vietnam"
        or $c eq "Thailand"
        or $c eq "Singapore"
        or $c eq "Indonesia"
        or $c eq "Israel"
        or $c eq "Iran, Islamic Republic of"
        or $c eq "Hong Kong"
        or $c eq "Korea, Republic of"
        or $c eq "Taiwan") {
    $continent = "Asia";

  } elsif ($c eq "United States"
        or $c eq "Mexico"
        or $c eq "Canada") {
    $continent = "North America";

  } elsif ($c eq "Netherlands"
        or $c eq "Germany"
        or $c eq "Europe"
        or $c eq "Spain"
        or $c eq "Ireland"
        or $c eq "Italy"
        or $c eq "France"
        or $c eq "Sweden"
        or $c eq "Norway"
        or $c eq "Turkey"
        or $c eq "Portugal"
        or $c eq "Romania"
        or $c eq "Ukraine"
        or $c eq "Cyprus"
        or $c eq "Luxembourg"
        or $c eq "Hungary"
        or $c eq "Switzerland"
        or $c eq "Russian Federation"
        or $c eq "United Kingdom"
        or $c eq "Poland") {
    $continent = "Europe";
  }
  #print $line;
  #print $domain . " " . $continent . "\n";
  if ($continent eq "") {
    #print $line . $continent;
  } else {
    print $domain . "\t" . $continent . "\n";
  }
}

close FP;
