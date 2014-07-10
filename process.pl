use POSIX;

$gr = 1;

my @raw;

open FP, "plt_163";
while ($line = <FP>) {
  $a = $line + 0.0;
  $a = floor($a / $gr) * $gr;
  if ($a == 0) {
    next;
  }
  push(@raw, $a);
}
close FP;

@raw = sort {$a <=> $b} @raw;
$n = @raw;

print "min: " . $raw[0];

print "median: " . $raw[$n/2];

foreach $a (@raw) {
  print $a . "\n";
}
