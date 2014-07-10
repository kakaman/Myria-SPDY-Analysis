#!/usr/bin/perl

package UtilPlot;

# Output CDF to the specified file name
# @param  string: filename
# @param  ref array:  float/int
# @return float/int: median value
#
sub outputCDF {
  my $filename = $_[1];
  my @arr = @{$_[2]};
  open FP, ">$filename";
  @arr = sort {$a <=> $b} @arr;
  my $i = 0;
  my $num = @arr;
  foreach my $e (@arr) {
    $i++;
    my $perc = $i / $num;
    print FP $e . "\t" . $perc . "\n";
  }
  close FP;

  # calculate percentage
  return $arr[int($num / 2)];
}

# Output scatter plot data to the specified file name
# @param  string: filename
# @param  ref array:  float/int
# @param  ref array:  float/int
#
sub outputScatter {
  my $filename = $_[1];
  my @arr1 = @{$_[2]};
  my @arr2 = @{$_[3]};
  open FP, ">$filename";
  my $i = 0;
  foreach my $e (@arr1) {
    if ($e > 0 and $arr2[$i] > 0) {
      print FP $e . "\t" . $arr2[$i] . "\n";
    }
    $i++;
  }
  close FP;
}

# Output intermediary files (domain, time) for post processing
# @param  string: filename
# @param  ref hash:  float/int
#
sub outputIntermediaries {
  my $filename = $_[1];
  my %h = %{$_[2]};
  open FP, ">$filename";
  foreach $domain (keys %h) {
    #$domain =~ s/www\.//g;
    print FP $domain . "\t" . $h{$domain} . "\n";
  }
  close FP;
}

1;
