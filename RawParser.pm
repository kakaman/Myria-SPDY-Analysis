#!/usr/bin/perl

package RawParser;

use JSON;
use UtilConfig;
use Dependency;
#use Error qw(:try);
#use Try::Tiny;

# RawParser constructor
# @param filename of the har file
#
sub new {
  my $class = shift;
  my $config = UtilConfig->getInstance()->getConfig();

  my $self = {
    _filename => $_[0],
    _dataPath => $_[1],
    _tempPath => $_[2],
    _switch => $_[3],
    _dep => $_[4],
    _content => '',

    _config => $config,

    _resources => undef,
    _objecthashes => undef,
    _objects => undef,
    _comps => undef,
    _hols => undef,
    _matchedCSSAndUrls => undef,
    _preloads => undef,
    _pageStart => undef,
    _pageEnd => undef,

    _isContentAvailable => 0,
    _isPageAvailable => 0,
    _isEntriesAvailable => 0,
  };
  bless $self, $class;

  # read content from file
  $self->readFromFile();

  $self->parse();

  $self->genIntermediaries();

  return $self;
}

# Read from file, called by constructor
#
sub readFromFile {
  my ($self, $filename) = @_;

  # calculate domain from filename
  my @temp = split(/\//, $self->{_filename});
  my $num_temp = @temp;
  $temp1 = $temp[$num_temp - 1];
  @temp = split(/\+/, $temp1);
  $num_temp = @temp;
  $self->{_domain} = $temp[0];

  $file = $self->{_dataPath} . "/" . $self->{_filename};
  open FH, $file;
  my $str = '';
  while (<FH>) {
    $str .= $_;
  }
  close FH;
  $self->{_content} = $str;
}

# Parse the har file, called by constructor
#
sub parse {
  my ($self, $content) = @_;

  # no need to parse again
  if ($self->{_isEntriesAvailable}) {
    return;
  }

  # cannot parse b/c of lack of input
  if (!$self->{_content}) {
    return;
  }

  $self->{_isContentAvailable} = 1;
  @a = split(/\-/, $self->{_filename});
  my $filename = $a[0];

  # parse each line
  my @lines = split(/\n/, $self->{_content}); 

  # results
  my @resources;
  my %objecthashes;
  my @objects;
  my @comps;
  my @hols;
  my @matchedCSSAndUrls;
  my @preloads;
  my @resourceinfos;
  my $start = undef;
  my $end = undef;
  my $pageResource = undef;
  my $pageUrl = undef;
  my $pageParseStart = undef;
  my $pageParseEnd = undef;

  # temp obj
  my %resource;
  my @chunks;
  my $scriptStartCode;

  foreach my $line (@lines) {
    #$line =~ s/'/"/g;
    my %h = %{decode_json($line)};

    # output resource
    $chunks = @chunks;
    if (!$h{"ReceivedChunk"} and $chunks > 0) {
      # add chunks to resource
      $resource{"chunks"} = \@chunks;

      # push resource to arr
      if ($pageUrl) {
        push (@resources, encode_json(\%resource));
      }
      if (!$pageResource) {
        $pageResource = encode_json(\%resource);
      }
      
      # clear
      %resource = "";
      @chunks = ();
    }

    # switch ... case ...
    if ($h{"Resource"}) {
      %resource = %{$h{"Resource"}};
      if ($resource{"sentTime"} == -1) {
	$resource{"sentTime"} = $resource{"requestTime"};
	#print "sentTime " . $resource{"sentTime"} . "\n";
      }
      @chunks = ();
      if (!$pageUrl) {
        $pageUrlTemp = $resource{"url"};
        @a = split(/\/\//, $pageUrlTemp);
        $pageUrlTemp = $a[1];
        $pageUrlTemp =~ s/\//\_/g;
        if ($filename eq $pageUrlTemp) {
          $pageUrl = $pageUrlTemp;
          $start = $resource{"sentTime"};
	  if (!$start) {
            $start = $resource{"requestTime"};
	  }
        }
      }
    } elsif ($h{"ReceivedChunk"}) {
      if ($pageUrl) {
        push(@chunks, $h{"ReceivedChunk"});
        $resource{"receivedTime"} = $h{"ReceivedChunk"}{"receivedTime"};
      }
    } elsif ($h{"DOMLoad"}) {
      $end = $h{"DOMLoad"};
    } elsif ($h{"ObjectHash"}) {
      %obj = %{$h{"ObjectHash"}};
      @a = split(/\/\//, $obj{"doc"});
      $obj_doc = $a[1];
      $obj_doc =~ s/\//\_/g;
      if ($obj_doc eq $pageUrl) {
        if (!$pageParseStart) {
          $pageParseStart = $obj{"time"};
        }
        $pageParseEnd = $obj{"time"};
      }

      $code = $h{"ObjectHash"}{"code"};

      # for script element, set the start tag for an script end tag
      if ($obj{"tagName"} eq "script") {
        if ($obj{"isStartTag"} == 1) {
          $scriptStartCode = $obj{"code"};
        } else {
          $h{"ObjectHash"}{"scriptStartCode"} = $scriptStartCode;
        }
      }

      $objecthashes{$code} = encode_json($h{"ObjectHash"});
      push(@objects, encode_json($h{"ObjectHash"}));
    } elsif ($h{"Computation"}) {
      if ($h{"Computation"}{"endTime"} > -1) {  # If endtime exists
        push(@comps, encode_json($h{"Computation"}));
      }
    } elsif ($h{"HOL"}) {
      push(@hols, encode_json($h{"HOL"}));
    } elsif ($h{"matchedCSSAndUrl"}) {
      push(@matchedCSSAndUrls, encode_json($h{"matchedCSSAndUrl"}));
    } elsif ($h{"Preload"}) {
      push(@preloads, encode_json($h{"Preload"}));
    } elsif ($h{"ResourceInfoChrome"}) {
      push(@resourceinfos, encode_json($h{"ResourceInfoChrome"}));
    } else {
      if ($self->{_dep}) {
        print "you forgot: " . encode_json(\%h) . "\n";
      }
    }
  }

  # set to variable
  $self->{_resources} = \@resources;
  $self->{_objecthashes} = \%objecthashes;
  $self->{_objects} = \@objects;
  $self->{_comps} = \@comps;
  $self->{_hols} = \@hols;
  $self->{_matchedCSSAndUrls} = \@matchedCSSAndUrls;
  $self->{_preloads} = \@preloads;
  $self->{_resourceinfos} = \@resourceinfos;

  $self->{_pageStart} = $start;
  $self->{_pageEnd} = $end;
  if (!$self->{_dep}) {
    open FF, ">>ttt";
    print FF $self->{_filename} . "\t" . $start . "\t" . $end . "\n";
    close FF;
  }


  $self->{_pageResource} = $pageResource;
  $self->{_pageUrl} = $pageUrl;
  $self->{_pageParseStart} = $pageParseStart;
  $self->{_pageParseEnd} = $pageParseEnd;
}

# Read from file, called by constructor
#
sub genIntermediaries {
  my ($self, $pageStart, $pageEnd, $pageParseStart, $pageParseEnd, $resources, $objecthashes, $comps, $hols) = @_;

  if (!$self->{_pageUrl}) {
    return;
  }

  # open file
  #$file = $self->{_config}->{"TempPath"} . $self->{_filename};
if ($self->{_dep}) {
  $file = $self->{_tempPath} . "/" . $self->{_filename};
  open FP, ">$file";
}

  #
  $ttfb = 1000 * ($self->{_pageParseStart} - $self->{_pageStart});
  $parseEnd = 1000 * ($self->{_pageParseEnd} - $self->{_pageParseStart});
  $load = 1000 * ($self->{_pageEnd} - $self->{_pageParseEnd});

  $DOMload = $self->{_pageEnd} - $self->{_pageStart};
  $HTMLParse = $self->{_pageParseEnd} - $self->{_pageStart};
  $self->{_load} = $DOMload;

if (1) {
  print "load:\t" . $DOMload . "\n";
  #print "HTMLParse:\t" . $HTMLParse . "\n";
  #print "TTFB:\t" . $ttfb . "\n";
  #print "Parse:\t" . $parseEnd . "\n";
  #print "PostParse:\t" . $load . "\n";
}

if ($self->{_dep}) {
  print FP "load:\t" . $DOMload . "\n";
  print FP "HTMLParse:\t" . $HTMLParse . "\n";
  print FP "TTFB:\t" . $ttfb . "\n";
  print FP "Parse:\t" . $parseEnd . "\n";
  print FP "PostParse:\t" . $load . "\n";
}

if (0) {
  print "load:\t" . $DOMload . "\n";
  print "HTMLParse:\t" . $HTMLParse . "\n";
}

if ($self->{_dep}) {
  # extract dependency
  $dep = new Dependency($self, $self->{_pageEnd});
  #$dep = new Dependency($self, $self->{_pageParseEnd});
  %ret = %{$dep->process()};
  print FP "level:\t" . $ret{"level"} . "\n";
  print FP "time_download:\t" . $ret{"time_download"} . "\n";
  print FP "time_comp:\t" . $ret{"time_comp"} . "\n";
  print FP "time_block:\t" . $ret{"time_block"} . "\n";
  print FP "whatif_matrix:\t" . $ret{"whatif_matrix"} . "\n";

if (1) {
  print "time_download:\t" . $ret{"time_download"} . "\n";
  print "time_comp:\t" . $ret{"time_comp"} . "\n";
  print "time_block:\t" . $ret{"time_block"} . "\n";
}

  print FP "download_blocking:\t" . $ret{"download_blocking"} . "\n";
  print FP "download_proxy:\t" . $ret{"download_proxy"} . "\n";
  print FP "download_dns:\t" . $ret{"download_dns"} . "\n";
  print FP "download_conn:\t" . $ret{"download_conn"} . "\n";
  print FP "download_ssl:\t" . $ret{"download_ssl"} . "\n";
  print FP "download_send:\t" . $ret{"download_send"} . "\n";
  print FP "download_receiveFirst:\t" . $ret{"download_receiveFirst"} . "\n";
  print FP "download_receiveLast:\t" . $ret{"download_receiveLast"} . "\n";
  print FP "parse_style:\t" . $ret{"parse_style"} . "\n";
  print FP "parse_script:\t" . $ret{"parse_script"} . "\n";
  print FP "parse_layout:\t" . $ret{"parse_layout"} . "\n";
  print FP "parse_paint:\t" . $ret{"parse_paint"} . "\n";
  print FP "parse_other:\t" . $ret{"parse_other"} . "\n";
  print FP "parse_undefined:\t" . $ret{"parse_undefined"} . "\n";
  print FP "dep_D2E:\t" . $ret{"dep_D2E"} . "\n";
  print FP "dep_E2D_html:\t" . $ret{"dep_E2D_html"} . "\n";
  print FP "dep_E2D_css:\t" . $ret{"dep_E2D_css"} . "\n";
  print FP "dep_E2D_js:\t" . $ret{"dep_E2D_js"} . "\n";
  print FP "dep_E2D_timer:\t" . $ret{"dep_E2D_timer"} . "\n";
  print FP "dep_RFB:\t" . $ret{"dep_RFB"} . "\n";
  print FP "dep_HOL_css:\t" . $ret{"dep_HOL_css"} . "\n";
  print FP "dep_HOL_js:\t" . $ret{"dep_HOL_js"} . "\n";

  print FP "time_download_html:\t" . $ret{"time_download_html"} . "\n";
  print FP "time_download_css:\t" . $ret{"time_download_css"} . "\n";
  print FP "time_download_js:\t" . $ret{"time_download_js"} . "\n";
  print FP "time_download_img:\t" . $ret{"time_download_img"} . "\n";
  print FP "time_download_o:\t" . $ret{"time_download_o"} . "\n";
  print FP "time_block_css:\t" . $ret{"time_block_css"} . "\n";
  print FP "time_block_js:\t" . $ret{"time_block_js"} . "\n";
  print FP "time_ttfb:\t" . $ret{"time_ttfb"} . "\n";
  print FP "num_domains_cp:\t" . $ret{"num_domains_cp"} . "\n";
  print FP "num_domains_all:\t" . $ret{"num_domains_all"} . "\n";
  print FP "text_domains_cp:\t" . $ret{"text_domains_cp"} . "\n";
  print FP "text_domains_all:\t" . $ret{"text_domains_all"} . "\n";
  print FP "num_bytes_cp:\t" . $ret{"num_bytes_cp"} . "\n";
  print FP "num_bytes_all:\t" . $ret{"num_bytes_all"} . "\n";
  print FP "num_send_cp:\t" . $ret{"num_send_cp"} . "\n";
  print FP "num_send_all:\t" . $ret{"num_send_all"} . "\n";
  print FP "num_conn_cp:\t" . $ret{"num_conn_cp"} . "\n";
  print FP "num_conn_all:\t" . $ret{"num_conn_all"} . "\n";
  print FP "num_objs_cp:\t" . $ret{"num_objs_cp"} . "\n";
  print FP "num_objs_all:\t" . $ret{"num_objs_all"} . "\n";
  print FP "text_domain_tcp_net_cp:\t" . $ret{"text_domain_tcp_net_cp"} . "\n";
  print FP "text_domain_tcp_net_all:\t" . $ret{"text_domain_tcp_net_all"} . "\n";
  print FP "act_timings:\t" . $ret{"act_timings"} . "\n";

if (0) {
  print "download_blocking:\t" . $ret{"download_blocking"} . "\n";
  print "download_proxy:\t" . $ret{"download_proxy"} . "\n";
  print "download_dns:\t" . $ret{"download_dns"} . "\n";
  print "download_conn:\t" . $ret{"download_conn"} . "\n";
  print "download_ssl:\t" . $ret{"download_ssl"} . "\n";
  print "download_send:\t" . $ret{"download_send"} . "\n";
  print "download_receiveFirst:\t" . $ret{"download_receiveFirst"} . "\n";
  print "download_receiveLast:\t" . $ret{"download_receiveLast"} . "\n";
  print "parse_style:\t" . $ret{"parse_style"} . "\n";
  print "parse_script:\t" . $ret{"parse_script"} . "\n";
  print "parse_layout:\t" . $ret{"parse_layout"} . "\n";
  print "parse_paint:\t" . $ret{"parse_paint"} . "\n";
  print "parse_other:\t" . $ret{"parse_other"} . "\n";
  print "parse_undefined:\t" . $ret{"parse_undefined"} . "\n";
  print "num_domains_cp:\t" . $ret{"num_domains_cp"} . "\n";
  print "num_domains_all:\t" . $ret{"num_domains_all"} . "\n";
  print "num_objs_cp:\t" . $ret{"num_objs_cp"} . "\n";
  print "num_objs_all:\t" . $ret{"num_objs_all"} . "\n";
}
if (1) {
  print "dep_D2E:\t" . $ret{"dep_D2E"} . "\n";
  print "dep_E2D_html:\t" . $ret{"dep_E2D_html"} . "\n";
  print "dep_E2D_css:\t" . $ret{"dep_E2D_css"} . "\n";
  print "dep_E2D_js:\t" . $ret{"dep_E2D_js"} . "\n";
  print "dep_E2D_timer:\t" . $ret{"dep_E2D_timer"} . "\n";
  print "dep_RFB:\t" . $ret{"dep_RFB"} . "\n";
  print "dep_HOL_css:\t" . $ret{"dep_HOL_css"} . "\n";
  print "dep_HOL_js:\t" . $ret{"dep_HOL_js"} . "\n";
}
  close FP;
}
}

# get page load time
# @return float: page load time in seconds
#
sub getResources {
  my ($self, $resources) = @_;
  return $self->{_resources};
}

sub setResources {
  my ($self, $resources) = @_;
  $self->{_resources} = $_[1];
}

sub getResourceinfos {
  my ($self, $resourceinfos) = @_;
  return $self->{_resourceinfos};
}

sub getObjecthashes {
  my ($self, $objecthashes) = @_;
  return $self->{_objecthashes};
}

sub getObjects {
  my ($self, $objects) = @_;
  return $self->{_objects};
}

sub getComps {
  my ($self, $comps) = @_;
  return $self->{_comps};
}

sub setComps {
  my ($self, $comps) = @_;
  $self->{_comps} = $_[1];
}

sub getHols {
  my ($self, $hols) = @_;
  return $self->{_hols};
}

sub getMatchedCSSAndUrls {
  my ($self, $matchedCSSAndUrls) = @_;
  return $self->{_matchedCSSAndUrls};
}

sub getPreloads {
  my ($self, $preloads) = @_;
  return $self->{_preloads};
}

sub getPageStart {
  my ($self, $pageStart) = @_;
  return $self->{_pageStart};
}

sub getPageParseEnd {
  my ($self, $pageEnd) = @_;

  return $self->{_pageParseEnd};
}

sub getPageEnd {
  my ($self, $pageEnd) = @_;

  return $self->{_pageEnd};
}

sub getLoad {
  my ($self, $pageLoad) = @_;

  return $self->{_load};
}

sub getPageUrl {
  my ($self, $pageUrl) = @_;

  return $self->{_pageUrl};
}

1;

