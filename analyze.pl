
#!/usr/bin/perl

#use ProcessAdapter;
use JSON;
use ProcessMain;

$num_experiments = 5;

##########################################
# Check arguments
##########################################
$argc = @ARGV;

if ($argc < 0) {
  print "Usage: " . $0 . " [min | max | median | 0.1 | 0.9]\n";
  exit 0;
}
$type = $ARGV[0];


$adapter = new ProcessMain($type);
$adapter->run();
