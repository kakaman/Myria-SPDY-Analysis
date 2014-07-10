#!/usr/bin/perl

package UtilMath;

# Calculae num of keys in a hash table
# @param  reference of hash table
# @return int: num of keys
#
sub calculateNum {
  my ($class) = @_;
  my %hash = %{$_[0]};
  my $ii = 0;
  foreach my $key (keys %hash) {
    $ii++;
  }
  return $ii;
}

# Calculae n-th percentile value in a hash table
# @param  reference of hash table
# @param  float: n-th percentile of return value
# @return int/float: n-th percentile value
#
sub calculatePerc {
  my ($class) = @_;
  my %hash = %{$_[0]};
  my $perc = $_[1] + 0;
  my $ii = 0;
  my @arr = [];
  foreach my $key (keys %hash) {
    $arr[$ii] = $hash{$key};
    $ii++;
  }
  @arr = sort {$a <=> $b} @arr;

  return $arr[int(($ii - 1) * $perc)];
}

# Calculae the maximum value in a hash table
# @param  reference of hash table
# @return int/float: maximum value
#
sub calculateMAX {
  my ($class) = @_;
  my %hash = %{$_[0]};
  my $ii = 0;
  my $max = 0;
  foreach my $key (keys %hash) {
    if ($hash{$key} > $max) {
      $max = $hash{$key};
    }
  }

  return $max;
}

# Calculae the average value in a hash table
# @param  reference of hash table
# @return int/float: average value
#
sub calculateAVG {
  my ($class) = @_;

  my @hash = @{$_[0]};
  my $ii = 0;
  my $sum = 0;
  foreach my $key (@hash) {
    print $key . "\n";
    $sum += $key;
    $ii++;
  }

  if ($ii == 0) {
    return 0;
  }

  return $sum / $ii;
}

# Calculae the standard deviation of values in a hash table
# @param  reference of hash table
# @return int/float: standard deviation
#
sub calculateSTD {
  my ($class) = @_;
  my @hash = @{$_[0]};
  my $avg = UtilMath->calculateAVG(\@hash);

  my $sd = 0;
  my $ii = 0;
  foreach my $key (@hash) {
    $sd += ($key - $avg) * ($key - $avg);
    $ii++;
  }

  if ($ii == 0) {
    return 0;
  }

  return sqrt($sd / $ii);
}

1;
