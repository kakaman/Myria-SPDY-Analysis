#!/usr/bin/perl
# ------------------------------------------------------
# The adapter that processes all the high-level results
#
# 1) It processes all the specified files to calculate
#    intermediaries that can be used later.
#    Each line in the intermediaries is like key -> value
#    The first element is domain, the second is value
#
# 2) It calculates high-level rsults from intermediaries
#    and output data that can be processed by gnuplot
# ------------------------------------------------------

package ProcessMain;

use JSON;
use RawParser;
use UtilConfig;
use UtilPlot;
use UtilMath;

sub new {
  my $class = shift;

  my $config = UtilConfig->getInstance()->getConfig();

  my $paths = {
    #"mwprof_mobile_1run_pro",
    #"mwprof_mobile_1run_pro",
    #"mwprof_wifi_200_5runs_pro",
    #"mwprof_nonmobile_wifi_200_5runs_pro",
    #"extensive_cold_warm_5runs_imac_pro",
    "wprof_300_5_pro",
    #"test",
    #"wprof_20ms_10IW_10Mbps_0plr_spdy_pro",
    #"wprof_20ms_10IW_10Mbps_0plr_mps_on_pro",
    #"wprof_20ms_10IW_10Mbps_0plr_mps_random_off_pro",
    #"wprof_20ms_10IW_10Mbps_0plr_mps_random_on_pro",
    # TODO add data path
  };

  my $self = {
    _config => $config,
    _paths => $paths,
    _type => $_[0],
  };
  bless $self, $class;

  #$self->run();

  return $self;
}

sub run {
  my ($self, $paths, $config) = @_;

  # generate intermediaries
  $self->generateIntermediaries();

  # process intermediaries
  $self->processIntermediaries();

  # process intermediaries
  $self->outputIntermediaries();
}

sub outputIntermediaries {
  my ($self, $path1, $config) = @_;

  $resultPath = $self->{_config}->{"ResultPath"};
  print `rm -rf $resultPath/*`;

  # all
  my @types = (
    #"mwprof_mobile_1run_pro",
    #"mwprof_wifi_200_5runs_pro",
    #"mwprof_nonmobile_wifi_200_5runs_pro",
    #"extensive_cold_warm_5runs_imac_pro",
    "wprof_300_5_pro",
    #"test",
    #"wprof_20ms_10IW_10Mbps_0plr_spdy_pro",
    #"wprof_20ms_10IW_10Mbps_0plr_mps_on_pro",
    #"wprof_20ms_10IW_10Mbps_0plr_mps_random_off_pro",
    #"wprof_20ms_10IW_10Mbps_0plr_mps_random_on_pro",
    # TODO add data path
  );
  foreach $type (@types) {
    if ($self->{_paths}->{$type} eq "two") {
      #$self->processAll($type);
      $self->processAll($type . "_1");
      $self->processAll($type . "_2");
    } else {
      $self->processAll($type);
    }
  }

  # overall
  %types = (
    #"extensive_200pages_controlled_5run_blockdns_pro" , ["extensive_200pages_controlled_5run_2_pro"],
    #"extensive_200pages_cold_hot_5run_pro_1", ["extensive_200pages_cold_hot_5run_pro_2"],
    #"extensive_200pages_cold_warm_5run_pro_1", ["extensive_200pages_cold_warm_5run_pro_1_2"],
    #"extensive_200pages_cold_warm_5run_1_pro_1", ["extensive_200pages_cold_warm_5run_1_pro_1_2"],
    #"extensive_200pages_cold_warm_3run_2_pro_1", ["extensive_200pages_cold_warm_3run_2_pro_2"],
  );
  #my $control_type = "preliminary_200pages_controlled_1run_pro_10";
  #my @types = ("preliminary_200pages_spdy_1run_pro_10");
  foreach $key (keys %types) {
    @values = @{$types{$key}};
    foreach $value (@values) {
      #print $key . "\t" . $value . "\n";
      $self->processOverall($value, $key);
    }
  }
}

sub generateIntermediaries {
  my ($self, $paths, $config) = @_; # Uses self, paths, config
  %paths = %{$self->{_paths}}; # Sets paths equal to the paths var in the self object

  foreach $path (keys %paths) { # for each path  that is a key in paths set value
    $value = $paths{$path};

      # clear files in temp path
      my $temp_path = $self->{_config}->{"TempPath"}; # set temkp path
      $temp_path .= $path;
      print `mkdir $temp_path`;
      print `rm -rf $temp_path/*`;

      print `rm -rf dep_logs/`;
      print `mkdir dep_logs/`;

      print `rm -rf graphs/`;
      print `mkdir graphs/`;

      my $data_path = $self->{_config}->{"DataPath"}; # sets data path
      $data_path .= $path;
      $ps = `ls $data_path`;
      #print $ps . "\n";
      @files = split(/\n/, $ps); # splits based on line

if (1) {
      # find out the min
      my %files1 = ();
      my %files2 = ();
      my %loads1 = ();
      my %loads2 = ();
      foreach $file (@files) {
        if ($value eq "ultralisk" and $file !~ "ultralisk") { # when ultralisk == val & != file
          next;
        }
        $f = $data_path . "/" . $file; # concatonates data_path and file together
        print "\n" . $f . "\n";
        $rp = new RawParser($file, $data_path, $temp_path, $value, 0); # Calls on the new function in RawParser
        $url = $rp->getPageUrl(); # sets url

        #$url = $file; # all

        @a = split(/\-/, $file); # set a = separate - from file 
        $n = $a[2]; # set n
        if ($url) {
          if (($value ne "two" or $n eq "1")) {
            $loads1{$url}{$rp->getLoad()} = $file; # sets load1
          }
          if ($n eq "2"  and $rp->getLoad() > $loads2{$url}) {
            $loads2{$url}{$rp->getLoad()} = $file; # sets load 2
          }
        }
      }

      # calculate the corresponding file based on $type
      foreach $url (keys %loads1) { # for each url which is a key in loads
        my %temp = %{$loads1{$url}};
        @temp_keys = sort { $a <=> $b } keys %temp; # sort a,b numerically into temp_keys
        my $type = $self->{_type};
        my $k = 0;
        my $count = @temp_keys;
        if ($type eq "min") { # if min set k = first element in temp_keys
          $k = $temp_keys[0];
        } elsif ($type eq "max") { 
          $k = $temp_keys[$count - 1]; # set k to last element
        } elsif ($type eq "median") { 
          $k = $temp_keys[$count / 2]; # set k to middle element
        } else {
          my $perc = $type + 0.0; # set perc to type + 0.0
          $k = $temp_keys[$count * $perc]; # set k to key in count * perc
        }
        $files1{$url} = $loads1{$url}{$k}; # set file url to loads1 url of k
      }
if (0) { # hot
      foreach $url (keys %loads2) {
        my %temp = %{$loads2{$url}};
        @temp_keys = sort { $a <=> $b } keys %temp;
        my $type = $self->{_type};
        my $k = 0;
        my $count = @temp_keys;
        if ($type eq "min") {
          $k = $temp_keys[0];
        } elsif ($type eq "max") {
          $k = $temp_keys[$count - 1];
        } elsif ($type eq "median") {
          $k = $temp_keys[$count / 2];
        } else {
          my $perc = $type + 0.0;
          $k = $temp_keys[$count * $perc];
        }
        $files2{$url} = $loads2{$url}{$k};
      }
}

      #do real analysis on 
      #cold
      foreach $url (keys %files1) {
        $file = $files1{$url};

        if ($value eq "ultralisk" and $file !~ "ultralisk") {
          next;
        }
        $f = $data_path . "/" . $file;
        print "$file\t$date_path\t$value\n\n";
        $rp = new RawParser($file, $data_path, $temp_path, $value, 1);
        $url = $rp->getPageUrl();
      }
      #hot
if (0) {
      foreach $url (keys %files2) {
        $file = $files2{$url};
        if ($value eq "ultralisk" and $file !~ "ultralisk") {
          next;
        }
        $f = $data_path . "/" . $file;
        print "\n" . $f . "\n";
        $rp = new RawParser($file, $data_path, $temp_path, $value, 1);
        $url = $rp->getPageUrl();
      }
}
}
  }
}

sub processIntermediaries {
  my ($self, $path1, $config) = @_;

  # init hashes
  my %h;

  # read from files
  my $temp_path = $self->{_config}->{"TempPath"};
  %paths = %{$self->{_paths}};

  foreach $path (keys %paths) {

  $value = $paths{$path};
  print $path . "\t" . $value . "\n";

  $ps = `ls $temp_path/$path`;
  @files = split(/\n/, $ps);

  my %h = ();
  my @h_arr = ();
  foreach $file (@files) {
    @elem = split(/\-/, $file);

    # get the domain
    $domain = $elem[0];

    $domain = $file; # for the same site

    if ($value eq "two") {
      $domain_time = $elem[0] . "-" . $elem[1]; # all
      $timestamp = $elem[1]; # all
      $runs = $elem[2] + 0.0;
    }

    # get timestamp
    $ts = $elem[1];

    $f = $temp_path . $path . "/". $file;
    open FP, $f;
    my %e;
    my $i = 0;
    while (<FP>) {
      $line = $_;

      @t = split(/\n/, $line);
      @t = split(/\t/, $t[0]);

      if ($i == 0) {
        #print $t[0] . " " . $t[1] . "\n";
        $e{"DOMLoad"} = $t[1];
        ++$i;
      }

      if ($t[0] eq "TTFB:") {
        $e{"TTFB"} = $t[1];
      } elsif ($t[0] eq "Parse:") {
        $e{"Parse"} = $t[1];
      } elsif ($t[0] eq "PostParse:") {
        $e{"PostParse"} = $t[1];

      # new
      } elsif ($t[0] eq "whatif_matrix:") {
        $e{"whatif_matrix"} = $t[1];
      } elsif ($t[0] eq "level:") {
        $e{"level"} = $t[1];
      } elsif ($t[0] eq "load:") {
        #$e{"DOMload"} = $t[1];
      } elsif ($t[0] eq "HTMLParse:") {
        $e{"HTMLParse"} = $t[1];
      } elsif ($t[0] eq "time_comp:") {
        $e{"time_comp"} = $t[1];
      } elsif ($t[0] eq "time_block:") {
        $e{"time_block"} = $t[1];
      } elsif ($t[0] eq "time_download:") {
        $e{"time_download"} = $t[1];
      } elsif ($t[0] eq "download_blocking:") {
        $e{"download_blocking"} = $t[1];
      } elsif ($t[0] eq "download_proxy:") {
        $e{"download_proxy"} = $t[1];
      } elsif ($t[0] eq "download_dns:") {
        $e{"download_dns"} = $t[1];
      } elsif ($t[0] eq "download_conn:") {
        $e{"download_conn"} = $t[1];
      } elsif ($t[0] eq "download_ssl:") {
        $e{"download_ssl"} = $t[1];
      } elsif ($t[0] eq "download_send:") {
        $e{"download_send"} = $t[1];
      } elsif ($t[0] eq "download_receiveFirst:") {
        $e{"download_receiveFirst"} = $t[1];
      } elsif ($t[0] eq "download_receiveLast:") {
        $e{"download_receiveLast"} = $t[1];
      } elsif ($t[0] eq "parse_style:") {
        $e{"parse_style"} = $t[1];
      } elsif ($t[0] eq "parse_script:") {
        $e{"parse_script"} = $t[1];
      } elsif ($t[0] eq "parse_layout:") {
        $e{"parse_layout"} = $t[1];
      } elsif ($t[0] eq "parse_paint:") {
        $e{"parse_paint"} = $t[1];
      } elsif ($t[0] eq "parse_other:") {
        $e{"parse_other"} = $t[1];
      } elsif ($t[0] eq "parse_undefined:") {
        $e{"parse_undefined"} = $t[1];
      } elsif ($t[0] eq "dep_D2E:") {
        $e{"dep_D2E"} = $t[1];
      } elsif ($t[0] eq "dep_E2D_html:") {
        $e{"dep_E2D_html"} = $t[1];
      } elsif ($t[0] eq "dep_E2D_css:") {
        $e{"dep_E2D_css"} = $t[1];
      } elsif ($t[0] eq "dep_E2D_js:") {
        $e{"dep_E2D_js"} = $t[1];
      } elsif ($t[0] eq "dep_E2D_timer:") {
        $e{"dep_E2D_timer"} = $t[1];
      } elsif ($t[0] eq "dep_RFB:") {
        $e{"dep_RFB"} = $t[1];
      } elsif ($t[0] eq "dep_HOL_css:") {
        $e{"dep_HOL_css"} = $t[1];
      } elsif ($t[0] eq "dep_HOL_js:") {
        $e{"dep_HOL_js"} = $t[1];


      } elsif ($t[0] eq "time_download_html:") {
        $e{"time_download_html"} = $t[1];
      } elsif ($t[0] eq "time_download_css:") {
        $e{"time_download_css"} = $t[1];
      } elsif ($t[0] eq "time_download_js:") {
        $e{"time_download_js"} = $t[1];
      } elsif ($t[0] eq "time_download_img:") {
        $e{"time_download_img"} = $t[1];
      } elsif ($t[0] eq "time_download_o:") {
        $e{"time_download_o"} = $t[1];
      } elsif ($t[0] eq "time_block_css:") {
        $e{"time_block_css"} = $t[1];
      } elsif ($t[0] eq "time_block_js:") {
        $e{"time_block_js"} = $t[1];
      } elsif ($t[0] eq "time_ttfb:") {
        $e{"time_ttfb"} = $t[1];
      } elsif ($t[0] eq "num_domains_cp:") {
        $e{"num_domains_cp"} = $t[1];
      } elsif ($t[0] eq "num_domains_all:") {
        $e{"num_domains_all"} = $t[1];
      } elsif ($t[0] eq "text_domains_cp:") {
        $e{"text_domains_cp"} = $t[1];
      } elsif ($t[0] eq "text_domains_all:") {
        $e{"text_domains_all"} = $t[1];
      } elsif ($t[0] eq "num_bytes_cp:") {
        $e{"num_bytes_cp"} = $t[1];
      } elsif ($t[0] eq "num_bytes_all:") {
        $e{"num_bytes_all"} = $t[1];
      } elsif ($t[0] eq "num_send_cp:") {
        $e{"num_send_cp"} = $t[1];
      } elsif ($t[0] eq "num_send_all:") {
        $e{"num_send_all"} = $t[1];
      } elsif ($t[0] eq "num_conn_cp:") {
        $e{"num_conn_cp"} = $t[1];
      } elsif ($t[0] eq "num_conn_all:") {
        $e{"num_conn_all"} = $t[1];
      } elsif ($t[0] eq "num_objs_cp:") {
        $e{"num_objs_cp"} = $t[1];
      } elsif ($t[0] eq "num_objs_all:") {
        $e{"num_objs_all"} = $t[1];
      } elsif ($t[0] eq "num_bytes_cp:") {
        $e{"num_bytes_cp"} = $t[1];
      } elsif ($t[0] eq "num_bytes_all:") {
        $e{"num_bytes_all"} = $t[1];
      } elsif ($t[0] eq "text_domain_tcp_net_cp:") {
        $e{"text_domain_tcp_net_cp"} = $t[1];
      } elsif ($t[0] eq "text_domain_tcp_net_all:") {
        $e{"text_domain_tcp_net_all"} = $t[1];
      } elsif ($t[0] eq "act_timings:") {
        $e{"act_timings"} = $t[1];
      }
    }
    #print encode_json(\%e) . "\n\n";
    if ($value eq "two") {
      #print $domain . "\t" . $timestamp . "\t" . $runs . "\t" . $h{$domain}{$timestamp}{$runs}{"text_domains_cp"} . "\n";
      #print $domain . "\n";
      @a = split(/\_/, $domain);
      $n = @a;
      if ($n > 2) {
        next;
      }
      $h{$domain}{$runs} = \%e;
    } else {
      if (!$h{$domain}) {
        $h{$domain} = \%e;
      } else {
        %s = %{$h{$domain}};
        if ($e{"time_download"} + $e{"time_block"} + $e{"time_comp"} < $s{"time_download"} + $s{"time_block"} + $s{"time_comp"}) {
          $h{$domain} = \%e;
        }
      }
    }
    close FP;
  } 

  # sanitize if "two"
  if ($value eq "two") {
    my %h1;
    my %h2;
    foreach $domain (keys %h) {
      my %data = %{$h{$domain}};
      my $temp1 = undef;
      my $temp2 = undef;

        #print $domain . "\n";
        #print encode_json(\%data1) . "\n";
        # do not consider only with one data
      #if (!$data{1} or !$data{2} or $data{3}) {
      if (!$data{1}) {
        next;
      }

      $h1{$domain} = encode_json($data{1});
      #$h2{$domain} = encode_json($data{2});

      #print $domain . "\t" . $temp1{"time_download"} . "\t" . $temp2{"time_download"} . "\n";
    }
    push(@h_arr, \%h1);
    #push(@h_arr, \%h2);
  } else {
    push(@h_arr, \%h);
  }

  # output
  my $i = 0;
  my $num = @h_arr;
  foreach $h (@h_arr) {
    %h = %{$h};
    #print encode_json(\%h) . "\n\n";
    ++$i;
    $pathi = $path . "_" . $i;
    if ($num > 1) {
      $pathi = "$path\_$i";
    } else {
      $pathi = $path;
    }
    print $pathi . "\t" . $path . "\t" . $i . "\n";

  my %levels = ();
  my %whatif_matrix = ();
  my %DOMLoad = ();
  my %HTMLParse = ();
  my %time_blocks = ();
  my %time_downloads = ();
  my %time_comps = ();
  my %downloads_blocking = ();
  my %downloads_proxy = ();
  my %downloads_dns = ();
  my %downloads_conn = ();
  my %downloads_ssl = ();
  my %downloads_send = ();
  my %downloads_receiveFirst = ();
  my %downloads_receiveLast = ();
  my %parses_style = ();
  my %parses_script = ();
  my %parses_layout = ();
  my %parses_paint = ();
  my %parses_other = ();
  my %parses_undefined = ();

  my %frac_time_blocks = ();
  my %frac_time_downloads = ();
  my %frac_time_comps = ();
  my %frac_downloads_blocking = ();
  my %frac_downloads_proxy = ();
  my %frac_downloads_dns = ();
  my %frac_downloads_conn = ();
  my %frac_downloads_ssl = ();
  my %frac_downloads_send = ();
  my %frac_downloads_receiveFirst = ();
  my %frac_downloads_receiveLast = ();
  my %frac_parses_style = ();
  my %frac_parses_script = ();
  my %frac_parses_layout = ();
  my %frac_parses_paint = ();
  my %frac_parses_other = ();
  my %frac_parses_undefined = ();
  my %frac_time_downloads_html = ();
  my %frac_time_downloads_css = ();
  my %frac_time_downloads_js = ();
  my %frac_time_downloads_img = ();
  my %frac_time_downloads_o = ();
  my %frac_time_blocks_css = ();
  my %frac_time_blocks_js = ();
  my %frac_time_ttfb = ();

  my %dep_D2E = ();
  my %dep_E2D_html = ();
  my %dep_E2D_css = ();
  my %dep_E2D_js = ();
  my %dep_E2D_timer = ();
  my %dep_RFB = ();
  my %dep_HOL_css = ();
  my %dep_HOL_js = ();
  my %num_domains_cp = ();
  my %num_domains_all = ();
  my %text_domains_cp = ();
  my %text_domains_all = ();
  my %num_bytes_cp = ();
  my %num_bytes_all = ();
  my %num_send_cp = ();
  my %num_send_all = ();
  my %num_conn_cp = ();
  my %num_conn_all = ();
  my %num_objs_cp = ();
  my %num_objs_all = ();
  my %num_bytes_cp = ();
  my %num_bytes_all = ();
  my %text_domain_tcp_net_cp = ();
  my %text_domain_tcp_net_all = ();
  my %act_timings = ();

  foreach $domain (%h) {
    if (!$h{$domain}) {
      next;
    }
    if ($value eq "two") {
      %info = %{decode_json($h{$domain})};
    } else {
      %info = %{$h{$domain}};
    }
    if ($info{"TTFB"}) {
      $str .= $domain . "\t" . $info{"TTFB"} . "\t" . $info{"Parse"} . "\t" . $info{"PostParse"} . "\n";

    $total = $info{"time_download"} + $info{"time_comp"} + $info{"time_block"};
    #print $total . "\t" . $total . "\n";
    #print $domain . " " . $info{"time_download"} . " " . $info{"time_comp"} . " " . $info{"time_block"} . "\n";
    $frac_download = $info{"time_download"} / $total;
    $frac_block = $info{"time_block"} / $total;
    $frac_comp = $info{"time_comp"} / $total;

    $frac_download_blocking = $info{"download_blocking"} / $total;
    $frac_download_proxy = $info{"download_proxy"} / $total;
    $frac_download_dns = $info{"download_dns"} / $total;
    $frac_download_conn = $info{"download_conn"} / $total;
    $frac_download_ssl = $info{"download_ssl"} / $total;
    $frac_download_send = $info{"download_send"} / $total;
    $frac_download_receiveFirst = $info{"download_receiveFirst"} / $total;
    $frac_download_receiveLast = $info{"download_receiveLast"} / $total;
    $frac_parse_style = $info{"parse_style"} / $total;
    $frac_parse_script = $info{"parse_script"} / $total;
    $frac_parse_layout = $info{"parse_layout"} / $total;
    $frac_parse_paint = $info{"parse_paint"} / $total;
    $frac_parse_other = $info{"parse_other"} / $total;
    $frac_parse_undefined = $info{"parse_undefined"} / $total;

    $frac_time_download_html = $info{"time_download_html"} / $total;
    $frac_time_download_css = $info{"time_download_css"} / $total;
    $frac_time_download_js = $info{"time_download_js"} / $total;
    $frac_time_download_img = $info{"time_download_img"} / $total;
    $frac_time_download_o = $info{"time_download_o"} / $total;
    $frac_time_block_css = $info{"time_block_css"} / $total;
    $frac_time_block_js = $info{"time_block_js"} / $total;
    $frac_time_ttfb = $info{"time_ttfb"} / $total;

    $levels{$domain} = $info{"level"};
    $whatif_matrix{$domain} = $info{"whatif_matrix"};
    $DOMLoad{$domain} = $info{"DOMLoad"};
    $HTMLParse{$domain} = $info{"HTMLParse"};
    $time_downloads{$domain} = $info{"time_download"};
    $time_blocks{$domain} = $info{"time_block"};
    $time_comps{$domain} = $info{"time_comp"};
    $downloads_blocking{$domain} = $info{"download_blocking"};
    $downloads_proxy{$domain} = $info{"download_proxy"};
    $downloads_dns{$domain} = $info{"download_dns"};
    $downloads_conn{$domain} = $info{"download_conn"};
    $downloads_ssl{$domain} = $info{"download_ssl"};
    $downloads_send{$domain} = $info{"download_send"};
    $downloads_receiveFirst{$domain} = $info{"download_receiveFirst"};
    $downloads_receiveLast{$domain} = $info{"download_receiveLast"};
    $parses_style{$domain} = $info{"parse_style"};
    $parses_script{$domain} = $info{"parse_script"};
    $parses_layout{$domain} = $info{"parse_layout"};
    $parses_paint{$domain} = $info{"parse_paint"};
    $parses_other{$domain} = $info{"parse_other"};
    $parses_undefined{$domain} = $info{"parse_undefined"};

    $frac_time_downloads{$domain} = $frac_download;
    $frac_time_blocks{$domain} = $frac_block;
    $frac_time_comps{$domain} = $frac_comp;
    $frac_downloads_blocking{$domain} = $frac_download_blocking;
    $frac_downloads_proxy{$domain} = $frac_download_proxy;
    $frac_downloads_dns{$domain} = $frac_download_dns;
    $frac_downloads_conn{$domain} = $frac_download_conn;
    $frac_downloads_ssl{$domain} = $frac_download_ssl;
    $frac_downloads_send{$domain} = $frac_download_send;
    $frac_downloads_receiveFirst{$domain} = $frac_download_receiveFirst;
    $frac_downloads_receiveLast{$domain} = $frac_download_receiveLast;
    $frac_parses_style{$domain} = $frac_parse_style;
    $frac_parses_script{$domain} = $frac_parse_script;
    $frac_parses_layout{$domain} = $frac_parse_layout;
    $frac_parses_paint{$domain} = $frac_parse_paint;
    $frac_parses_other{$domain} = $frac_parse_other;
    $frac_parses_undefined{$domain} = $frac_parse_undefined;
    $frac_time_downloads_html{$domain} = $frac_time_download_html;
    $frac_time_downloads_css{$domain} = $frac_time_download_css;
    $frac_time_downloads_js{$domain} = $frac_time_download_js;
    $frac_time_downloads_img{$domain} = $frac_time_download_img;
    $frac_time_downloads_o{$domain} = $frac_time_download_o;
    $frac_time_blocks_css{$domain} = $frac_time_block_css;
    $frac_time_blocks_js{$domain} = $frac_time_block_js;
    $frac_time_ttfb{$domain} = $frac_time_ttfb;

    $dep_D2E{$domain} = $info{"dep_D2E"};
    $dep_E2D_html{$domain} = $info{"dep_E2D_html"};
    $dep_E2D_css{$domain} = $info{"dep_E2D_css"};
    $dep_E2D_js{$domain} = $info{"dep_E2D_js"};
    $dep_E2D_timer{$domain} = $info{"dep_E2D_timer"};
    $dep_E2D_RFB{$domain} = $info{"dep_E2D_RFB"};
    $dep_HOL_css{$domain} = $info{"dep_HOL_css"};
    $dep_HOL_js{$domain} = $info{"dep_HOL_js"};
    $num_domains_cp{$domain} = $info{"num_domains_cp"};
    $num_domains_all{$domain} = $info{"num_domains_all"};
    $text_domains_cp{$domain} = $info{"text_domains_cp"};
    $text_domains_all{$domain} = $info{"text_domains_all"};
    $num_objs_cp{$domain} = $info{"num_objs_cp"};
    $num_objs_all{$domain} = $info{"num_objs_all"};
    $num_bytes_cp{$domain} = $info{"num_bytes_cp"};
    $num_bytes_all{$domain} = $info{"num_bytes_all"};
    $num_send_cp{$domain} = $info{"num_send_cp"};
    $num_send_all{$domain} = $info{"num_send_all"};
    $num_conn_cp{$domain} = $info{"num_conn_cp"};
    $num_conn_all{$domain} = $info{"num_conn_all"};
    $act_timings{$domain} = $info{"act_timings"};
    }
  }

  #$ot = $result_path . $pathi . "_";
  $ot = $temp_path . "temp/" . $pathi . "_";
  print "ot:  " . $ot . "\n";
  UtilPlot->outputIntermediaries($ot . "levels", \%levels);
  UtilPlot->outputIntermediaries($ot . "whatifMatrix", \%whatif_matrix);
  UtilPlot->outputIntermediaries($ot . "DOMLoad", \%DOMLoad);
  UtilPlot->outputIntermediaries($ot . "HTMLParse", \%HTMLParse);
  UtilPlot->outputIntermediaries($ot . "time_downloads", \%time_downloads);
  UtilPlot->outputIntermediaries($ot . "time_blocks", \%time_blocks);
  UtilPlot->outputIntermediaries($ot . "time_comps", \%time_comps);
  UtilPlot->outputIntermediaries($ot . "downloads_blocking", \%downloads_blocking);
  UtilPlot->outputIntermediaries($ot . "downloads_proxy", \%downloads_proxy);
  UtilPlot->outputIntermediaries($ot . "downloads_dns", \%downloads_dns);
  UtilPlot->outputIntermediaries($ot . "downloads_conn", \%downloads_conn);
  UtilPlot->outputIntermediaries($ot . "downloads_ssl", \%downloads_ssl);
  UtilPlot->outputIntermediaries($ot . "downloads_send", \%downloads_send);
  UtilPlot->outputIntermediaries($ot . "downloads_receiveFirst", \%downloads_receiveFirst);
  UtilPlot->outputIntermediaries($ot . "downloads_receiveLast", \%downloads_receiveLast);
  UtilPlot->outputIntermediaries($ot . "parses_style", \%parses_style);
  UtilPlot->outputIntermediaries($ot . "parses_script", \%parses_script);
  UtilPlot->outputIntermediaries($ot . "parses_layout", \%parses_layout);
  UtilPlot->outputIntermediaries($ot . "parses_paint", \%parses_paint);
  UtilPlot->outputIntermediaries($ot . "parses_other", \%parses_other);
  UtilPlot->outputIntermediaries($ot . "parses_undefined", \%parses_undefined);
  UtilPlot->outputIntermediaries($ot . "frac_time_downloads", \%frac_time_downloads);
  UtilPlot->outputIntermediaries($ot . "frac_time_blocks", \%frac_time_blocks);
  UtilPlot->outputIntermediaries($ot . "frac_time_comps", \%frac_time_comps);
  UtilPlot->outputIntermediaries($ot . "frac_downloads_blocking", \%frac_downloads_blocking);
  UtilPlot->outputIntermediaries($ot . "frac_downloads_proxy", \%frac_downloads_proxy);
  UtilPlot->outputIntermediaries($ot . "frac_downloads_dns", \%frac_downloads_dns);
  UtilPlot->outputIntermediaries($ot . "frac_downloads_conn", \%frac_downloads_conn);
  UtilPlot->outputIntermediaries($ot . "frac_downloads_ssl", \%frac_downloads_ssl);
  UtilPlot->outputIntermediaries($ot . "frac_downloads_send", \%frac_downloads_send);
  UtilPlot->outputIntermediaries($ot . "frac_downloads_receiveFirst", \%frac_downloads_receiveFirst);
  UtilPlot->outputIntermediaries($ot . "frac_downloads_receiveLast", \%frac_downloads_receiveLast);
  UtilPlot->outputIntermediaries($ot . "frac_parses_style", \%frac_parses_style);
  UtilPlot->outputIntermediaries($ot . "frac_parses_script", \%frac_parses_script);
  UtilPlot->outputIntermediaries($ot . "frac_parses_layout", \%frac_parses_layout);
  UtilPlot->outputIntermediaries($ot . "frac_parses_paint", \%frac_parses_paint);
  UtilPlot->outputIntermediaries($ot . "frac_parses_other", \%frac_parses_other);
  UtilPlot->outputIntermediaries($ot . "frac_parses_undefined", \%frac_parses_undefined);
  UtilPlot->outputIntermediaries($ot . "frac_time_downloads_html", \%frac_time_downloads_html);
  UtilPlot->outputIntermediaries($ot . "frac_time_downloads_css", \%frac_time_downloads_css);
  UtilPlot->outputIntermediaries($ot . "frac_time_downloads_js", \%frac_time_downloads_js);
  UtilPlot->outputIntermediaries($ot . "frac_time_downloads_img", \%frac_time_downloads_img);
  UtilPlot->outputIntermediaries($ot . "frac_time_downloads_o", \%frac_time_downloads_o);
  UtilPlot->outputIntermediaries($ot . "frac_time_blocks_css", \%frac_time_blocks_css);
  UtilPlot->outputIntermediaries($ot . "frac_time_blocks_js", \%frac_time_blocks_js);
  UtilPlot->outputIntermediaries($ot . "frac_time_ttfb", \%frac_time_ttfb);
  UtilPlot->outputIntermediaries($ot . "dep_D2E", \%dep_D2E);
  UtilPlot->outputIntermediaries($ot . "dep_E2D_html", \%dep_E2D_html);
  UtilPlot->outputIntermediaries($ot . "dep_E2D_css", \%dep_E2D_css);
  UtilPlot->outputIntermediaries($ot . "dep_E2D_js", \%dep_E2D_js);
  UtilPlot->outputIntermediaries($ot . "dep_E2D_timer", \%dep_E2D_timer);
  UtilPlot->outputIntermediaries($ot . "dep_E2D_RFB", \%dep_E2D_RFB);
  UtilPlot->outputIntermediaries($ot . "dep_HOL_css", \%dep_HOL_css);
  UtilPlot->outputIntermediaries($ot . "dep_HOL_js", \%dep_HOL_js);
  UtilPlot->outputIntermediaries($ot . "num_domains_cp", \%num_domains_cp);
  UtilPlot->outputIntermediaries($ot . "num_domains_all", \%num_domains_all);
  UtilPlot->outputIntermediaries($ot . "text_domains_cp", \%text_domains_cp);
  UtilPlot->outputIntermediaries($ot . "text_domains_all", \%text_domains_all);
  UtilPlot->outputIntermediaries($ot . "num_objs_cp", \%num_objs_cp);
  UtilPlot->outputIntermediaries($ot . "num_objs_all", \%num_objs_all);
  UtilPlot->outputIntermediaries($ot . "num_bytes_cp", \%num_bytes_cp);
  UtilPlot->outputIntermediaries($ot . "num_bytes_all", \%num_bytes_all);
  UtilPlot->outputIntermediaries($ot . "num_send_cp", \%num_send_cp);
  UtilPlot->outputIntermediaries($ot . "num_send_all", \%num_send_all);
  UtilPlot->outputIntermediaries($ot . "num_conn_cp", \%num_conn_cp);
  UtilPlot->outputIntermediaries($ot . "num_conn_all", \%num_conn_all);
  UtilPlot->outputIntermediaries($ot . "act_timings", \%act_timings);
  }
  }
}

sub readIntermediaries {
  my ($self, $config) = @_;

  $filename = $self->{_config}->{"TempPath"} . "temp/" . $_[1];
  #print "filename: " . $filename . "\n";
  my %hash_ret = ();

  open FP, $filename;

  while (my $line = <FP>) {
    @arr = split(/\n/, $line);
    @arr = split(/\t/, $arr[0]);
    $hash_ret{$arr[0]} = $arr[1];
  }
  #print encode_json(\%hash_ret) . "\n\n";
  close FP;

  return \%hash_ret;
}

sub processAll {
  my ($self, $path1, $config) = @_;
  my $type = $_[1];
  print "type: " . $type . "\n";

  %levels = %{$self->readIntermediaries($type . "_levels")};
  %whatifMatrix = %{$self->readIntermediaries($type . "_whatifMatrix")};
  %DOMLoad = %{$self->readIntermediaries($type . "_DOMLoad")};
  %HTMLParse = %{$self->readIntermediaries($type . "_HTMLParse")};
  %time_downloads = %{$self->readIntermediaries($type . "_time_downloads")};
  %time_blocks = %{$self->readIntermediaries($type . "_time_blocks")};
  %time_comps = %{$self->readIntermediaries($type . "_time_comps")};
  %downloads_blocking = %{$self->readIntermediaries($type . "_downloads_blocking")};
  %downloads_proxy = %{$self->readIntermediaries($type . "_downloads_proxy")};
  %downloads_dns = %{$self->readIntermediaries($type . "_downloads_dns")};
  %downloads_conn = %{$self->readIntermediaries($type . "_downloads_conn")};
  %downloads_ssl = %{$self->readIntermediaries($type . "_downloads_ssl")};
  %downloads_send = %{$self->readIntermediaries($type . "_downloads_send")};
  %downloads_receiveFirst = %{$self->readIntermediaries($type . "_downloads_receiveFirst")};
  %downloads_receiveLast = %{$self->readIntermediaries($type . "_downloads_receiveLast")};
  %parses_style = %{$self->readIntermediaries($type . "_parses_style")};
  %parses_script = %{$self->readIntermediaries($type . "_parses_script")};
  %parses_layout = %{$self->readIntermediaries($type . "_parses_layout")};
  %parses_paint = %{$self->readIntermediaries($type . "_parses_paint")};
  %parses_other = %{$self->readIntermediaries($type . "_parses_other")};
  %parses_undefined = %{$self->readIntermediaries($type . "_parses_undefined")};

  %frac_time_downloads = %{$self->readIntermediaries($type . "_frac_time_downloads")};
  %frac_time_blocks = %{$self->readIntermediaries($type . "_frac_time_blocks")};
  %frac_time_comps = %{$self->readIntermediaries($type . "_frac_time_comps")};
  %frac_downloads_blocking = %{$self->readIntermediaries($type . "_frac_downloads_blocking")};
  %frac_downloads_proxy = %{$self->readIntermediaries($type . "_frac_downloads_proxy")};
  %frac_downloads_dns = %{$self->readIntermediaries($type . "_frac_downloads_dns")};
  %frac_downloads_conn = %{$self->readIntermediaries($type . "_frac_downloads_conn")};
  %frac_downloads_ssl = %{$self->readIntermediaries($type . "_frac_downloads_ssl")};
  %frac_downloads_send = %{$self->readIntermediaries($type . "_frac_downloads_send")};
  %frac_downloads_receiveFirst = %{$self->readIntermediaries($type . "_frac_downloads_receiveFirst")};
  %frac_downloads_receiveLast = %{$self->readIntermediaries($type . "_frac_downloads_receiveLast")};
  %frac_parses_style = %{$self->readIntermediaries($type . "_frac_parses_style")};
  %frac_parses_script = %{$self->readIntermediaries($type . "_frac_parses_script")};
  %frac_parses_layout = %{$self->readIntermediaries($type . "_frac_parses_layout")};
  %frac_parses_paint = %{$self->readIntermediaries($type . "_frac_parses_paint")};
  %frac_parses_other = %{$self->readIntermediaries($type . "_frac_parses_other")};
  %frac_parses_undefined = %{$self->readIntermediaries($type . "_frac_parses_undefined")};
  %frac_time_downloads_html = %{$self->readIntermediaries($type . "_frac_time_downloads_html")};
  %frac_time_downloads_css = %{$self->readIntermediaries($type . "_frac_time_downloads_css")};
  %frac_time_downloads_js = %{$self->readIntermediaries($type . "_frac_time_downloads_js")};
  %frac_time_downloads_img = %{$self->readIntermediaries($type . "_frac_time_downloads_img")};
  %frac_time_downloads_o = %{$self->readIntermediaries($type . "_frac_time_downloads_o")};
  %frac_time_blocks_css = %{$self->readIntermediaries($type . "_frac_time_blocks_css")};
  %frac_time_blocks_js = %{$self->readIntermediaries($type . "_frac_time_blocks_js")};
  %frac_time_ttfb = %{$self->readIntermediaries($type . "_frac_time_ttfb")};

  %dep_D2E = %{$self->readIntermediaries($type . "_dep_D2E")};
  %dep_E2D_html = %{$self->readIntermediaries($type . "_dep_E2D_html")};
  %dep_E2D_css = %{$self->readIntermediaries($type . "_dep_E2D_css")};
  %dep_E2D_js = %{$self->readIntermediaries($type . "_dep_E2D_js")};
  %dep_E2D_timer = %{$self->readIntermediaries($type . "_dep_E2D_timer")};
  %dep_RFB = %{$self->readIntermediaries($type . "_dep_RFB")};
  %dep_HOL_css = %{$self->readIntermediaries($type . "_dep_HOL_css")};
  %dep_HOL_js = %{$self->readIntermediaries($type . "_dep_HOL_js")};
  %num_domains_cp = %{$self->readIntermediaries($type . "_num_domains_cp")};
  %num_domains_all = %{$self->readIntermediaries($type . "_num_domains_all")};
  %text_domains_cp = %{$self->readIntermediaries($type . "_text_domains_cp")};
  %text_domains_all = %{$self->readIntermediaries($type . "_text_domains_all")};
  %num_objs_cp = %{$self->readIntermediaries($type . "_num_objs_cp")};
  %num_objs_all = %{$self->readIntermediaries($type . "_num_objs_all")};
  %num_bytes_cp = %{$self->readIntermediaries($type . "_num_bytes_cp")};
  %num_bytes_all = %{$self->readIntermediaries($type . "_num_bytes_all")};
  %num_send_cp = %{$self->readIntermediaries($type . "_num_send_cp")};
  %num_send_all = %{$self->readIntermediaries($type . "_num_send_all")};
  %num_conn_cp = %{$self->readIntermediaries($type . "_num_conn_cp")};
  %num_conn_all = %{$self->readIntermediaries($type . "_num_conn_all")};
  #%text_domain_tcp_net_cp = %{$self->readIntermediaries($type . "_text_domain_tcp_net_cp")};
  #%text_domain_tcp_net_all = %{$self->readIntermediaries($type . "_text_domain_tcp_net_all")};
  %act_timings = %{$self->readIntermediaries($type . "_act_timings")};

  my %domains = ();

#print $type . "_frac_time_downloads_html\n";
#print encode_json(\%frac_time_downloads_html) . "\n";

  my @plts;
  my @levels;
  my @DOMLoad;
  my @HTMLParse;
  my @time_blocks;
  my @time_downloads;
  my @time_comps;
  my @downloads_blocking;
  my @downloads_proxy;
  my @downloads_dns;
  my @downloads_conn;
  my @downloads_ssl;
  my @downloads_send;
  my @downloads_receiveFirst;
  my @downloads_receiveLast;
  my @parses_style;
  my @parses_script;
  my @parses_layout;
  my @parses_paint;
  my @parses_other;
  my @parses_undefined;

  my @frac_time_blocks;
  my @frac_time_downloads;
  my @frac_time_comps;
  my @frac_downloads_blocking;
  my @frac_downloads_proxy;
  my @frac_downloads_dns;
  my @frac_downloads_conn;
  my @frac_downloads_ssl;
  my @frac_downloads_send;
  my @frac_downloads_receiveFirst;
  my @frac_downloads_receiveLast;
  my @frac_parses_style;
  my @frac_parses_script;
  my @frac_parses_layout;
  my @frac_parses_paint;
  my @frac_parses_other;
  my @frac_parses_undefined;
  my @frac_time_downloads_html;
  my @frac_time_downloads_css;
  my @frac_time_downloads_js;
  my @frac_time_downloads_img;
  my @frac_time_downloads_o;
  my @frac_time_blocks_css;
  my @frac_time_blocks_js;
  my @frac_time_ttfb;
  my @frac_time_after;

  my @dep_D2E;
  my @dep_E2D_html;
  my @dep_E2D_css;
  my @dep_E2D_js;
  my @dep_E2D_timer;
  my @dep_RFB;
  my @dep_HOL_css;
  my @dep_HOL_js;
  my @num_domains_cp;
  my @num_domains_all;
  my @frac_domains_cp;
  my @num_objs_cp;
  my @num_objs_all;
  my @frac_objs_cp;
  my @num_bytes_cp;
  my @num_bytes_all;
  my @frac_bytes_cp;


  my @diffall;
  my @diff0;
  my @diff1;
  my @diff2;

  my %whatif = ();

  foreach $domain (keys %levels) {
    if ($levels{$domain} > 0) {
      $time = $time_blocks{$domain} + $time_downloads{$domain} + $time_comps{$domain};
      push (@plts, ($time_blocks{$domain} + $time_downloads{$domain} + $time_comps{$domain}) / 1000);

if (0) {
      if ($whatifMatrix{$domain}) {
        @matrix = @{decode_json($whatifMatrix{$domain})};
        $n = @matrix;
        $plt = $matrix[$n - 1];
        $i = 0;
        foreach $m (@matrix) {
          my @ppp = ();
          if ($whatif{$i}) {
            @ppp = @{decode_json($whatif{$i})};
          }
          $r = $m / $plt;
          push(@ppp, $r);
          $whatif{$i} = encode_json(\@ppp);
          ++$i;
        }
        
        #print $whatifMatrix{$domain} . "\n";
      }
      # this only works for google.com
      @actt = @{decode_json($act_timings{$domain})};
      %act0 = %{decode_json($actt[0])};
      $all = $act0{"e"};
      $diff0 = $act0{"e"} - $act0{"s"};
      %act1 = %{decode_json($actt[1])};
      $diff1 = $act1{"e"} - $act1{"s"};
      if ($actt[2]) {
        %act2 = %{decode_json($actt[2])};
        $diff2 = $act2{"e"} - $act2{"s"};
      }
      push(@diffall, $all);
      push(@diff0, $diff0);
      push(@diff1, $diff1);
      push(@diff2, $diff2);

      print $all . "\n";
      print $diff0 . "\n";
      print $diff1 . "\n";
      print $diff2 . "\n";
      print "\n";
}
      # end


      push (@levels, $levels{$domain});
      push (@DOMLoad, $DOMLoad{$domain});
      push (@HTMLParse, $HTMLParse{$domain});
      push (@time_blocks, $time_blocks{$domain});
      push (@time_downloads, $time_downloads{$domain} + $time_comps{$domain});
      push (@time_comps, $time_comps{$domain});
      push (@downloads_blocking, $downloads_blocking{$domain});
      push (@downloads_proxy, $downloads_proxy{$domain});
      push (@downloads_dns, $downloads_dns{$domain});
      push (@downloads_conn, $downloads_conn{$domain});
      push (@downloads_ssl, $downloads_ssl{$domain});
      push (@downloads_send, $downloads_send{$domain});
      push (@downloads_receiveFirst, $downloads_receiveFirst{$domain});
      push (@downloads_receiveLast, $downloads_receiveLast{$domain});
      push (@parses_style, $parses_style{$domain});
      push (@parses_script, $parses_script{$domain});
      push (@parses_layout, $parses_layout{$domain});
      push (@parses_paint, $parses_paint{$domain});
      push (@parses_other, $parses_other{$domain});
      push (@parses_undefined, $parses_undefined{$domain});
      push (@frac_time_blocks, $frac_time_blocks{$domain});
      push (@frac_time_downloads, $frac_time_downloads{$domain} + $frac_time_blocks{$domain});
      push (@frac_time_comps, $frac_time_comps{$domain});
      push (@frac_downloads_blocking, $frac_downloads_blocking{$domain});
      push (@frac_downloads_proxy, $frac_downloads_proxy{$domain});
      push (@frac_downloads_dns, $frac_downloads_dns{$domain});
      push (@frac_downloads_conn, $frac_downloads_conn{$domain});
      push (@frac_downloads_ssl, $frac_downloads_ssl{$domain});
      push (@frac_downloads_send, $frac_downloads_send{$domain});
      push (@frac_downloads_receiveFirst, $frac_downloads_receiveFirst{$domain});
      push (@frac_downloads_receiveLast, $frac_downloads_receiveLast{$domain});
      push (@frac_parses_style, $frac_parses_style{$domain});
      push (@frac_parses_script, $frac_parses_script{$domain});
      push (@frac_parses_layout, $frac_parses_layout{$domain} + $frac_parses_paint{$domain});
      #push (@frac_parses_paint, $frac_parses_paint{$domain});
      push (@frac_parses_other, $frac_parses_other{$domain});
      push (@frac_parses_undefined, $frac_parses_undefined{$domain});
      push (@dep_D2E, $dep_D2E{$domain});
      push (@dep_E2D_html, $dep_E2D_html{$domain});
      push (@dep_E2D_css, $dep_E2D_css{$domain});
      push (@dep_E2D_js, $dep_E2D_js{$domain});
      push (@dep_E2D_timer, $dep_E2D_timer{$domain});
      push (@dep_RFB, $dep_E2D_RFB{$domain});
      push (@dep_HOL_css, $dep_HOL_css{$domain});
      push (@dep_HOL_js, $dep_HOL_js{$domain});

      push(@frac_time_downloads_html, $frac_time_downloads_html{$domain});
      push(@frac_time_downloads_css, $frac_time_downloads_css{$domain});
      push(@frac_time_downloads_js, $frac_time_downloads_js{$domain});
      push(@frac_time_downloads_img, $frac_time_downloads_img{$domain});
      push(@frac_time_downloads_o, $frac_time_downloads_o{$domain});
      push(@frac_time_blocks_css, $frac_time_blocks_css{$domain});
      push(@frac_time_blocks_js, $frac_time_blocks_js{$domain});
      push(@frac_time_ttfb, $frac_time_ttfb{$domain});
      push(@frac_time_after, $frac_time_downloads{$domain} - $frac_time_ttfb{$domain});
      if ($num_domains_all{$domain} > 0) {
        push(@num_domains_cp, $num_domains_cp{$domain});
        push(@num_domains_all, $num_domains_all{$domain});
        push(@frac_domains_cp, $num_domains_cp{$domain} / $num_domains_all{$domain});
      }
      if ($num_objs_all{$domain} > 0) {
        push(@num_objs_cp, $num_objs_cp{$domain});
        push(@num_objs_all, $num_objs_all{$domain});
        push(@frac_objs_cp, $num_objs_cp{$domain} / $num_objs_all{$domain});
      }
      if ($num_bytes_all{$domain} > 0) {
        push(@num_bytes_cp, $num_bytes_cp{$domain});
        push(@num_bytes_all, $num_bytes_all{$domain});
        push(@frac_bytes_cp, $num_bytes_cp{$domain} / $num_bytes_all{$domain});
      }

      $text = $text_domains_all{$domain};
      if (!$text) {
        next;
      }

      %objs = %{decode_json($text)};
      foreach $d (keys %objs) {
        if ($domains{$d}) {
          $domains{$d}++;
        } else {
          $domains{$d} = 1;
        }
      }

    }
  }

if (0) {
  foreach $i (sort {$a <=> $b} keys %whatif) {
    @arr = @{decode_json($whatif{$i})};
    @arr = sort {$a <=> $b} @arr;
    $n = @arr;
    print $arr[$n / 2] . "\t";
    #print $arr[0] . "\t";
    if ( ($i + 1) % 5 == 0) {
      print "\n";
    }
    #print $i . "\t" . $arr[$n / 2] . "\n"
    #print $i . "\t" . $whatif{$i} . "\n";
  }

  my @domains_eval = [
    "pagead2.googlesyndication.com",
    "connect.facebook.net",
  ];

  foreach $d (keys %domains) {
    if ($d and $domains{$d} > 3 and $d =~ /\./) {
      push(@domains_eval, $d);
      #print $d . "\t" . $domains{$d} . "\n";
    }
  }

  my @frac_time_extern;
  foreach $domain (keys %text_domains_cp) {
    $text = $text_domains_cp{$domain};
    %text = %{decode_json($text)};
    $time = 0;
    foreach $d (keys %text) {
      foreach $de (@domains_eval) {
        if ($de eq "www.google.com" or $de eq "www.facebook.com" or $de eq "www.gstatic.com") {
          next;
        }
        if ($de eq $d) {
          $time += $text{$d};
          #print $domain . "\t" . $d . "\t" . $time . "\n";
          last;
        }
      }
    }
    $time = $time / ($time_blocks{$domain} + $time_comps{$domain} + $time_downloads{$domain});
    push(@frac_time_extern, $time);
  }

  # calc std that only works for google
  $avgall = $self->calculateAVG(\@diffall, 0);
  $avg0 = $self->calculateAVG(\@diff0, 0);
  $avg1 = $self->calculateAVG(\@diff1, 0);
  $avg2 = $self->calculateAVG(\@diff2, 0);
  $stdall = $self->calculateSTD(\@diffall);
  $std0 = $self->calculateSTD(\@diff0);
  $std1 = $self->calculateSTD(\@diff1);
  $std2 = $self->calculateSTD(\@diff2);

  print $stdall . "\t" . $avgall . "\n";
  print $std0 . "\t" . $avg0 . "\n";
  print $std1 . "\t" . $avg1 . "\n";
  print $std2 . "\t" . $avg2 . "\n";
  # end
}

  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_plt", \@plts);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_level", \@levels);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_DOMLoad", \@DOMLoad);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_HTMLParse", \@HTMLParse);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_time_download", \@frac_time_downloads);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_time_block", \@frac_time_blocks);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_time_comp", \@frac_time_comps);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_downloads_blocking", \@frac_downloads_blocking);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_downloads_proxy", \@frac_downloads_proxy);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_downloads_dns", \@frac_downloads_dns);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_downloads_conn", \@frac_downloads_conn);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_downloads_ssl", \@frac_downloads_ssl);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_downloads_send", \@frac_downloads_send);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_downloads_receiveFirst", \@frac_downloads_receiveFirst);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_downloads_receiveLast", \@frac_downloads_receiveLast);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_parses_style", \@frac_parses_style);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_parses_script", \@frac_parses_script);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_parses_layout", \@frac_parses_layout);
  #UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_parses_paint", \@frac_parses_paint);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_parses_other", \@frac_parses_other);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_parses_undefined", \@frac_parses_undefined);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_time_download", \@time_downloads);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_time_block", \@time_blocks);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_time_comp", \@time_comps);

  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_downloads_blocking", \@downloads_blocking);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_downloads_proxy", \@downloads_proxy);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_downloads_dns", \@downloads_dns);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_downloads_conn", \@downloads_conn);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_downloads_ssl", \@downloads_ssl);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_downloads_send", \@downloads_send);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_downloads_receiveFirst", \@downloads_receiveFirst);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_downloads_receiveLast", \@downloads_receiveLast);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_parses_style", \@parses_style);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_parses_script", \@parses_script);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_parses_layout", \@parses_layout);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_parses_paint", \@parses_paint);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_parses_other", \@parses_other);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_parses_undefined", \@parses_undefined);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_dep_D2E", \@dep_D2E);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_dep_E2D_html", \@dep_E2D_html);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_dep_E2D_css", \@dep_E2D_css);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_dep_E2D_js", \@dep_E2D_js);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_dep_E2D_timer", \@dep_E2D_timer);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_dep_RFB", \@dep_RFB);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_dep_HOL_css", \@dep_HOL_css);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_dep_HOL_js", \@dep_HOL_js);

  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_time_download_html", \@frac_time_downloads_html);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_time_download_css", \@frac_time_downloads_css);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_time_download_js", \@frac_time_downloads_js);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_time_download_img", \@frac_time_downloads_img);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_time_download_o", \@frac_time_downloads_o);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_time_block_css", \@frac_time_blocks_css);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_time_block_js", \@frac_time_blocks_js);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_time_ttfb", \@frac_time_ttfb);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_time_after", \@frac_time_after);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_num_domains_cp", \@num_domains_cp);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_num_domains_all", \@num_domains_all);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_domains_cp", \@frac_domains_cp);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_num_objs_cp", \@num_objs_cp);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_num_objs_all", \@num_objs_all);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_objs_cp", \@frac_objs_cp);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_num_bytes_cp", \@num_bytes_cp);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_num_bytes_all", \@num_bytes_all);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_bytes_cp", \@frac_bytes_cp);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_time_extern", \@frac_time_extern);
  UtilPlot->outputScatter($self->{_config}->{"ResultPath"} . $type . "_scatter_frac_domains_cp", \@frac_domains_cp, \@num_domains_cp);
}

sub processOverall {
  my ($self, $config) = @_;
  my $type = $_[1];
  my $type_c = $_[2];

  %time_blocks = %{$self->readIntermediaries($type . "_time_blocks")};
  %time_downloads = %{$self->readIntermediaries($type . "_time_downloads")};
  %time_comps = %{$self->readIntermediaries($type . "_time_comps")};
  %num_objs_cp = %{$self->readIntermediaries($type . "_num_objs_cp")};
  %num_objs_all = %{$self->readIntermediaries($type . "_num_objs_all")};
  %num_bytes_cp = %{$self->readIntermediaries($type . "_num_bytes_cp")};
  %num_bytes_all = %{$self->readIntermediaries($type . "_num_bytes_all")};
  %num_send_cp = %{$self->readIntermediaries($type . "_num_send_cp")};
  %num_send_all = %{$self->readIntermediaries($type . "_num_send_all")};
  %num_conn_cp = %{$self->readIntermediaries($type . "_num_conn_cp")};
  %num_conn_all = %{$self->readIntermediaries($type . "_num_conn_all")};

  %time_blocks_c = %{$self->readIntermediaries($type_c . "_time_blocks")};
  %time_downloads_c = %{$self->readIntermediaries($type_c . "_time_downloads")};
  %time_comps_c = %{$self->readIntermediaries($type_c . "_time_comps")};
  %levels_c = %{$self->readIntermediaries($type_c . "_levels")};
  %time_blocks_c = %{$self->readIntermediaries($type_c . "_time_blocks")};
  %time_downloads_c = %{$self->readIntermediaries($type_c . "_time_downloads")};
  %time_comps_c = %{$self->readIntermediaries($type_c . "_time_comps")};

  %num_objs_cp_c = %{$self->readIntermediaries($type_c . "_num_objs_cp")};
  %num_objs_all_c = %{$self->readIntermediaries($type_c . "_num_objs_all")};
  %num_bytes_cp_c = %{$self->readIntermediaries($type_c . "_num_bytes_cp")};
  %num_bytes_all_c = %{$self->readIntermediaries($type_c . "_num_bytes_all")};
  %num_send_cp_c = %{$self->readIntermediaries($type_c . "_num_send_cp")};
  %num_send_all_c = %{$self->readIntermediaries($type_c . "_num_send_all")};
  %num_conn_cp_c = %{$self->readIntermediaries($type_c . "_num_conn_cp")};
  %num_conn_all_c = %{$self->readIntermediaries($type_c . "_num_conn_all")};

  my @frac_time;
  my @frac_time_network;
  my @frac_time_comp;
  my @frac_objs_cp;
  my @frac_objs_all;
  my @frac_bytes_cp;
  my @frac_bytes_all;
  my @frac_send_cp;
  my @frac_send_all;
  my @frac_conn_cp;
  my @frac_conn_all;

  my @levels_c;
  my @time_total;
  my @time_total_c;
  my @time_blocks_c;
  my @time_downloads_c;
  my @time_comps_c;

  my $alpha = 0.3;
  foreach $domain (keys %time_downloads) {
    if ($time_downloads{$domain} > 0 and $time_downloads_c{$domain} > 0) {

      $total = $time_downloads{$domain} + $time_blocks{$domain} + $time_comps{$domain};
      $total_c = $time_downloads_c{$domain} + $time_blocks_c{$domain} + $time_comps_c{$domain};
      $frac = $total / $total_c;
      $frac_net = ($time_downloads{$domain} + $time_blocks{$domain}) / ($time_downloads_c{$domain} + $time_blocks_c{$domain});
      $frac_comp = $time_comps{$domain} / $time_comps_c{$domain};

      if ($num_objs_cp_c{$domain} > 0) {
        push(@frac_objs_cp, $num_objs_cp{$domain} / $num_objs_cp_c{$domain});
      }
      if ($num_objs_all_c{$domain} > 0) {
        push(@frac_objs_all, $num_objs_all{$domain} / $num_objs_all_c{$domain});
      }
      if ($num_bytes_cp_c{$domain} > 0) {
        push(@frac_bytes_cp, $num_bytes_cp{$domain} / $num_bytes_cp_c{$domain});
      }
      if ($num_bytes_all_c{$domain} > 0) {
        push(@frac_bytes_all, $num_bytes_all{$domain} / $num_bytes_all_c{$domain});
      }
      if ($num_send_cp_c{$domain} > 0) {
        push(@frac_send_cp, $num_send_cp{$domain} / $num_send_cp_c{$domain});
      }
      if ($num_send_all_c{$domain} > 0) {
        push(@frac_send_all, $num_send_all{$domain} / $num_send_all_c{$domain});
      }
      if ($num_conn_cp_c{$domain} > 0) {
        push(@frac_conn_cp, $num_conn_cp{$domain} / $num_conn_cp_c{$domain});
      }
      if ($num_conn_all_c{$domain} > 0) {
        push(@frac_conn_all, $num_conn_all{$domain} / $num_conn_all_c{$domain});
      }

      if ($frac > 1 + $alpha or $frac < 1 - $alpha) {
        #print $domain . "\t" . $frac . "\n";
      }

      push (@frac_time, $frac);
      push (@frac_time_network, $frac_net);
      push (@frac_time_comp, $frac_comp);
      push (@levels_c, $levels_c{$domain});

      push (@time_total, $total);
      push (@time_total_c, $total_c);
      push (@time_blocks_c, $time_blocks_c{$domain});
      push (@time_downloads_c, $time_downloads_c{$domain});
      push (@time_comps_c, $time_comps_c{$domain});
      #print $domain . "\t" . $frac . "\t" . ($time_downloads{$domain} + $time_blocks{$domain} + $time_comps{$domain}) . "\t" . ($time_downloads_c{$domain} + $time_blocks_c{$domain} + $time_comps_c{$domain}) . "\n";
    }
  }

  #print encode_json(\@frac_objs_cp) . "\n";

  #print $self->{_config}->{"ResultPath"} . $type . "_frac_time_overall\n";

  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_time_overall", \@frac_time);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_time_total", \@time_total);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_time_total_c", \@time_total_c);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_objs_cp", \@frac_objs_cp);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_objs_all", \@frac_objs_all);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_bytes_cp", \@frac_bytes_cp);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_bytes_all", \@frac_bytes_all);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_send_cp", \@frac_send_cp);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_send_all", \@frac_send_all);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_conn_cp", \@frac_conn_cp);
  UtilPlot->outputCDF($self->{_config}->{"ResultPath"} . $type . "_frac_conn_all", \@frac_conn_all);

}

sub calculateAVG {
  my ($self, $path1, $config) = @_;

  my @hash = @{$_[1]};
  my $switch = $_[2];
  my $ii = 0;
  my $sum = 0;

  $n = @hash;
  if ($switch) {
    foreach my $key (@hash) {
      $sum += $key;
      $ii++;
    }
  } else {
    @hash = sort {$a <=> $b} @hash;
    @hashn;
    for ($i = 0; $i < $n * (1 - 0.1); $i++) {
      $hashn[$i] = $hash[$i];
    }
    @hash = $hashn;
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
  my ($self, $path1, $config) = @_;
  my @hash = @{$_[1]};

  @hash = sort {$a <=> $b} @hash;
  @hashn;
  for ($i = 0; $i < $n * (1 - 0.1); $i++) {
    $hashn[$i] = $hash[$i];
  }
  @hash = @hashn;

  my $avg = $self->calculateAVG($_[1], 1);

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
