#!/usr/bin/perl

use UtilPlot;

##########################################
# Check arguments
##########################################
$argc = @ARGV;

if ($argc < 1) {
  print "Usage: " . $0 . " [filepath]\n";
  exit 0;
}
$file = $ARGV[0];

my %h = ();

open FP, $file;
while ($line = <FP>) {
  @a = split(/\n/, $line);
  @a = split(/ /, $a[0]);
  $n = @a;
  if ($n < 2) {
    next;
  }

  $path = $a[0];
  $size = $a[1] + 0;

  @a = split(/\-/, $path);
  $domain = $a[0];
  $ts = $a[1];
  $times = $a[2] + 0;

  $h{$domain}{$ts}{$times} = $size;
}
close FP;

@size;
$sum = 0;
$n = 0;
foreach $domain (keys %h) {
  %h1 = %{$h{$domain}};

  $s = 0;
  $t = 0;
  foreach $ts (keys %h1) {
    %h2 = %{$h1{$ts}};
    if (!$h2{2} or $h2{3}) {
      next;
    }
    $t++;
    $s += $h2{1};
  }
  if ($t > 0) {
    push(@size, $s / $t / 1024);
    $n++;
    $sum += $s / $t / 1024;
  }
}

$mean = $sum / $n;
print "mean:\t" . $mean . "\n";
UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . "results/eval_filesize", \@size);
