#!/usr/bin/perl

#use ProcessAdapter;
use JSON;
use UtilPlot;

##########################################
# Check arguments
##########################################
$argc = @ARGV;

$f1 = "eval_perf_on_4";
$f2 = "eval_perf_off_4";

%h1 = ();
open FP, $f1;
while ($line = <FP>) {
  @a = split(/\n/, $line);
  @a = split(/\t/, $a[0]);
  $url = $a[0];
  $time = $a[1];
  $h1{$url} = $time;
}
close FP;

%h2 = ();
open FP, $f2;
while ($line = <FP>) {
  @a = split(/\n/, $line);
  @a = split(/\t/, $a[0]);
  $url = $a[0];
  $time = $a[1];
  $h2{$url} = $time;
}
close FP;

@arr_on = ();
@arr_off = ();
@arr_frac = ();
foreach $key (keys %h1) {
  if ($h1{$key} > 0 and $h2{$key} > 0) {
    push(@arr_on, $h1{$key} / 1000);
    push(@arr_off, $h2{$key} / 1000);
    push(@arr_frac, $h1{$key} / $h2{$key});
    print $key . "\t" . $h1{$key} . "\t" . $h2{$key} . "\n";
  }
}

UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . "results/eval_on_2", \@arr_on);
UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . "results/eval_off_2", \@arr_off);
UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . "results/eval_frac_2", \@arr_frac);
