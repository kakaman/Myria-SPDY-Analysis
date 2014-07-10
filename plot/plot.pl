#!/usr/bin/perl

use GnuplotController;
$prefix_main = "extensive_200pages_controlled_5run_blockdns_pro_";
$suffix_file = "";
$path = "../results";
#@ytics = (0, 0.1, 0.25, 0.5, 0.75, 0.9, 1);
#@ytics = (0, 0.25, 0.5, 0.75, 1);
@ytics = (0, 0.2, 0.4, 0.6, 0.8, 1);
@xtics_1 = (0, 3, 6, 9, 12, 15);
@xtics_2 = (0, 30, 60, 90, 120, 150);
@xtics_3 = (0, 3, 6, 9, 12, 15);
@xtics_4 = (0, 60, 120, 180, 240, 300);
@xtics_5 = (0, 300, 600, 900, 1200, 1500);
@grid = (0, 0);
%prefixes = (
  "_imac", "extensive_cold_hot_5runs_imac_pro_1_",
  "_imac_h", "extensive_cold_hot_5runs_imac_pro_2_",
  "_cold", "extensive_cold_hot_5runs_imac_pro_1_",
  "_hot", "extensive_cold_hot_5runs_imac_pro_2_",
  "_control", "extensive_200pages_controlled_5run_blockdns_pro_",
  "_spdy", "extensive_200pages_spdy_5run_blockdns_pro_",
  "_pagespeed", "extensive_200pages_pagespeed_5run_blockdns_pro_",
  #"_cold", "extensive_200pages_cold_hot_5run_pro_1_",
  #"_hot", "extensive_200pages_cold_hot_5run_pro_2_",
  #"_opendns", "extensive_200pages_cold_hot_opendns_5run_pro_",
  #"_cold2", "extensive_200pages_cold_warm_5run_pro_1_",
  "_cold2", "extensive_200pages_cold_warm_5run_2_pro_1_",
  "_warm", "extensive_200pages_cold_warm_5run_2_pro_2_",
);

foreach $key (keys %prefixes) {
$prefix_main = $prefixes{$key};
$suffix_file = $key;

@data = (
  { # breakdown of overall time (fractions)
    "size" => [0.6, 0.4],
    "lineWidth" => 4,
    "grid" => \@grid,
    "ytics" => \@ytics,
    "xlabel" => "Fractions",
    "ylabel" => "CDF",
    "filename" => "cpa_frac_overall$suffix_file",
    "plot" => {
      $path . "/" . $prefix_main . "frac_time_comp" => [11, "computation"],
      $path . "/" . $prefix_main . "frac_time_download" => [1, "network"],
      #$path . "/" . $prefix_main . "frac_time_ttfb" => [1, "net-before-parsing"],
      #$path . "/" . $prefix_main . "frac_time_block" => [11, "net-block-parsing"],
      #$path . "/" . $prefix_main . "frac_time_after" => [21, "net-post-parsing"],
    },
  },
  { # breakdown of network time (fractions)
    "size" => [0.6, 0.4],
    "lineWidth" => 4,
    "grid" => \@grid,
    "ytics" => \@ytics,
    "xlabel" => "Fractions",
    "ylabel" => "CDF",
    "filename" => "cpa_frac_net$suffix_file",
    "plot" => {
      #$path . "/" . $prefix_main . "frac_time_comp" => [3, "computation"],
      #$path . "/" . $prefix_main . "frac_time_download" => [1, "network-nonblock"],
      $path . "/" . $prefix_main . "frac_time_ttfb" => [1, "pre-parsing"],
      $path . "/" . $prefix_main . "frac_time_block" => [11, "block-parsing"],
      $path . "/" . $prefix_main . "frac_time_after" => [21, "post-parsing"],
    },
  },
  { # breakdown of network time (fractions)
    "size" => [0.6, 0.4],
    "lineWidth" => 4,
    "grid" => \@grid,
    "xrange" => [0, 0.5],
    "ytics" => \@ytics,
    "xlabel" => "Fractions",
    "ylabel" => "CDF",
    "filename" => "cpa_frac_network$suffix_file",
    "plot" => {
      #$path . "/" . $prefix_main . "frac_downloads_blocking" => [21, "send buffer"],
      $path . "/" . $prefix_main . "frac_downloads_dns" => [11, "dns"],
      $path . "/" . $prefix_main . "frac_downloads_conn" => [1, "tcp conn."],
      #$path . "/" . $prefix_main . "frac_downloads_ssl" => [4, "ssl"],
      #$path . "/" . $prefix_main . "frac_downloads_send" => [5, "send"],
      $path . "/" . $prefix_main . "frac_downloads_receiveFirst" => [6, "server roundabout"],
      $path . "/" . $prefix_main . "frac_downloads_receiveLast" => [16, "receive"],
    },
  },
  { # fractions of network time by mime type
    "size" => [0.6, 0.4],
    "lineWidth" => 4,
    "grid" => \@grid,
    "ytics" => \@ytics,
    "xlabel" => "Fractions",
    "ylabel" => "CDF",
    "filename" => "cpa_frac_mime$suffix_file",
    "plot" => {
      $path . "/" . $prefix_main . "frac_time_download_html" => [6, "html"],
      #$path . "/" . $prefix_main . "frac_time_download_css" => [7, "css"],
      $path . "/" . $prefix_main . "frac_time_download_js" => [1, "js"],
      $path . "/" . $prefix_main . "frac_time_download_img" => [16, "img"],
      $path . "/" . $prefix_main . "frac_time_block_css" => [21, "css (block)"],
      $path . "/" . $prefix_main . "frac_time_block_js" => [11, "js (block)"],
    },
  },
  { # breakdown of computational time (fractions)
    "size" => [0.6, 0.4],
    "lineWidth" => 4,
    "grid" => \@grid,
    "ytics" => \@ytics,
    "xlabel" => "Fractions",
    "ylabel" => "CDF",
    "filename" => "cpa_frac_computation$suffix_file",
    "plot" => {
      $path . "/" . $prefix_main . "frac_parses_style" => [16, "CssEvaluation"],
      $path . "/" . $prefix_main . "frac_parses_script" => [6, "JsEvaluation"],
      $path . "/" . $prefix_main . "frac_parses_layout" => [11, "Rendering"],
      #$path . "/" . $prefix_main . "frac_parses_paint" => [4, "Paint"],
      $path . "/" . $prefix_main . "frac_parses_other" => [1, "HtmlParsing"],
      #$path . "/" . $prefix_main . "frac_parses_undefined" => [6, "Other"],
    },
  },
  { # fractions of domains on CP
    "size" => [0.6, 0.4],
    "lineWidth" => 4,
    "grid" => \@grid,
    "ytics" => \@ytics,
    "xlabel" => "Fractions",
    "ylabel" => "CDF",
    "filename" => "cpa_frac_domains_cp$suffix_file",
    "plot" => {
      $path . "/" . $prefix_main . "frac_domains_cp" => [1, " by domains"],
      $path . "/" . $prefix_main . "frac_objs_cp" => [11, " by objects"],
      $path . "/" . $prefix_main . "frac_bytes_cp" => [21, " by bytes"],
    },
  },
);

$c = new GnuplotController(\@data);
$c->run();
}


@xtics_filesize = (0, 1000, 2000, 3000, 4000);
@data = (
  { # spdy
    "size" => [0.4, 0.4],
    "lineWidth" => 4,
    "grid" => \@grid,
    "xrange" => [0, 10],
    "ytics" => \@ytics,
    "xlabel" => "Time (seconds)",
    "ylabel" => "CDF",
    "filename" => "cpa_spdy_abs",
    "plot" => {
      $path . "/" . "extensive_200pages_spdy_5run_blockdns_pro_plt" => [1, "w/ SPDY"],
      $path . "/" . "extensive_200pages_controlled_5run_blockdns_pro_plt" => [11, "w/o SPDY"],
    },
  },
  { # spdy net time - tcp
    "size" => [0.4, 0.4],
    "lineWidth" => 4,
    "grid" => \@grid,
    "xrange" => [0, 100],
    "ytics" => \@ytics,
    #"xtics" => \@xtics_2,
    "xlabel" => "Time (milliseconds)",
    "ylabel" => "CDF",
    "filename" => "cpa_network_compare_spdy",
    "plot" => {
      $path . "/" . "extensive_200pages_spdy_5run_blockdns_pro_downloads_conn" => [1, "w/ spdy"],
      $path . "/" . "extensive_200pages_controlled_5run_blockdns_pro_downloads_conn" => [11, "w/o spdy"],
    },
  },
  { # spdy net time - send
    "size" => [0.4, 0.4],
    "lineWidth" => 4,
    "grid" => \@grid,
    "xrange" => [0, 100],
    "ytics" => \@ytics,
    #"xtics" => \@xtics_2,
    "xlabel" => "Time (milliseconds)",
    "ylabel" => "CDF",
    "filename" => "cpa_network_compare_spdy_1",
    "plot" => {
      $path . "/" . "extensive_200pages_spdy_5run_blockdns_pro_downloads_send" => [1, "w/ spdy"],
      $path . "/" . "extensive_200pages_controlled_5run_blockdns_pro_downloads_send" => [11, "w/o spdy"],
    },
  },
  { # spdy net time - receive first
    "size" => [0.4, 0.4],
    "lineWidth" => 4,
    "grid" => \@grid,
    "xrange" => [0, 300],
    "ytics" => \@ytics,
    #"xtics" => \@xtics_2,
    "xlabel" => "Time (milliseconds)",
    "ylabel" => "CDF",
    "filename" => "cpa_network_compare_spdy_2",
    "plot" => {
      $path . "/" . "extensive_200pages_spdy_5run_blockdns_pro_downloads_receiveFirst" => [1, "w/ spdy"],
      $path . "/" . "extensive_200pages_controlled_5run_blockdns_pro_downloads_receiveFirst" => [11, "w/o spdy"],
    },
  },
  { # fractions of conn for spdy
    "size" => [0.4, 0.4],
    "lineWidth" => 4,
    "grid" => \@grid,
    "ytics" => \@ytics,
    "xlabel" => "Fractions",
    "ylabel" => "CDF",
    "filename" => "cpa_network_compare_conn_cp",
    "plot" => {
      $path . "/" . "extensive_200pages_spdy_5run_blockdns_pro_frac_conn_cp" => [1, "critical path"],
      $path . "/" . "extensive_200pages_spdy_5run_blockdns_pro_frac_conn_all" => [11, "overall"],
    },
  },
  { # mod_pagespeed
    "size" => [0.4, 0.4],
    "lineWidth" => 4,
    "grid" => \@grid,
    "xrange" => [0, 10],
    "ytics" => \@ytics,
    "xlabel" => "Time (seconds)",
    "ylabel" => "CDF",
    "filename" => "cpa_pagespeed_abs",
    "plot" => {
      #$path . "/" . "extensive_200pages_pagespeed_5run_blockdns_pro_plt" => [1, "mps-20ms"],
      #$path . "/" . "extensive_200pages_controlled_5run_blockdns_pro_plt" => [11, "no-mps-20ms"],
      $path . "/" . "extensive_200pages_pagespeed_5run_2_pro_plt" => [1, "w/ pagespeed"],
      $path . "/" . "extensive_200pages_controlled_5run_2_pro_plt" => [11, "w/o pagespeed"],
    },
  },
  { # mod_pagespeed net time
    "size" => [0.4, 0.4],
    "lineWidth" => 4,
    "grid" => \@grid,
    "xrange" => [0, 500],
    "ytics" => \@ytics,
    #"xtics" => \@xtics_4,
    "xlabel" => "Time (milliseconds)",
    "ylabel" => "CDF",
    "filename" => "cpa_network_compare_pagespeed",
    "plot" => {
      $path . "/" . "extensive_200pages_pagespeed_5run_2_pro_downloads_receiveLast" => [1, "w/ pagespeed"],
      $path . "/" . "extensive_200pages_controlled_5run_2_pro_downloads_receiveLast" => [11, "w/o pagespeed"],
    },
  },
  { # mod_pagespeed bytes
    "size" => [0.4, 0.4],
    "lineWidth" => 4,
    "grid" => \@grid,
    "xrange" => [0, 200000],
    "ytics" => \@ytics,
    #"xtics" => \@xtics_4,
    "xlabel" => "Bytes",
    "ylabel" => "CDF",
    "filename" => "cpa_network_compare_pagespeed_1",
    "plot" => {
      $path . "/" . "extensive_200pages_pagespeed_5run_2_pro_num_bytes_cp" => [1, "w/ pagespeed"],
      $path . "/" . "extensive_200pages_controlled_5run_2_pro_num_bytes_cp" => [11, "w/o pagespeed"],
    },
  },
  { # mod_pagespeed all
    "size" => [0.4, 0.4],
    "lineWidth" => 4,
    "grid" => \@grid,
    "xrange" => [0, 100000],
    "ytics" => \@ytics,
    #"xtics" => \@xtics_4,
    "xlabel" => "Time (milliseconds)",
    "ylabel" => "CDF",
    "filename" => "cpa_network_compare_pagespeed_2",
    "plot" => {
      $path . "/" . "extensive_200pages_pagespeed_5run_2_pro_num_bytes_all" => [1, "w/ pagespeed"],
      $path . "/" . "extensive_200pages_controlled_5run_2_pro_num_bytes_all" => [11, "w/o pagespeed"],
    },
  },
  { # hot/cold abs
    "size" => [0.4, 0.4],
    "lineWidth" => 4,
    "grid" => \@grid,
    "xrange" => [0, 20],
    "ytics" => \@ytics,
    "xlabel" => "Time (seconds)",
    "ylabel" => "CDF",
    "filename" => "cpa_cold_hot_abs",
    "plot" => {
      $path . "/" . "extensive_cold_warm_5runs_imac_pro_2_plt" => [21, "warm"],
      #$path . "/" . "extensive_cold_warm_5runs_imac_pro_1_plt" => [6, "warmw"],
      $path . "/" . "extensive_cold_hot_5runs_imac_pro_2_plt" => [11, "hot"],
      $path . "/" . "extensive_cold_hot_5runs_imac_pro_1_plt" => [1, "cold"],
    },
  },
  { # hot/cold net time
    "size" => [0.4, 0.4],
    "lineWidth" => 4,
    "grid" => \@grid,
    "xrange" => [0, 1500],
    "ytics" => \@ytics,
    "xtics" => \@xtics_5,
    "xlabel" => "Time (milliseconds)",
    "ylabel" => "CDF",
    "filename" => "cpa_network_compare_cold_hot",
    "plot" => {
      $path . "/" . "extensive_cold_hot_5runs_imac_pro_1_downloads_dns" => [1, "dns w/ cold"],
      $path . "/" . "extensive_cold_hot_5runs_imac_pro_1_downloads_conn" => [6, "conn w/ cold"],
      $path . "/" . "extensive_cold_hot_5runs_imac_pro_2_downloads_dns" => [11, "dns w/ hot"],
      $path . "/" . "extensive_cold_hot_5runs_imac_pro_2_downloads_conn" => [16, "conn w/ hot"],
      $path . "/" . "extensive_cold_warm_5runs_imac_pro_2_downloads_dns" => [21, "dns w/ warm"],
      $path . "/" . "extensive_cold_warm_5runs_imac_pro_2_downloads_conn" => [26, "conn w/ warm"],
    },
  },
  { # hot/cold comp
    "size" => [0.4, 0.4],
    "lineWidth" => 4,
    "grid" => \@grid,
    "xrange" => [0, 5000],
    "ytics" => \@ytics,
    #"xtics" => \@xtics_5,
    "xlabel" => "Time (milliseconds)",
    "ylabel" => "CDF",
    "filename" => "cpa_network_compare_cold_hot_comp",
    "plot" => {
      $path . "/" . "extensive_cold_hot_5runs_imac_pro_1_time_comp" => [1, "comp. w/ cold"],
      $path . "/" . "extensive_cold_hot_5runs_imac_pro_1_parses_layout" => [6, "layout w/ cold"],
      $path . "/" . "extensive_cold_hot_5runs_imac_pro_2_time_comp" => [11, "comp. w/ hot"],
      $path . "/" . "extensive_cold_hot_5runs_imac_pro_2_parses_layout" => [16, "layout w/ hot"],
      $path . "/" . "extensive_cold_warm_5runs_imac_pro_2_time_comp" => [21, "comp. w/ warm"],
      $path . "/" . "extensive_cold_warm_5runs_imac_pro_2_parses_layout" => [26, "layout w/ warm"],
    },
  },
  { # hot/cold evaluate WProf
    "size" => [0.4, 0.4],
    "lineWidth" => 4,
    "grid" => \@grid,
    "xrange" => [0, 1],
    "ytics" => \@ytics,
    #"xtics" => \@xtics_5,
    "xlabel" => "Fractions",
    "ylabel" => "CDF",
    "filename" => "eval_cold_hot_cp",
    "plot" => {
      $path . "/" . "extensive_cold_hot_5runs_imac_pro_2_frac_objs_cp" => [1, "objs-cp"],
      $path . "/" . "extensive_cold_hot_5runs_imac_pro_2_frac_objs_all" => [11, "objs-all"],
      #$path . "/" . "extensive_cold_warm_5runs_imac_pro_2_frac_objs_cp" => [6, "objs-cp"],
      #$path . "/" . "extensive_cold_warm_5runs_imac_pro_2_frac_objs_all" => [16, "objs-all"],
    },
  },
  { # perf evaluation of file size
    "size" => [0.4, 0.4],
    "lineWidth" => 4,
    "grid" => \@grid,
    "xrange" => [0, 4000],
    "ytics" => \@ytics,
    "xtics" => \@xtics_filesize,
    "xlabel" => "Log file size (KB)",
    "ylabel" => "CDF",
    "filename" => "eval_filesize",
    "plot" => {
      $path . "/" . "eval_filesize" => [1, ""],
    },
  },
  { # perf evaluation
    "size" => [0.4, 0.4],
    "lineWidth" => 4,
    "grid" => \@grid,
    "xrange" => [0, 20],
    "ytics" => \@ytics,
    "xlabel" => "Time (seconds)",
    "ylabel" => "CDF",
    "filename" => "eval_perf_abs",
    "plot" => {
      $path . "/" . "eval_on_2" => [1, "WProf on"],
      $path . "/" . "eval_off_2" => [11, "WProf off"],
    },
  },
  { # perf evaluation
    "size" => [0.6, 0.4],
    "lineWidth" => 4,
    "grid" => \@grid,
    "xrange" => [0, 15],
    "ytics" => \@ytics,
    "xtics" => \@xtics_1,
    "xlabel" => "Page load metrics (seconds)",
    "ylabel" => "CDF",
    "filename" => "plt_random_top",
    "plot" => {
      $path . "/" . "extensive_200pages_cold_hot_5run_pro_1_DOMLoad" => [1, "top 200"],
      $path . "/" . "extensive_200pages_random_cold_5run_pro_DOMLoad" => [16, "random 200"],
    },
  },
  { # perf evaluation
    "size" => [0.6, 0.4],
    "lineWidth" => 4,
    "grid" => \@grid,
    "xrange" => [0, 15],
    "ytics" => \@ytics,
    "xtics" => \@xtics_1,
    "xlabel" => "Page load metrics (seconds)",
    "ylabel" => "CDF",
    "filename" => "plt",
    "plot" => {
      $path . "/" . "extensive_200pages_cold_hot_5run_pro_1_DOMLoad" => [1, "DOMLoaded"],
      $path . "/" . "extensive_200pages_cold_hot_5run_pro_1_HTMLParse" => [16, "HTMLParsed"],
    },
  },
  { # perf evaluation
    "size" => [0.6, 0.4],
    "lineWidth" => 4,
    "grid" => \@grid,
    "xrange" => [0, 2],
    "ytics" => \@ytics,
    "xlabel" => "Fractions of time",
    "ylabel" => "CDF",
    "filename" => "eval_perf_frac",
    "plot" => {
      $path . "/" . "eval_frac_2" => [1, "on v.s. off"],
    },
  },
);

$c = new GnuplotController(\@data);
$c->run();
