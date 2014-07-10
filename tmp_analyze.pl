#!/usr/bin/perl

use Switch;
use JSON;
use Error qw(:try);
use Scalar::Util qw/looks_like_number/;
use Statistics::LineFit;
use Try::Tiny;

use Util;
use UtilMath;
use UtilPlot;
use HarParser;

##########################################
# Check arguments
##########################################
$argc = @ARGV;

if ($argc < 2) {
  print "Usage: " . $0 . " [command {plt | redirect | dns | tcpsetup}] [path]\n";
  exit 0;
}
$cmd = $ARGV[0];
$path = $ARGV[1];

$sub_paths = `ls $path`;
@sub_paths = split(/\n/, $sub_paths);


#$path = "data/loquat";
$suffix = "";

$num_experiments = 5;

%hars_cold = [];
%hars_hot  = [];

# read and category har file names from directory
foreach $sub_path (@sub_paths) {
  %sites = ();

  # read har file names
  $hars = `ls $path/$sub_path/har$suffix`;
  @hars = split(/\n/, $hars);
  foreach $har (@hars) {
    @arr = split(/\+/, $har);
    $domain = $arr[0];
    if (exists $sites{$domain}) {
      $sites{$domain}++;
      # hot load
      push (@{$hars_hot{$domain}}, "$sub_path/har$suffix/$har");
    } else {
      $sites{$domain} = 1;
      push (@{$hars_cold{$domain}}, "$sub_path/har$suffix/$har");
    }
  }
}

# read domain -> geo mapping
%domain_geo = ();
open FP, "domain_country2continent.txt";
while ($line = <FP>) {
  @arr = split(/\n/, $line);
  @arr = split(/\t/, $arr[0]);
  $domain_geo{$arr[0]} = $arr[1];
  @arr = [];
}
close FP;

# read domains to eliminate and to redirect (by scripts)
%domain_eliminate = ();
%domain_redirect_to = ();
%domain_redirect_from = ();
%content_redirect = ();
open FP, "domain_map.txt";
while ($line = <FP>) {
  @arr = split(/\n/, $line);
  @arr = split(/\t/, $arr[0]);
  if ($arr[0] eq "abd") {
    $domain_eliminate{$arr[1]} = 1
  } elsif ($arr[0] eq "rdr") {
    $num = @arr - 1;
    $i = 1;
    while ($i < $num) {
      $domain_redirect_to{$arr[$i]} = $arr[$i + 1];
      $domain_redirect_from{$arr[$i + 1]} = $arr[$i];
      $i++;
    }
  }
}
close FP;
# read har file
foreach $har (@hars) {
  @arr = split(/\+/, $har);
  if (exists $domain_redirect_to{$arr[0]}) {
    $filename = "$path/har$suffix/$har";
    open FH, $filename;
    $str = "";
    while (<FH>) {
      $str .= $_;
    }
    $content_redirect{$arr[0]} = $str;
  }
}

##########################################
# switch by cmd
##########################################
if ($cmd eq "header") {
  processHeader();
} elsif ($cmd eq "cache") {
  processCache();
} elsif ($cmd eq "https") {
  processHTTPS();
} else {
  processPLT($cmd);
}

##########################################
# process page load time
##########################################
sub processPLT {
  $cmd = $_[0];

  ############## define params
  # plt
  @plts_min = [];
  @plts_med = [];
  @plts_max = [];

  %hash_plt_cold = ();
  %hash_plt_hot = ();
  %hash_plt_warm = ();

  @plts_na = [];
  @plts_asia = [];
  @plts_europe = [];

  @overhead_ttfb = [];
  @rdt = [];
  @percent_rdt = [];

  @plt_size = [];
  @plt_obj = [];
  @plt_tcp = [];
  @plt_domain = [];

  $i_na = 0;
  $i_asia = 0;
  $i_europe = 0;

  @plss_na = [];
  @plss_asia = [];
  @plss_europe = [];

  # redirect
  @redirect_num = [];
  @redirect_time = [];
  @redirect_time_eff = [];
  @redirect_time_req = [];

  # dns
  @dns_time = [];
  @dns_time_req = [];
  @dns_time_eff = [];

  # tcp setup
  @tcp_time = [];
  @tcp_time_req = [];
  @tcp_time_eff = [];

  # backend
  @backend_time = [];
  @backend_time_req = [];
  @backend_time_eff = [];

  @perc_page_diff = [];

  # evaluate "effective"
  @all_time_eff = [];

  # ..
  @std_size = [];
  @avg_size = [];
  @med_size = [];
  @max_size = [];
  @speed_bytes = [];
  @speed_ori = [];

  @all_domains = [];

  # # of parallel TCP conn.

  $i = 0;
  $i_req = 0;
  %sites = ();
  foreach $key (keys %hars_cold) {
    @hars = @{$hars_cold{$key}};

    # eliminate random sites
    $len = @hars;
    if ($len < $num_experiments) {
      next;
    }
    #@arr = split(/\+/, $har);
    #if (exists $sites{$arr[0]}) {
    #  $sites{$arr[0]}++;
    #  next;
    #} else {
    #  $sites{$arr[0]} = 1;
    #}

    $domain = $key;
    # skip abandoned domain from sqlite file
    #if (exists $domain_eliminate{$domain}) {
    #  next;
    #}
    #if (exists $domain_redirect_to{$domain}) {
    #  next;
    #}

    # should be # of instances we tested
    my @tmp_plts;
    foreach $har (@hars) {
      $filename = "$path/$har";

      $har_parser = new HarParser($filename);
      $plt = $har_parser->getPageLoadTime();

      if ($plt) {
        push (@tmp_plts, $plt);
      }
    }

    @tmp_plts = sort {$a <=> $b} @tmp_plts;
    $len = @tmp_plts;
    $plt_min = $tmp_plts[0];
    $plt_med = $tmp_plts[int($len/2)];
    $plt_max = $tmp_plts[$len - 1];

    $hash_plt_cold{$domain} = $plt_min;
    #print $len . "\t" . $plt_min . "\t" . $plt_med . "\n";

    # look at different server locations
    if ($plt_min > 0) {
      $plts_min[$i] = $plt_min;
      $plts_med[$i] = $plt_med;
      $plts_max[$i] = $plt_max;

      $all_domains[$i] = $domain;

      # look at ttfb overhead
      @entries = @{$har{"log"}{"entries"}};

      ################### init params
      # plt
      $page_stime = 0;
      $page_etime = 0;
      $page_ltime = 0;
      $page_ttlb = 0;
      $page_diff = 0;

      # redirect
      $red_num = 0;
      $red_time = 0;

      # dns
      $dns_time = 0;

      # tcp setup
      $tcp_time = 0;

      # backend
      $be_time = 0;

      # evaluate "effective"
      $all_time_eff = 0;

      # parallel conn.
      @para_e = [];
      $para_e[0] = -1;
      $p_i = 0;

      # size
      %size_per_domain = ();

      # compute parallelism
      my @timestamps;
      $timestamps[0] = 0;

      #print $domain . "\t" . $page{"pageTimings"}{"onLoad"} . "\t" . $domain_geo{$domain} . "\n";

      $j = 0;
      $cont = 0;
      $first = 0;
      $stime_prev = 0;
      foreach $entry (@entries) {
        %entry = %{$entry};
        $stime = Util->convertTime($entry{"startedDateTime"});

        ################# per req
        # redirect
        $status = int($entry{"response"}{"status"});
        $red = int($entry{"time"});
        $red = ($status =~ /30?/) ? $red : 0;
        $redirect_time_req[$i_req] = $red;

        # dns
        $dns = int($entry{"timings"}{"dns"});
        $dns = ($dns > 0) ? $dns : 0;
        $dns_time_req[$i_req] = $dns;

        # tcp setup
        $tcp = int($entry{"timings"}{"connect"});
        $tcp = ($tcp > 0) ? $tcp : 0;
        $tcp_time_req[$i_req] = $tcp;

        # backend
        $be = int($entry{"timings"}{"wait"});
        $be = ($be > 0) ? $be : 0;
        $backend_time_req[$i_req] = $be;

          # parallel downloads
          $block = int($entry{"timings"}{"blocked"});
          $block  = ($block > 0) ? $block : 0;
          $etime = $stime + (int($entry{"time"}) / 1000);
          #$stime += ($block + $dns + $tcp) / 1000;
          $stime += $block / 1000;
          @temp_para_e = [];
          $temp_i = 0;
          foreach $ts (@para_e) {
            if ($ts > $stime) {
              $temp_para_e[$temp_i] = $ts;
              $temp_i++;
            }
          }
          $temp_para_e[$temp_i] = $etime;
          $temp_i++;
          @para_e = @temp_para_e;
          $num_parallel = $temp_i;

        $mime = $entry{"response"}{"content"}{"mimeType"};
        if ($mime =~ /html/) {
          $first = 1;
          $first_stime = $stime;
        }
        if ($first == 1) {
          $t = $stime - $first_stime;
        }
        #print "\n" . $stime . " " . $etime . " " . $num_parallel . "\t" . $entry{"response"}{"bodySize"} . "\t" . $mime . "\n";
        #print $num_parallel . "\t" . $entry{"response"}{"bodySize"} . "\t" . $mime . "\n";

        # increment counter
        $i_req++;

        # resource downloading
        if ($cont == 1) {
          # a) convert stime
          %entry_prev = %{$entries[$j - 1]};

          $stime = Util->convertTime($entry{"startedDateTime"});
          $etime = $stime + (int($entry{"time"}) / 1000);

          if ($stime > $page_ltime) {
            $page_ttlb = $etime;
            last;
          }

          $diff = int(($stime - $stime_prev) * 1000 + 0.1);
          if ($diff >= 10 or $diff <= -10) {
            $page_diff += $diff;
            #print $diff . "\t";
          }

          $stime_prev = $stime;

          # b) compute parallelism
          my @temp_timestamps;
          $temp_i = 0;
          foreach $ts (@timestamps) {
            if ($ts > $stime) {
              $temp_timestamps[$temp_i] = $ts;
              $temp_i++;
            }
          }
          $temp_timestamps[$temp_i] = $etime;
          @timestamps = @temp_timestamps;
          $num_parallel = $temp_i + 1;

          ############### rdt param
          # redirect
          $red_time_eff += $red / $num_parallel;

          # dns
          $dns_time_eff += $dns / $num_parallel;

          # dns
          $tcp_time_eff += $tcp / $num_parallel;

          # backend
          $be_time_eff += $be / $num_parallel;

          # evaluate "effective"
          $all_time_eff += int($entry{"time"}) / $num_parallel;

          #
          $body = $entry{"response"}{"bodySize"};
          $body = ($body > 0) ? $body : 0;
          #if (exists $size_per_domain{$d}) {
          #  $size_per_domain{$d} += $body / 1024;
          #} else {
          #  $size_per_domain{$d} = $body / 1024;
          #}

          next;
        }

        ################ time to first byte
        # redirect
        $red_time += $red;
        $red_num++;

        # dns
        $dns_time += $dns;

        # tcp
        $tcp_time += $tcp;

        # backend
        $be_time += $be;


        if ($j == 0) {
          $page_stime = Util->convertTime($entry{"startedDateTime"});
          $page_ltime = $page_stime + (int($page{"pageTimings"}{"onContentLoad"}) / 1000);
        }
        $status = $entry{"response"}{"status"};
        if ($status =~ /200/) {
          $cont = 1;
          $blocked = int($entry{"timings"}{"blocked"});
          $dns = int($entry{"timings"}{"dns"});
          $connect = int($entry{"timings"}{"connect"});
          $send = int($entry{"timings"}{"send"});
          $wait = int($entry{"timings"}{"wait"});
          $page_etime = Util->convertTime($entry{"startedDateTime"}) + $blocked + $dns + $connect + $send + $wait;
          $stime_prev = $stime;
        }
        $j++;
      }

      $paint_time = int(($page_stime + (int($page{"pageTimings"}{"onLoad"}) / 1000) - $etime) * 1000 + 0.1);
      #print "\n$paint_time\n";
      if ($paint_time > 0) {
        $page_diff += $paint_time;
      }

      $perc_page_diff[$i] = $page_diff / $plt / 1000;
      #print "$page_diff\n\n";

      # plt macro level
      $plt_obj[$i] = 0;
      $plt_size[$i] = 0;
      $plt_domain[$i] = 0;
      $plt_tcp[$i] = 0;

      $overhead_ttfb = 0;
      $body_size = 0;

      %domains = ();
      $cont = 1;
      foreach $entry (@entries) {
        %entry = %{$entry};

        # num of objects
        $plt_obj[$i]++;

        # content size
        $body = int($entry{"response"}{"bodySize"});
        $body = ($body > 0) ? $body : 0;
        $plt_size[$i] += $body;

        # num of tcp connections
        $conn = int($entry{"timings"}{"connect"});
        $conn = ($conn > 0) ? $conn : 0;
        if ($conn > 1) {
          $plt_tcp[$i]++;
        }

        # num of domains
        $d = $entry{"serverIPAddress"};
        $domains{$d} = 1;

        if (exists $size_per_domain{$d}) {
          $size_per_domain{$d} += $body / 1024;
        } else {
          $size_per_domain{$d} = $body / 1024;
        }
      }

      ################### post-processing params
      # calculate num of domains
      $overhead_ttfb[$i] = ($page_etime - $page_stime) / 1000;
      $overhead_ttlb[$i] = ($page_ttlb - $page_stime) / 1000;
      $percent_ttfb[$i] = $overhead_ttfb[$i] / $plt;
      $rdt[$i] = $plts[$i] - $overhead_ttfb[$i];
      $percent_rdt[$i] = $rdt[$i] / $plt;

      $plt_size[$i] /= 1024; # KB
      $plt_domain[$i] = scalar keys %domains;

      # redirect
      $redirect_num[$i] = $red_num;
      $redirect_time[$i] = $red_time / 1000;
      $redirect_time_eff[$i] = $red_time_eff / 1000;

      # dns
      $dns_time[$i] = $dns_time / 1000;
      $dns_time_eff[$i] = $dns_time_eff / 1000;

      # tcp
      $tcp_time[$i] = $tcp_time / 1000;
      $tcp_time_eff[$i] = $tcp_time_eff / 1000;

      # backend
      $backend_time[$i] = $be_time / 1000;
      $backend_time_eff[$i] = $be_time_eff / 1000;

      # evaluate "effective"
      $all_time_eff[$i] = $all_time_eff / 1000;


      $speed_bytes[$i] = $plt_size[$i] / $plt; # KB/s
      #$std_size[$i] = calculatePerc(\%size_per_domain, 0.5);
      #$std_size[$i] = calculatePerc(\%size_per_domain, 0.5);
      $std_size[$i] = UtilMath->calculateSTD(\%size_per_domain);
      $avg_size[$i] = UtilMath->calculateAVG(\%size_per_domain);
      $med_size[$i] = UtilMath->calculatePerc(\%size_per_domain, 0.5);
      $max_size[$i] = UtilMath->calculateMAX(\%size_per_domain);
      #print $plt . "\n";

      # [plt] different location
      if ($domain_geo{$domain} eq "Asia") {
        $plts_asia[$i_asia] = $plt_min;
        $plss_asia[$i_asia] = $plt_size[$i] / $plt_min;
        $i_asia++;
      } elsif ($domain_geo{$domain} eq "North America") {
        $plts_na[$i_na] = $plt_min;
        $plss_na[$i_na] = $plt_size[$i] / $plt_min;
        $i_na++;
      } elsif ($domain_geo{$domain} eq "Europe") {
        $plts_europe[$i_europe] = $plt_min;
        $plss_europe[$i_europe] = $plt_size[$i] / $plt_min;
        $i_europe++;
      }

      # increment counter
      $i++;
    }
  }
  $n = $i;

  switch ($cmd) {
    case ("plt") {
      # plt
      print "# of pages by location:\n";
      print "Overall: $n\n";
      print "Asia: $i_asia\n";
      print "Europe: $i_europe\n";
      print "North America: $i_na\n";

      UtilPlot->outputScatter("plot/scatter_plt_ttfbover.txt", \@plts, \@overhead_ttfb);
      UtilPlot->outputScatter("plot/scatter_plt_rdt.txt", \@plts, \@rdt);
      UtilPlot->outputScatter("plot/scatter_plt_size.txt", \@plts, \@plt_size);
      UtilPlot->outputScatter("plot/scatter_plt_obj.txt", \@plts, \@plt_obj);
      UtilPlot->outputScatter("plot/scatter_plt_domain.txt", \@plts, \@plt_domain);
      UtilPlot->outputScatter("plot/scatter_plt_tcp.txt", \@plts, \@plt_tcp);
      UtilPlot->outputScatter("plot/scatter_plt_eff.txt", \@rdt, \@all_time_eff);

      $i = 0;
      $j = 0;
      @c_speed_bytes = [];
      @c_std_size = [];
      #foreach $d (@all_domains) {
      foreach $ps (@plt_obj) {
        #if ($ps > 500) { # size
        if ($ps >= 0) { # obj
        #if ($ps > 10) { # domain
        #if ($domain_geo{$d} eq "North America") { # obj
          $c_speed_bytes[$j] = $speed_bytes[$i];
          $c_std_size[$j] = $std_size[$i];
          #$c_std_size[$j] = $plt_size[$i];
          $j++;
        }
        $i++;
      }
      print $j . "\t" . $i . "\n";
      use Statistics::LineFit;
      $lineFit = Statistics::LineFit->new();
      $lineFit->setData (\@c_speed_bytes, \@c_std_size) or die "Invalid data";
      #($intercept, $slope) = $lineFit->coefficients();
      $rSquared = $lineFit->rSquared();
      $meanSquaredError = $lineFit->meanSqError();
      #$durbinWatson = $lineFit->durbinWatson();
      print $rSquared . "\t" . $meanSquaredError . "\n";

      UtilPlot->outputScatter("plot/scatter_speed_std.txt", \@c_speed_bytes, \@c_std_size);
      UtilPlot->outputScatter("plot/scatter_pls_obj.txt", \@speed_bytes, \@plt_obj);
      UtilPlot->outputScatter("plot/scatter_pls_size.txt", \@speed_bytes, \@plt_size);
      UtilPlot->outputScatter("plot/scatter_pls_domain.txt", \@speed_bytes, \@plt_domain);
      UtilPlot->outputScatter("plot/scatter_pls_tcp.txt", \@speed_bytes, \@plt_tcp);
      UtilPlot->outputScatter("plot/scatter_pls_std.txt", \@speed_bytes, \@std_size);
      UtilPlot->outputScatter("plot/scatter_pls_avg.txt", \@speed_bytes, \@avg_size);
      UtilPlot->outputScatter("plot/scatter_pls_med.txt", \@speed_bytes, \@med_size);
      UtilPlot->outputScatter("plot/scatter_pls_max.txt", \@speed_bytes, \@max_size);
      UtilPlot->outputScatter("plot/scatter_plt_page_diff.txt", \@plts, \@perc_page_diff);

      UtilPlot->outputCDF("plot/perc_page_diff.txt", \@perc_page_diff);

      UtilPlot->outputCDF("plot/plt_min.txt", \@plts_min);
      UtilPlot->outputCDF("plot/plt_med.txt", \@plts_med);
      UtilPlot->outputCDF("plot/plt_max.txt", \@plts_max);

      UtilPlot->outputCDF("plot/plt_na.txt", \@plts_na);
      UtilPlot->outputCDF("plot/plt_asia.txt", \@plts_asia);
      UtilPlot->outputCDF("plot/plt_europe.txt", \@plts_europe);
      UtilPlot->outputCDF("plot/overhead_ttfb.txt", \@overhead_ttfb);
      UtilPlot->outputCDF("plot/overhead_perc_ttfb.txt", \@percent_ttfb);
      UtilPlot->outputCDF("plot/rdt.txt", \@rdt);
      UtilPlot->outputCDF("plot/rdt_perc.txt", \@percent_rdt);

      UtilPlot->outputCDF("plot/speed_bytes.txt", \@c_speed_bytes);
      UtilPlot->outputCDF("plot/pls_na.txt", \@plss_na);
      UtilPlot->outputCDF("plot/pls_asia.txt", \@plss_asia);
      UtilPlot->outputCDF("plot/pls_europe.txt", \@plss_europe);
    }
    case ("redirect") {
      UtilPlot->outputScatter("plot/scatter_redirect1.txt", \@overhead_ttfb, \@redirect_time);
      UtilPlot->outputScatter("plot/scatter_redirect2.txt", \@rdt, \@redirect_time_eff);
      UtilPlot->outputCDF("plot/redirect0.txt", \@redirect_time_req);
      UtilPlot->outputCDF("plot/redirect1.txt", \@redirect_time);
      UtilPlot->outputCDF("plot/redirect2.txt", \@redirect_time_eff);
    }
    case ("dns") {
      UtilPlot->outputScatter("plot/scatter_dns1.txt", \@overhead_ttfb, \@dns_time);
      UtilPlot->outputScatter("plot/scatter_dns2.txt", \@rdt, \@dns_time_eff);
      UtilPlot->outputCDF("plot/dns0.txt", \@dns_time_req);
      UtilPlot->outputCDF("plot/dns1.txt", \@dns_time);
      UtilPlot->outputCDF("plot/dns2.txt", \@dns_time_eff);
    }
    case ("tcpsetup") {
      UtilPlot->outputScatter("plot/scatter_tcp1.txt", \@overhead_ttfb, \@tcp_time);
      UtilPlot->outputScatter("plot/scatter_tcp2.txt", \@rdt, \@tcp_time_eff);
      UtilPlot->outputCDF("plot/tcpsetup0.txt", \@tcp_time_req);
      UtilPlot->outputCDF("plot/tcpsetup1.txt", \@tcp_time);
      UtilPlot->outputCDF("plot/tcpsetup2.txt", \@tcp_time_eff);
    }
    case ("backend") {
      UtilPlot->outputScatter("plot/scatter_backend1.txt", \@overhead_ttfb, \@backend_time);
      UtilPlot->outputScatter("plot/scatter_backend2.txt", \@rdt, \@backend_time_eff);
      UtilPlot->outputCDF("plot/backend0.txt", \@backend_time_req);
      UtilPlot->outputCDF("plot/backend1.txt", \@backend_time);
      UtilPlot->outputCDF("plot/backend2.txt", \@backend_time_eff);
    }
  }
}

##########################################
# process redirects
##########################################
sub processRedirect {
  # block
  @redirect_num = [];
  @redirect_time = [];
  @redirect_time_eff = [];
  @redirect_time_req = [];
  @redirect_time_script = [];

  $i = 0;
  $i_req = 0;
  $i_script = 0;

  $no_www = 0;
  # only consider cold load for now
  %sites = ();
  foreach $har (@hars) {
    @arr = split(/\+/, $har);
    $domain = $arr[0];

    # skip abandoned domain from sqlite file
    if (exists $domain_eliminate{$domain}) {
      next;
    }
    if (exists $domain_redirect_to{$domain}) {
      next;
    }

    # open file
    $filename = "$path/har$suffix/$har";
    open FH, $filename;

    # get har
    $str = "";
    while ($line = <FH>) {
      $str .= $line;
    }
    close FH;
    %har = %{decode_json($str)};

    # get pages
    @pages = @{$har{"log"}{"pages"}};
    %page = %{$pages[0]};

    # get entries
    @entries = @{$har{"log"}{"entries"}};

    # skip if it's cached
    $domain_ori = $entries[0]{"request"}{"url"};
    @ado = split(/\//, $domain_ori);
    $domain_ori = $ado[2];
    @ado = split(/www\./, $domain_ori);
    $nado = @ado;
    $domain_ori = ($nado > 1) ? $ado[1] : $ado[0];
    if (exists $sites{$domain_ori}) {
      $sites{$domain_ori}++;
      next;
    } else {
      $sites{$domain_ori} = 1;
    }
    print $domain_ori . "\n";

    $redi_time = 0;
    $redi_time_eff = 0;
    $j = 0;

    $domain_first = 0;

    # check whether it's redirected
    if (exists $domain_redirect_from{$domain}) {
      $redirect_from = $domain_redirect_from{$domain};
      $str = $content_redirect{$redirect_from};
      %har_f = %{decode_json($str)};

      # get pages
      @pages_f = @{$har_f{"log"}{"pages"}};
      %page_f = %{$pages_f[0]};

      $onload = int($page_f{"pageTimings"}{"onLoad"});
      $redirect_time_script[$i_script] = $onload / 1000;
      $i_script++;
      $redi_time += $onload;
      $redi_time_eff += $onload;
      $j++;

      print $redirect_from . "\t" . $onload . "\n";

      # update domain_first
      $domain_first = $redirect_from;
    }

    my @timestamps;
    $timestamps[0] = 0;
    $cont = 0;
    $no_www_current = 0;
    foreach $entry (@entries) {
      %entry = %{$entry};
      $status = int($entry{"response"}{"status"});

      $domain_current = $entry{"request"}{"url"};
      @ado = split(/\//, $domain_current);
      $domain_current = $ado[2];

      if ("www." . $domain_first eq $domain_current) {
        $no_www_current = 1;
      }

      # per req
      if ($status >= 300 and $status < 400) {
        $redirect_time_req[$i_req] = int($entry{"time"}) / 1000;
        $i_req++;

        if ($domain_first == 0) {
          $domain_first = $entry{"request"}{"url"};
          @ado = split(/\//, $domain_first);
          $domain_first = $ado[2];
        }
      }

      # per page
      if ($cont == 0 and $status >= 300 and $status < 400) {
        $redi_time += int($entry{"time"});
        $j++;
      } else {
        $cont = 200;
      }

      # eff
      # a) convert stime
      $stime = Util->convertTime($entry{"startedDateTime"});
      $etime = $stime + int($entry{"time"});

      # b) compute parallelism
      my @temp_timestamps;
      $temp_i = 0;
      foreach $ts (@timestamps) {
        if (int($ts) > $stime) {
          $temp_timestamps[$temp_i] = $ts;
          $temp_i++;
        }
      }
      $temp_timestamps[$temp_i] = $etime;
      @timestamps = @temp_timestamps;
      $num_parallel = $temp_i + 1;
      $redi_time_eff += int($entry{"time"}) / $num_parallel;
    }
    $no_www += $no_www_current;
    $redirect_time[$i] = $redi_time / 1000;
    $redirect_time_eff[$i] = $redi_time_eff / 1000;
    $redirect_num[$i] = $j;

    # print multiple redirects
    $i++;
    if ($j > 1) {
      #print $har . "\t";
      #print $j . "\t";
      #print $redi_time . "\n";
    }
  }
  $n = $i;
  # per page
  $median_code = UtilPlot->outputCDF("plot/redirect0.txt", \@redirect_time_req);
  $median_script = UtilPlot->outputCDF("plot/redirect0_1.txt", \@redirect_time_script);
  UtilPlot->outputCDF("plot/redirect1.txt", \@redirect_time);
  UtilPlot->outputCDF("plot/redirect2.txt", \@redirect_time_eff);

  #print "a.com -> www.a.com: $non_zero out of $n\n";
  #median
  print "median w code: $median_code ins: $i_req\n";
  print "median w script: $median_script ins: $i_script\n";
  print "a.com -> www.a.com: $no_www/$n\n"
}

##########################################
# process headers
##########################################
sub processHeader {
  @plts = [];
  @http_size_req = [];
  @http_size_res = [];
  @http_size_req_all = [];
  @http_size_res_all = [];
  @http_frac_bth = [];
  @http_frac_res = [];
  @http_frac_bth_all = [];
  @http_frac_res_all = [];
  @http_stime_req = [];

  %req_bytes = ();
  %res_bytes = ();

  $i = 0;
  $i_req = 0;
  %sites = ();
  foreach $har (@hars) {

    # filter out cached pages
    @arr = split(/\+/, $har);
    if (exists $sites{$arr[0]}) {
      $sites{$arr[0]}++;
      next;
    } else {
      $sites{$arr[0]} = 1;
    }

    $filename = "$path/har$suffix/$har";
    open FH, $filename;

    # get har
    $str = "";
    while ($line = <FH>) {
      $str .= $line;
    }
    %har = %{decode_json($str)};

    # get pages
    @pages = @{$har{"log"}{"pages"}};
    %page = %{$pages[0]};
    $plt = int($page{"pageTimings"}{"onLoad"}) / 1000;
    $plts[$i] = $plt;

    # get entries
    @entries = @{$har{"log"}{"entries"}};
    $http_size = 0;
    $dns_time_eff = 0;
    $cont = 1;

    # compute parallelism
    my @timestamps;
    $timestamps[0] = 0;

    $http_req_all = 0;
    $http_res_all = 0;
    $http_body_all = 0;

    foreach $entry (@entries) {
      %entry = %{$entry};
      # per req
      $req = int($entry{"request"}{"headersSize"});
      $res = int($entry{"response"}{"headersSize"});
      $body = int($entry{"response"}{"bodySize"});
      $http_size_req[$i_req] = $req;
      $http_size_res[$i_req] = $res;
      if (int($entry{"response"}{"bodySize"}) > 0) {
        $http_frac_res[$i_req] = $res / ($res + $body);
        $http_frac_bth[$i_req] = ($res + $req) / ($res + $req + $body);
      }
      $http_stime_req[$i_req] = int($entry{"timings"}{"send"});
      if (int($entry{"timings"}{"send"}) > 1) {
        #print $entry{"timings"}{"send"} . "\t" . $req . "\n";
      }
      $i_req++;

      # per page
      $http_req_all += int($entry{"request"}{"headersSize"});
      $http_res_all += int($entry{"response"}{"headersSize"});
      if (int($entry{"response"}{"bodySize"}) > 0) {
        $http_body_all += int($entry{"response"}{"bodySize"});
      }

      # kinds of headers
      @headers = @{$entry{"request"}{"headers"}};
      foreach $header (@headers) {
        %header = %{$header};
        if (exists $req_bytes{$header{"name"}}) {
          $req_bytes{$header{"name"}} += length($header{"value"}) + length($header{"name"}) + 3;
        } else {
          $req_bytes{$header{"name"}} = length($header{"value"}) + length($header{"name"}) + 3;
        }
      }
      @headers = @{$entry{"response"}{"headers"}};
      foreach $header (@headers) {
        %header = %{$header};
        if (exists $res_bytes{$header{"name"}}) {
          $res_bytes{$header{"name"}} += length($header{"value"}) + length($header{"name"}) + 3;
        } else {
          $res_bytes{$header{"name"}} = length($header{"value"}) + length($header{"name"}) + 3;
        }
      }
    }
    $http_size_req_all[$i] = $http_req_all;
    $http_size_res_all[$i] = $http_res_all;
    $http_frac_bth_all[$i] = ($http_req_all + $http_res_all) / ($http_req_all + $http_res_all + $http_body_all);
    $http_frac_res_all[$i] = $http_res_all / ($http_res_all + $http_body_all);

    $i++;
  }
  $n = $i;
  print $n . "\n";
  print $i_req . "\n";

  # output
  $i = 0;
  foreach $key (sort {$req_bytes{$b} <=> $req_bytes{$a}} keys %req_bytes) {
    print $key . "\t" . $req_bytes{$key} . "\n";
    $i++;
  }
  print "Num of headers:" + $i . "\n";

  print "==========================\n";

  $i = 0;
  foreach $key (sort {$res_bytes{$b} <=> $res_bytes{$a}} keys %res_bytes) {
    print $key . "\t" . $res_bytes{$key} . "\n";
    $i++;
  }
  print "Num of headers:" + $i . "\n";

  # absolute size
  UtilPlot->outputCDF("plot/header_req1.txt", \@http_size_req_all);
  UtilPlot->outputCDF("plot/header_res1.txt", \@http_size_res_all);
  UtilPlot->outputCDF("plot/header_req0.txt", \@http_size_req);
  UtilPlot->outputCDF("plot/header_res0.txt", \@http_size_res);

  # fraction of sites
  UtilPlot->outputCDF("plot/header_bth_frac_1.txt", \@http_frac_bth_all);
  UtilPlot->outputCDF("plot/header_res_frac_1.txt", \@http_frac_res_all);
  UtilPlot->outputCDF("plot/header_bth_frac_0.txt", \@http_frac_bth);
  UtilPlot->outputCDF("plot/header_res_frac_0.txt", \@http_frac_res);

  UtilPlot->outputCDF("plot/header_stime_req.txt", \@http_stime_req);
}

##########################################
# process cache
##########################################
sub processCache {
  # cold load
  my %hash_ret_c = %{processMacro(\%hars_cold)};
  my %hash_plt_time = %{$hash_ret_c{"plt"}};
  my %hash_plt_obj = %{$hash_ret_c{"obj"}};
  my %hash_plt_tcp = %{$hash_ret_c{"tcp"}};
  my %hash_plt_size = %{$hash_ret_c{"size"}};
  my %hash_plt_domain = %{$hash_ret_c{"domain"}};

  my %hash_ttfb = %{$hash_ret_c{"ttfb"}};
  my %hash_ttfb_red = %{$hash_ret_c{"ttfb_red"}};
  my %hash_ttfb_red_num = %{$hash_ret_c{"ttfb_red_num"}};
  my %hash_ttfb_dns = %{$hash_ret_c{"ttfb_dns"}};
  my %hash_ttfb_tcp = %{$hash_ret_c{"ttfb_tcp"}};
  my %hash_ttfb_send = %{$hash_ret_c{"ttfb_send"}};
  my %hash_ttfb_be = %{$hash_ret_c{"ttfb_be"}};
  my %hash_ttfb_recv = %{$hash_ret_c{"ttfb_recv"}};

  # warm load
  my %hash_ret_h = %{processMacro(\%hars_hot)};
  my %hash_plt_time_cache = %{$hash_ret_h{"plt"}};
  my %hash_plt_obj_cache = %{$hash_ret_h{"obj"}};
  my %hash_plt_tcp_cache = %{$hash_ret_h{"tcp"}};
  my %hash_plt_size_cache = %{$hash_ret_h{"size"}};
  my %hash_plt_domain_cache = %{$hash_ret_h{"domain"}};

  my %hash_ttfb_h = %{$hash_ret_h{"ttfb"}};
  my %hash_ttfb_red_h = %{$hash_ret_h{"ttfb_red"}};
  my %hash_ttfb_red_num_h = %{$hash_ret_h{"ttfb_red_num"}};
  my %hash_ttfb_dns_h = %{$hash_ret_h{"ttfb_dns"}};
  my %hash_ttfb_tcp_h = %{$hash_ret_h{"ttfb_tcp"}};
  my %hash_ttfb_send_h = %{$hash_ret_h{"ttfb_send"}};
  my %hash_ttfb_be_h = %{$hash_ret_h{"ttfb_be"}};
  my %hash_ttfb_recv_h = %{$hash_ret_h{"ttfb_recv"}};

  # calculation
  my @plt_time;
  my @plt_time_frac;
  my @plt_obj;
  my @plt_obj_frac;
  my @plt_tcp;
  my @plt_tcp_frac;
  my @plt_size;
  my @plt_size_frac;
  my @plt_domain;
  my @plt_domain_frac;

  my @ttfb_c;
  my @ttfb_frac_c;
  my @ttfb_red_num_c;
  my @ttfb_red_frac_c;
  my @ttfb_dns_frac_c;
  my @ttfb_tcp_frac_c;
  my @ttfb_send_frac_c;
  my @ttfb_be_frac_c;
  my @ttfb_recv_frac_c;

  my @ttfb_h;
  my @ttfb_frac_h;
  my @ttfb_red_num_h;
  my @ttfb_red_frac_h;
  my @ttfb_dns_frac_h;
  my @ttfb_tcp_frac_h;
  my @ttfb_send_frac_h;
  my @ttfb_be_frac_h;
  my @ttfb_recv_frac_h;

  foreach $key (keys %hash_plt_time) {
    if (!$hash_plt_time{$key}) {
      next;
    }
    #print $key . "\n";
    #print $hash_ttfb_red{$key} . "\n\n";

    # macro level
    $tmp = $hash_plt_time{$key} - $hash_plt_time_cache{$key};
    if ($tmp > 0) {
      push (@plt_time, $tmp);
      push (@plt_time_frac, $tmp / $hash_plt_time{$key});
    }
    $tmp = $hash_plt_obj{$key} - $hash_plt_obj_cache{$key};
    if ($tmp > 0) {
      push (@plt_obj, $tmp);
      push (@plt_obj_frac, $tmp / $hash_plt_obj{$key});
    }
    $tmp = $hash_plt_tcp{$key} - $hash_plt_tcp_cache{$key};
    if ($tmp > 0) {
      push (@plt_tcp, $tmp);
      push (@plt_tcp_frac, $tmp / $hash_plt_tcp{$key});
    }
    $tmp = $hash_plt_size{$key} - $hash_plt_size_cache{$key};
    if ($tmp > 0) {
      push (@plt_size, $tmp);
      push (@plt_size_frac, $tmp / $hash_plt_size{$key});
    }
    $tmp = $hash_plt_domain{$key} - $hash_plt_domain_cache{$key};
    if ($tmp > 0) {
      push (@plt_domain, $tmp);
      push (@plt_domain_frac, $tmp / $hash_plt_domain{$key});
    }

    if ($hash_ttfb_red_num{$key} > $hash_ttfb_red_num_h{$key}) {
      print $key . "\t" . $hash_ttfb_red_num{$key} . "\t" . $hash_ttfb_red_num_h{$key} . "\n";
    }

    # micro level
    if ($hash_ttfb{$key} > 0) {
      push (@ttfb_c, $hash_ttfb{$key});
      push (@ttfb_red_num_c, $hash_ttfb_red_num{$key});
      push (@ttfb_red_frac_c, $hash_ttfb_red{$key} / $hash_ttfb{$key});
      push (@ttfb_dns_frac_c, $hash_ttfb_dns{$key} / $hash_ttfb{$key});
      push (@ttfb_tcp_frac_c, $hash_ttfb_tcp{$key} / $hash_ttfb{$key});
      push (@ttfb_send_frac_c, $hash_ttfb_send{$key} / $hash_ttfb{$key});
      push (@ttfb_be_frac_c, $hash_ttfb_be{$key} / $hash_ttfb{$key});
      push (@ttfb_recv_frac_c, $hash_ttfb_recv{$key} / $hash_ttfb{$key});
      if ($hash_plt_time{$key} > 0) {
        push (@ttfb_frac_c, $hash_ttfb{$key} / $hash_plt_time{$key});
      }
    }
    if ($hash_ttfb_h{$key} > 0) {
      push (@ttfb_h, $hash_ttfb_h{$key});
      push (@ttfb_red_num_h, $hash_ttfb_red_num_h{$key});
      push (@ttfb_red_frac_h, $hash_ttfb_red_h{$key} / $hash_ttfb_h{$key});
      push (@ttfb_dns_frac_h, $hash_ttfb_dns_h{$key} / $hash_ttfb_h{$key});
      push (@ttfb_tcp_frac_h, $hash_ttfb_tcp_h{$key} / $hash_ttfb_h{$key});
      push (@ttfb_send_frac_h, $hash_ttfb_send_h{$key} / $hash_ttfb_h{$key});
      push (@ttfb_be_frac_h, $hash_ttfb_be_h{$key} / $hash_ttfb_h{$key});
      push (@ttfb_recv_frac_h, $hash_ttfb_recv_h{$key} / $hash_ttfb_h{$key});
      if ($hash_plt_time_cache{$key} > 0) {
        push (@ttfb_frac_h, $hash_ttfb_h{$key} / $hash_plt_time_cache{$key});
      }
    }
  }

  print "Without cache:\n";
  my @a_plt_time = values %hash_plt_time;
  my @a_plt_obj = values %hash_plt_obj;
  my @a_plt_tcp = values %hash_plt_tcp;
  my @a_plt_size = values %hash_plt_size;
  my @a_plt_domain = values %hash_plt_domain;
  use Statistics::LineFit;
  $lineFit = Statistics::LineFit->new();
  $lineFit->setData (\@a_plt_time, \@a_plt_obj) or die "Invalid data";
  print "obj\t" . $lineFit->rSquared() . "\n";
  $lineFit->setData (\@a_plt_time, \@a_plt_tcp) or die "Invalid data";
  print "tcp\t" . $lineFit->rSquared() . "\n";
  $lineFit->setData (\@a_plt_time, \@a_plt_size) or die "Invalid data";
  print "size\t" . $lineFit->rSquared() . "\n";
  $lineFit->setData (\@a_plt_time, \@a_plt_domain) or die "Invalid data";
  print "domain\t" . $lineFit->rSquared() . "\n";

  print "With cache:\n";
  @ac_plt_time = values %hash_plt_time_cache;
  @ac_plt_obj = values %hash_plt_obj_cache;
  @ac_plt_tcp = values %hash_plt_tcp_cache;
  @ac_plt_size = values %hash_plt_size_cache;
  @ac_plt_domain = values %hash_plt_domain_cache;
  use Statistics::LineFit;
  $lineFit = Statistics::LineFit->new();
  $lineFit->setData (\@ac_plt_time, \@ac_plt_obj) or die "Invalid data";
  print "obj\t" . $lineFit->rSquared() . "\n";
  $lineFit->setData (\@ac_plt_time, \@ac_plt_tcp) or die "Invalid data";
  print "tcp\t" . $lineFit->rSquared() . "\n";
  $lineFit->setData (\@ac_plt_time, \@ac_plt_size) or die "Invalid data";
  print "size\t" . $lineFit->rSquared() . "\n";
  $lineFit->setData (\@ac_plt_time, \@ac_plt_domain) or die "Invalid data";
  print "domain\t" . $lineFit->rSquared() . "\n";

  # plot 1
  UtilPlot->outputCDF("plot/cache_n.txt", \@plt_time);
  UtilPlot->outputCDF("plot/cache_w.txt", \@plt_time_frac);
  UtilPlot->outputCDF("plot/cache_obj_n.txt", \@plt_obj);
  UtilPlot->outputCDF("plot/cache_obj_w.txt", \@plt_obj_frac);
  UtilPlot->outputCDF("plot/cache_size_n.txt", \@plt_size);
  UtilPlot->outputCDF("plot/cache_size_w.txt", \@plt_size_frac);
  UtilPlot->outputCDF("plot/cache_tcp_n.txt", \@plt_tcp);
  UtilPlot->outputCDF("plot/cache_tcp_w.txt", \@plt_tcp_frac);
  UtilPlot->outputCDF("plot/cache_domain_n.txt", \@plt_domain);
  UtilPlot->outputCDF("plot/cache_domain_w.txt", \@plt_domain_frac);

  # plot ttfb
  UtilPlot->outputCDF("plot/ttfb_c.txt", \@ttfb_c);
  UtilPlot->outputCDF("plot/ttfb_h.txt", \@ttfb_h);
  UtilPlot->outputCDF("plot/ttfb_frac_c.txt", \@ttfb_frac_c);
  UtilPlot->outputCDF("plot/ttfb_frac_h.txt", \@ttfb_frac_h);
  UtilPlot->outputCDF("plot/ttfb_red_num_c.txt", \@ttfb_red_num_c);
  UtilPlot->outputCDF("plot/ttfb_red_num_h.txt", \@ttfb_red_num_h);
  UtilPlot->outputCDF("plot/ttfb_red_frac_c.txt", \@ttfb_red_frac_c);
  UtilPlot->outputCDF("plot/ttfb_red_frac_h.txt", \@ttfb_red_frac_h);
  UtilPlot->outputCDF("plot/ttfb_dns_frac_c.txt", \@ttfb_dns_frac_c);
  UtilPlot->outputCDF("plot/ttfb_dns_frac_h.txt", \@ttfb_dns_frac_h);
  UtilPlot->outputCDF("plot/ttfb_tcp_frac_c.txt", \@ttfb_tcp_frac_c);
  UtilPlot->outputCDF("plot/ttfb_tcp_frac_h.txt", \@ttfb_tcp_frac_h);
  UtilPlot->outputCDF("plot/ttfb_send_frac_c.txt", \@ttfb_send_frac_c);
  UtilPlot->outputCDF("plot/ttfb_send_frac_h.txt", \@ttfb_send_frac_h);
  UtilPlot->outputCDF("plot/ttfb_be_frac_c.txt", \@ttfb_be_frac_c);
  UtilPlot->outputCDF("plot/ttfb_be_frac_h.txt", \@ttfb_be_frac_h);
  UtilPlot->outputCDF("plot/ttfb_recv_frac_c.txt", \@ttfb_recv_frac_c);
  UtilPlot->outputCDF("plot/ttfb_recv_frac_h.txt", \@ttfb_recv_frac_h);
}

sub processMacro {
  my %hash_hars = %{$_[0]};

  my %plts_time = [];
  my %plts_obj = [];
  my %plts_size = [];
  my %plts_domain = [];
  my %plts_tcp = [];

  my %plts_time_ttfb = [];
  my %plts_time_red = [];
  my %plts_time_red_num = [];
  my %plts_time_dns = [];
  my %plts_time_tcp = [];
  my %plts_time_send = [];
  my %plts_time_be = [];
  my %plts_time_recv = [];

  foreach $key (keys %hash_hars) {
    @hars = @{$hash_hars{$key}};

    # eliminate random sites
    $len = @hars;
    if ($len < $num_experiments) {
      next;
    }

    $domain = $key;

    my @tmp_plts;
    my @tmp_plts_obj;
    my @tmp_plts_tcp;
    my @tmp_plts_size;
    my @tmp_plts_domain;
    foreach $har (@hars) {
      $filename = "$path/$har";
      open FH, $filename;
      $str = "";
      while (<FH>) {
        $str .= $_;
      }
      try {
        %h = %{decode_json($str)};
        @pages = @{$h{"log"}{"pages"}};
        %page = %{$pages[0]};
        $plt = int($page{"pageTimings"}{"onLoad"}) / 1000;
        if ($plt > 0) {
          push (@tmp_plts, $plt);

          # get entries
          @entries = @{$h{"log"}{"entries"}};
          %domains = ();
          $plt_obj = 0;
          $plt_tcp = 0;
          $plt_size = 0;
          $plt_domain = 0;
          foreach $entry (@entries) {
            %entry = %{$entry};

            # num of objects
            $plt_obj++;

            # content size
            $size = int($entry{"response"}{"bodySize"});
            $size = ($size > 0) ? $size : 0;
            $plt_size += $size / 1024; # KB

            # num of tcp connections
            $tcp = int($entry{"timings"}{"connect"});
            $tcp = ($tcp > 0) ? $tcp : 0;
            if ($tcp > 0) {
              $plt_tcp++;
            }

            # num of domains
            $d = $entry{"serverIPAddress"};
            $domains{$d} = 1;
          }
          # calculate num of domains
          $plt_domain = scalar keys %domains;
          push (@tmp_plts_obj, $plt_obj);
          push (@tmp_plts_tcp, $plt_tcp);
          push (@tmp_plts_size, $plt_size);
          push (@tmp_plts_domain, $plt_domain);
        }
      } catch {
        print "$domain\n";
        print "$_\n";
      }
    }

    $num = @tmp_plts;

    if ($num > 0) {
      @ori_plts = @tmp_plts;

      @tmp_plts = sort {$a <=> $b} @tmp_plts;
      $plts_time{$domain} = $tmp_plts[0];

      @tmp_plts_obj = sort {$a <=> $b} @tmp_plts_obj;
      $plts_obj{$domain} = $tmp_plts_obj[0];
      @tmp_plts_tcp = sort {$a <=> $b} @tmp_plts_tcp;
      $plts_tcp{$domain} = $tmp_plts_tcp[0];
      @tmp_plts_size = sort {$a <=> $b} @tmp_plts_size;
      $plts_size{$domain} = $tmp_plts_size[0];
      @tmp_plts_domain = sort {$a <=> $b} @tmp_plts_domain;
      $plts_domain{$domain} = $tmp_plts_domain[0];

      # calculate internals with minimum plt
      $i = 0;
      while ($i < $num) {
        if ($ori_plts[$i] == $tmp_plts[0]) {
          my $har = $hars[$i];
          my %hash_internal = %{processInternal($har)};

          $plts_time_ttfb{$domain} = $hash_internal{"ttfb"};
          $plts_time_red{$domain} = $hash_internal{"red"};
          $plts_time_red_num{$domain} = $hash_internal{"red_num"};
          $plts_time_dns{$domain} = $hash_internal{"dns"};
          $plts_time_tcp{$domain} = $hash_internal{"tcp"};
          $plts_time_send{$domain} = $hash_internal{"send"};
          $plts_time_be{$domain} = $hash_internal{"be"};
          $plts_time_recv{$domain} = $hash_internal{"recv"};

          last;
        }
        $i++;
      }

    }
  }
  %hash_ret = (
    "plt", \%plts_time,
    "obj", \%plts_obj,
    "tcp", \%plts_tcp,
    "size", \%plts_size,
    "domain", \%plts_domain,

    "ttfb", \%plts_time_ttfb,
    "ttfb_red", \%plts_time_red,
    "ttfb_red_num", \%plts_time_red_num,
    "ttfb_dns", \%plts_time_dns,
    "ttfb_tcp", \%plts_time_tcp,
    "ttfb_send", \%plts_time_send,
    "ttfb_be", \%plts_time_be,
    "ttfb_recv", \%plts_time_recv,
  );
  return \%hash_ret;
}

##########################################
# process internal
##########################################
sub processInternal {
  my $har = $_[0];
  %hash_internal = ();

  $filename = "$path/$har";
  open FH, $filename;
  $str = "";
  while (<FH>) {
    $str .= $_;
  }
  close FH;

    %h = %{decode_json($str)};
    @pages = @{$h{"log"}{"pages"}};
    %page = %{$pages[0]};
    $plt = int($page{"pageTimings"}{"onLoad"}) / 1000;
    if ($plt > 0) {
      # look at ttfb overhead
      @entries = @{$h{"log"}{"entries"}};

       ################### init params
      # plt
      my $page_stime = 0;
      my $page_etime = 0;

      # redirect
      my $red_num = 0;
      my $red_time = 0;

      # dns
      my $dns_time = 0;

      # tcp
      my $tcp_time = 0;

      # send
      my $send_time = 0;

      # backend
      my $be_time = 0;

      # receive
      my $recv_time = 0;

      $j = 0;
      $cont = 0;
      foreach $entry (@entries) {
        %entry = %{$entry};
        $stime = Util->convertTime($entry{"startedDateTime"});

        ################# per req
        # redirect
        $status = int($entry{"response"}{"status"});
        $red = int($entry{"time"}) / 1000;
        $red = ($status =~ /30?/) ? $red : 0;

        # blocked
        $blocked = int($entry{"timings"}{"blocked"}) / 1000;
        $blocked = ($blocked > 0) ? $blocked : 0;

        # dns
        $dns = int($entry{"timings"}{"dns"}) / 1000;
        $dns = ($dns > 0) ? $dns : 0;

        # tcp setup
        $tcp = int($entry{"timings"}{"connect"}) / 1000;
        $tcp = ($tcp > 0) ? $tcp : 0;

        # send
        $send = int($entry{"timings"}{"send"}) / 1000;
        $send = ($send > 0) ? $send : 0;

        # backend
        $be = int($entry{"timings"}{"wait"}) / 1000;
        $be = ($be > 0) ? $be : 0;

        # receive
        $recv = int($entry{"timings"}{"receive"}) / 1000;
        $recv = ($recv > 0) ? $recv : 0;

        # resource downloading
        if ($cont == 1) {
          # TODO

          next;
        }

        ################ time to first byte
        # redirect
        $red_time += $red;
        if ($red > 0) {
          $red_num++;
        }

        # dns
        $dns_time += $dns;

        # tcp
        $tcp_time += $tcp;

        # send
        $send_time += $send;

        # backend
        $be_time += $be;

        # receive
        $recv_time += $recv;

        if ($j == 0) {
          $page_stime = Util->convertTime($entry{"startedDateTime"});
          $page_ltime = $page_stime + (int($page{"pageTimings"}{"onContentLoad"}) / 1000);
        }
        $status = $entry{"response"}{"status"};
        if ($status =~ /200/) {
          $cont = 1;
          $page_etime = Util->convertTime($entry{"startedDateTime"}) + ($blocked + $dns + $tcp + $send + $be);
        }
        $j++;
      }
    $ttfb = $page_etime - $page_stime;
    #print $har . "\n" . $plt . "\t" . $ttfb . "\t" . $red_time . "\t" . $tcp_time . "\t" . $be_time . "\t" . $recv_time . "\n";
    %hash_internal = (
      "plt", $plt,
      "ttfb", $ttfb,
      "red", $red_time,
      "red_num", $red_num,
      "dns", $dns_time,
      "tcp", $tcp_time,
      "send", $send_time,
      "be", $be_time,
      "recv", $recv_time,
    );
    return \%hash_internal;
  }
}

##########################################
# process https
##########################################
sub processHTTPS {
  @https_size = [];
  %mimetype_num = ();
  %mimetype_size = ();
  $i = 0;
  $non_zero = 0;
  foreach $har (@hars) {
    @arr = split(/\+/, $har);
    $domain = $arr[0];
    if (exists $sites{$arr[0]}) {
      $sites{$arr[0]}++;
      next;
    } else {
      $sites{$arr[0]} = 1;
    }

    $filename = "$path/har$suffix/$har";
    open FH, $filename;

    # get har
    $str = "";
    while ($line = <FH>) {
      $str .= $line;
    }
    %har = %{decode_json($str)};

    # get pages
    @pages = @{$har{"log"}{"pages"}};
    %page = %{$pages[0]};
    $plt = int($page{"pageTimings"}{"onLoad"}) / 1000;
    if ($sites{$domain} == 1) {
      $plt_time[$i] = $plt;
    } elsif ($sites{$domain} == 2) {
      $plt_time_cache[$i] = $plt;
    }

    $hs = 0;
    $cont = 0;
    # get entries
    @entries = @{$har{"log"}{"entries"}};
    foreach $entry (@entries) {
      %entry = %{$entry};
      # 
      if (int($entry{"response"}{"status"}) == 200) {
        $conn = int($entry{"connection"});
        if ($conn == 443) {
          $url = $entry{"request"}{"url"};
          @aurl = split(/\//, $url);
          $num_parts = @aurl;
          if ($num_parts <= 3) {
            print $url . "\n";
          }
        }
      }

      if (int($entry{"connection"}) != 443) {
        next;
      }

      # size of https per page
      $header = int($entry{"response"}{"headersSize"});
      $body = int($entry{"response"}{"bodySize"});
      $hs = $header + $body;

      # mime type
      $mime = $entry{"response"}{"content"}{"mimeType"};
      if (exists $mimetype_num{$mime}) {
        $mimetype_num{$mime}++;
      } else {
        $mimetype_num{$mime} = 1;
      }
      if (exists $mimetype_size{$mime}) {
        $mimetype_size{$mime} += $header + $body;
      } else {
        $mimetype_size{$mime} = $header + $body;
      }
    }

    if ($hs != 0) {
      $non_zero++;
    }
    $http_size[$i] = $hs;
    $i++;
  }
  # categorize mimetype
  %mimetype = Util->calculateMimeType(\%mimetype_num);
  foreach $key (sort {$mimetype{$b} <=> $mimetype{$a}} keys %mimetype) {
    print $key . "\t" . $mimetype{$key} . "\n";
  }
  %mimetype = Util->calculateMimeType(\%mimetype_size);
  foreach $key (sort {$mimetype{$b} <=> $mimetype{$a}} keys %mimetype) {
    print $key . "\t" . ($mimetype{$key} / 1024) . "\n";
  }

  print "# of https: " . $non_zero . "/" . $i . "\n";
  # plot 1
  UtilPlot->outputCDF("plot/https_size.txt", \@http_size);
}
