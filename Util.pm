#!/usr/bin/perl

package Util;

# Convert time format in HAR to seconds
# @param  string: filename
# @param  ref array:  float/int
# @return float/int: median value
#
sub convertTime {
  my $filename = $_[0];
  my $str = $_[1];
  my @arr = split(/\-/, $str);
  @arr = split(/\:/, $arr[2]);
  return ($arr[1] + 0) * 60 + $arr[2] + 0;
}

# Calculae MimeType
# @param  reference of hash table that uses mime types as keys and
#         cumulate values
# @return hash table that uses our defined types as keys and cumulate values
#
sub calculateMimeType {
  my $filename = $_[0];
  my %mimetype_num = %{$_[0]};
  my %mimetype = ();
  foreach my $key (keys %mimetype_num) {
    if ($key =~ /javascript/) {
      if (exists $mimetype{"js"}) {
        $mimetype{"js"} += $mimetype_num{$key};
      } else {
        $mimetype{"js"} = $mimetype_num{$key};
      }
    } elsif ($key =~ /image/) {
      if (exists $mimetype{"img"}) {
        $mimetype{"img"} += $mimetype_num{$key};
      } else {
        $mimetype{"img"} = $mimetype_num{$key};
      }
    } elsif ($key =~ /xml/) {
      if (exists $mimetype{"xml"}) {
        $mimetype{"xml"} += $mimetype_num{$key};
      } else {
        $mimetype{"xml"} = $mimetype_num{$key};
      }
    } elsif ($key =~ /html/) {
      if (exists $mimetype{"html"}) {
        $mimetype{"html"} += $mimetype_num{$key};
      } else {
        $mimetype{"html"} = $mimetype_num{$key};
      }
    } elsif ($key =~ /css/) {
      if (exists $mimetype{"css"}) {
        $mimetype{"css"} += $mimetype_num{$key};
      } else {
        $mimetype{"css"} = $mimetype_num{$key};
      }
    } elsif ($key =~ /flash/) {
      if (exists $mimetype{"flash"}) {
        $mimetype{"flash"} += $mimetype_num{$key};
      } else {
        $mimetype{"flash"} = $mimetype_num{$key};
      }
    } elsif ($key =~ /text/) {
      if (exists $mimetype{"text"}) {
        $mimetype{"text"} += $mimetype_num{$key};
      } else {
        $mimetype{"text"} = $mimetype_num{$key};
      }
    } else {
      if (exists $mimetype{"other"}) {
        $mimetype{"other"} += $mimetype_num{$key};
      } else {
        $mimetype{"other"} = $mimetype_num{$key};
      }
      print $key . "\t" . $mimetype_num{$key} . "\n";
    }
  }
  return %mimetype;
}

1;
