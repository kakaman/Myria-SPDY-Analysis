
my %h1 = ();
my %h2 = ();

open FP, "ttt";
while ($line = <FP>) {
  @a = split(/\n/, $line);
  @a = split(/\t/, $a[0]);
  @b = split(/\-/, $a[0]);
  $ts = $b[1] + 0.0;
  $value = $b[0] . "\t" . $a[1] . "\t" . $a[2];
  if ($b[2] eq "1") {
    $h1{$ts} = $value;
  }
  if ($b[2] eq "2") {
    $h2{$ts} = $value;
  }
}
close FP;

$prevs = -1;
$preve = -1;
$preva = "";
$n = 0;
for my $key ( sort {$a <=> $b} keys %h1) {
  @b = split(/\t/, $h1{$key});
  if ($b[1] + 0.0 <= $preve and $b[1] + 0.0 > $prevs and $prevs > 0) {
    print $preva . "\n";
    print $key . "\t" . $h1{$key} . "\n\n";
    ++$n;
  }
  $prevs = $b[1] + 0.0;
  $preve = $b[2] + 0.0;
  $preva = $key . "\t" . $h1{$key};
}
print "total: $n\n";

$prevs = -1;
$preve = -1;
$preva = "";
$n = 0;
for my $key ( sort {$a <=> $b} keys %h2) {
  @b = split(/\t/, $h2{$key});
  if ($b[1] + 0.0 <= $preve and $b[1] + 0.0 > $prevs and $prevs > 0) {
    print $preva . "\n";
    print $key . "\t" . $h2{$key} . "\n\n";
    ++$n;
  }
  $prevs = $b[1] + 0.0;
  $preve = $b[2] + 0.0;
  $preva = $h2{$key};
}
print "total: $n\n";
