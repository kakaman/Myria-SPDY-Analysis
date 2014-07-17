#!/usr/bin/perl
# ------------------------------------------------------
# This file processes the har data and output to the
# intermediaries. 
# ------------------------------------------------------

package Dependency;
# Creates a Dependency package

use JSON;
use Data::Dumper;

# creates the self object?
# The self is a table with multiple columns and rows
# Entire code creates one table: self

sub new {
  my $class = shift;
  my $config = UtilConfig->getInstance()->getConfig();

  if ($config->{"ProgressInfo"} eq "on") {
    print "processing...\n";
  }

  my $self = {
    _info => $_[0],
    _load => $_[1],
    _config => $config,
    _parses => undef,
  };
  bless $self, $class;

  return $self;
}
# Dependency graph: Name, Objs, deps, Start activity, Load activity
# self: comps, objects, preloads, resource info, url, 
# Dependencies:
# Comp: id, type, s_time, e_time, 
# Dep: id, a1, a2, time
# Nodes:
# E2D: 
# Obj: id, url, when_comp_start, download. comps
# Download: type, s_time, id


sub process { # Subroutine that processes the information
  my ($self, $info) = @_; # Creates the "container" that houses the information used in the dependency graph

  $info = $self->{_info};
  $self->{_load} = 1000 * ($self->{_load} - $info->getPageStart());

  $url = $info->getPageUrl(); # Gets url 
  $pageStart = $info->getPageStart(); 
  $pageEnd = $info->getPageEnd();
  print "pageUrl: " . $url , "\n";
  print "pageStart: " . $pageStart , "\n";

  @comps = @{$info->getComps()}; # comps?
  @objects = @{$info->getObjects()}; # Number of objects in the page
  %objecthashes = %{$info->getObjecthashes()};

  @hols = @{$info->getHols()};
  @mcaus = @{$info->getMatchedCSSAndUrls()};
  @preloads = @{$info->getPreloads()};
  @resourceinfos = @{$info->getResourceinfos()};

  ####################################
  # add obj_id to resources
  $self->addId2Resources();
  @resources = @{$info->getResources()};

  ####################################
  # Get parses from objects and objecthashes
  @parses = @{$self->constructParses()};
  $self->{_parses} = \@parses;

  ####################################
  # add obj_id to comps
  # add downloads the comps depend on (D2E)
  $self->addIdAndD2E2Comps();
  @comps = @{$info->getComps()};

  ####################################
  # add comps to parses
  $self->addComps2Parses();
  @parses = @{$self->{_parses}};
  @comps_post_n = @{$self->{_comps_post_n}};
  @comps_post_l = @{$self->{_comps_post_l}};

  ####################################
  # add HOL/FRB dependencies
  $self->addHolDependencies();
  @parses = @{$self->{_parses}};

  ####################################
  # add E2D dependencies
  # including preloading and css->img
  $self->addE2DDependencies();
  @resources = @{$info->getResources()};

  ####################################    What are these nodes that are used here???
  # add resources to nodes
  my @nodes;
  foreach $resource (@resources) {
    %r = %{decode_json($resource)};
    #print $r{"E2D"} . "\n";
    if ($r{"E2D"}) {
      #print "ye: " . $r{"url"} . "\n";
    } else {
      print "noE2D: " . $r{"url"} . "\n";
    }
    push(@nodes, $resource);
  }

  ####################################
  # [new] Generate dependency graph
  $self->generateDependencyGraph(); # Creates a dependency graph

  ####################################
  # what-if analysis
if (0) {
  $whatif_matrix = $self->whatIfAnalysis();
}

  ####################################
  # critical path analysis
  $ret = $self->criticalPathAnalysis(); # Calls on the method created later.
  %ret = %{$ret};
  $ret{"whatif_matrix"} = $whatif_matrix;

  return \%ret;
}

# Construct parses from objects
sub constructParses {
  my ($self, $info) = @_;
  $info = $self->{_info};
  $pageStart = $info->getPageStart();
  @objects = @{$info->getObjects()};
  @resources = @{$info->getResources()};

  my @parses;
  my %parse;
  my %parseUrl;
  my %docs;
  my $i = 0;
  foreach $object (@objects) {
    %object = %{decode_json($object)};
    #print $object . "\n";

    $docUrl = $object{"doc"};
    $object{"time"} = ($object{"time"} - $pageStart) * 1000;
    $object = encode_json(\%object);

    if ($docs{$docUrl}) {
      $parse{"end"} = $object{"time"};
      $parse{"last_code"} = $object{"code"};

      # objs array
      @objs = ();
      if ($parse{"objects"}) {
        @objs = @{decode_json($parse{"objects"})};
      }
      push(@objs, $object);
      $parse{"objects"} = encode_json(\@objs);

      # objs hash
      %objs_hash = ();
      if ($parse{"objects_hash"}) {
        %objs_hash = %{decode_json($parse{"objects_hash"})}; # Hashes the objects
      }
      $objs_hash{$object{"code"}} = $object;
      $parse{"objects_hash"} = encode_json(\%objs_hash);

      # objs with urls
      if ($object{"url"} ne "(null)") {
        @objsUrl = ();
        if ($parse{"objectsUrl"}) {
          #print $parse{"objects"} . "\n";
          @objsUrl = @{decode_json($parse{"objectsUrl"})};
        }
        push(@objsUrl, $object);
        $parse{"objectsUrl"} = encode_json(\@objsUrl);
      }

      next;
    }

    # push to old
    if ($parse{"url"}) {
      push(@parses, encode_json(\%parse));
    }

    # create a new parse
    # A parse is a type of object that has url, starttime, endtime, lastcode, and its id
    $docs{$docUrl} = 1;
    %parse = ();
    $parse{"url"} = $docUrl;
    $parse{"start"} = $object{"time"};
    $parse{"end"} = $object{"time"};
    $parse{"last_code"} = $object{"code"};
    $parse{"obj_id"} = "parse_" . $i;

    # objs array
    @objs = ();
    push(@objs, $object);
    $parse{"objects"} = encode_json(\@objs);

    # objs hash
    %objs_hash = ();
    $objs_hash{$object{"code"}} = $object;
    $parse{"objects_hash"} = encode_json(\%objs_hash);

    # objs with url
    if ($object{"url"} ne "(null)") {
      #print $object . "\n";
      @objsUrl = ();
      push(@objsUrl, $object);
      $parse{"objectsUrl"} = encode_json(\@objsUrl);
    }

    # parse has url
    foreach $resource (@resources) {
      %resource = %{decode_json($resource)};
      if ($parse{"url"} eq $resource{"url"}) {
        $parse{"critical"} = $resource{"obj_id"};
        $parse{"critical_time"} = $resource{"receivedTime"};
        my $t = ($parse{"start"} < $resource{"receivedTime"}) ? $parse{"start"} : $resource{"receivedTime"};
        my %pr = (
          "id", $resource{"obj_id"},
          "at", $t,
          "rt", $t - $resource{"sentTime"},
          "rs", "data",
        );

        #print $parse{"url"} . " " . $resource{"url"} . "\n";
        # push to prev
        my @prev = ();
        if ($parse{"prev"}) {
          my @prev = @{decode_json($parse{"prev"})};
        }
        push(@prev, encode_json(\%pr));
        $parse{"prev"} = encode_json(\@prev);
        #print $parse{"prev"} . "\n";

        last;
      }
    }
    ++$i;
  }

  # push to old
  if ($parse{"url"}) {
    push(@parses, encode_json(\%parse));
  }

  return \@parses;
}

# Add obj_id to resources 
# Create a graph that maps the resource table with the object id table
sub addId2Resources {
  my ($self, $info) = @_;
  $info = $self->{_info};
  $pageStart = $info->getPageStart();
  @resources = @{$info->getResources()};

  my $i = 0;
  foreach $resource (@resources) {
    %resource = %{decode_json($resource)};
    $resource{"obj_id"} = "download_" . $i;
    $resource{"sentTime"} = ($resource{"sentTime"} + 0.0 - $pageStart) * 1000;
    $resource{"requestTime"} = ($resource{"requestTime"} + 0.0 - $pageStart) * 1000;
    $resource{"receivedTime"} = ($resource{"receivedTime"} + 0.0 - $pageStart) * 1000;

    $resource{"blocking"} = $resource{"requestTime"} - $resource{"sentTime"};
    $resource{"proxy"} = 0;
    $resource{"dns"} = 0;
    $resource{"conn"} = 0;
    $resource{"ssl"} = 0;
    $resource{"send"} = 0;
    $resource{"receiveFirst"} = 0;
    $resource{"receiveLast"} = 0;

    $curr = 0;
    if ($resource{"proxyEnd"} > 0) {
      $resource{"proxy"} = $resource{"proxyEnd"} - $curr;
      $curr = $resource{"proxyEnd"};
    }
    if ($resource{"dnsEnd"} > 0) {
      #$resource{"dns"} = $resource{"dnsEnd"} - $curr;
      $resource{"dns"} = $resource{"dnsEnd"} - $resource{"dnsStart"};
      $curr = $resource{"dnsEnd"};
    }
    if ($resource{"sslEnd"} > 0) {
      $resource{"ssl"} = $resource{"sslEnd"} - $curr;
      $curr = $resource{"sslEnd"};
    }
    if ($resource{"connectEnd"} > 0) {
      $resource{"conn"} = $resource{"connectEnd"} - $curr;
      $curr = $resource{"connectEnd"};
    }
    if ($resource{"sendEnd"} > 0) {
      $resource{"send"} = $resource{"sendEnd"} - $curr;
      $curr = $resource{"sendEnd"};
    }
    if ($resource{"receiveHeadersEnd"} > 0) {
      $resource{"receiveFirst"} = $resource{"receiveHeadersEnd"} - $curr;
      $curr = $resource{"receiveHeadersEnd"};
    }
    if ($resource{"receivedTime"} > 0) {
      $resource{"receiveLast"} = $resource{"receivedTime"} - $curr;
      $curr = $resource{"receivedTime"};
    }

    @resources[$i] = encode_json(\%resource);
    ++$i;
  }

  $info->setResources(\@resources);
}

# Add obj_id and D2E dependencies to comps
# Creates a table that is a union of object id, dependencies, and comps
sub addIdAndD2E2Comps {
  my ($self, $info) = @_;
  $info = $self->{_info};
  $pageStart = $info->getPageStart();
  @resources = @{$info->getResources()};
  @comps = @{$info->getComps()};
  @parses = @{$self->{_parses}};

  my $i = 0;
  foreach $comp (@comps) {
    %comp = %{decode_json($comp)};
    $comp{"obj_id"} = "comp_" . $i;
    $comp{"startTime"} = ($comp{"startTime"} - $pageStart) * 1000;
    $comp{"endTime"} = ($comp{"endTime"} - $pageStart) * 1000;

    if ($comp{"urlRecalcStyle"} eq "(null)") {
      $comps[$i] = encode_json(\%comp);
      ++$i;
      next;
    }

    # dependency: comps from downloads
    foreach $resource (@resources) {
      %resource = %{decode_json($resource)};
      if ($comp{"urlRecalcStyle"} eq $resource{"url"}) {
        #print $comp{"urlRecalcStyle"} . "\n";

        $comp{"D2E"} = $resource{"obj_id"};
        $comp{"critical"} = $resource{"obj_id"};
        $comp{"critical_time"} = $resource{"receivedTime"};

        my %pr = (
          "id", $resource{"obj_id"},
          "at", $resource{"receivedTime"},
          "rt", $resource{"receivedTime"} - $resource{"sentTime"},
          "rs", "data",
        );

        # push to prev
        my @prev = ();
        if ($comp{"prev"}) {
          @prev = @{decode_json($comp{"prev"})};
        }
        push(@prev, encode_json(\%pr));
        $comp{"prev"} = encode_json(\@prev);
        #print $comp{"prev"} . "\n";

        last;
      }
    }

    # dependency: comps from parses chunks
    foreach $parse (@parses) {
      %parse = %{decode_json($parse)};
      if (!$parse{"objectsUrl"}) {
        next;
      }
      @objects = @{decode_json($parse{"objectsUrl"})};
      foreach $object (@objects) {
        %object = %{decode_json($object)};
        if ($comp{"urlRecalcStyle"} eq $object{"url"}) {
        my %pr = (
          "id", $object{"code"},
          "at", $object{"time"},
          "rt", $object{"time"} - $parse{"start"},
          "rs", "data",
        );

        # push to prev
        my @prev = ();
        if ($comp{"prev"}) {
          @prev = @{decode_json($comp{"prev"})};
        }
        push(@prev, encode_json(\%pr));
        $comp{"prev"} = encode_json(\@prev);
        #print $parse{"start"} . "\n";
        #print $comp{"prev"} . "\n";

        last;
        }
      }
    }

    $comps[$i] = encode_json(\%comp);
    ++$i;
  }

  $info->setComps(\@comps);
}

# Add comps to parses and leave other comps not in parses external
# Creates a table from a union of parse and comps (not in parses external)
sub addComps2Parses {
  my ($self, $info, $parses) = @_;
  $info = $self->{_info};
  @comps = @{$info->getComps()};
  @parses = @{$self->{_parses}};

  my @comps_post_n;
  my @comps_post_l;

  foreach $comp (@comps) {
    #print $comp . "\n";
    %comp = %{decode_json($comp)};

    my $i = 0;
    foreach $parse (@parses) {
      %parse = %{decode_json($parse)};
      if ($parse{"url"} eq $comp{"docUrl"}) {
        # During parsing
        if ($parse{"last_code"} ne $comp{"code"}) {

            if ($parse{"during_n"}) {
              @comps_during_n = @{$parse{"during_n"}};
            } else {
              @comps_during_n = ();
            }
            push(@comps_during_n, $comp);
            $parse{"during_n"} = \@comps_during_n;

          if ($comp{"urlRecalcStyle"} ne "(null)" and $comp{"urlRecalcStyle"} ne "") {
            if ($parse{"during_l"}) {
              @comps_during_l = @{$parse{"during_l"}};
            } else {
              @comps_during_l = ();
            }
            push(@comps_during_l, $comp);
            $parse{"during_l"} = \@comps_during_l;

          }
        # Post parsing
        } else {
          if ($comp{"urlRecalcStyle"} eq "(null)" or $comp{"urlRecalcStyle"} eq "") {
            push(@comps_post_n, $comp);
          } else {
            push(@comps_post_l, $comp);
          }
        }
      }
      $parses[$i] = encode_json(\%parse);
      ++$i;
    }
  }

  $self->{_parses} = \@parses;
  $self->{_comps_post_n} = \@comps_post_n;
  $self->{_comps_post_l} = \@comps_post_l;
}

# Add HOL dependencies and calculate the real prev
sub addHolDependencies {
  my ($self, $info, $parses) = @_;
  $info = $self->{_info};
  @resources = @{$info->getResources()};
  @hols = @{$info->getHols()};
  @parses = @{$self->{_parses}};
  @comps_post_l = @{$self->{_comps_post_l}};

  # build the 'lotus root' graph
  my @hols_trimmed;
  my @hols_prev;
  my $ref_js = undef;
  my $i = 0;
  foreach $hol (@hols) {
    %hol = %{decode_json($hol)};
    if ($hol{"url"} eq "(null)") {
      next;
    }

    # add comps to the 'lotus root' graph
    $comp_hol = undef;
    foreach $parse (@parses) {
      if ($comp_hol) {
        last;
      }
      %parse = %{decode_json($parse)};
      @comps_during_l = @{$parse{"during_l"}};

      my $j = 0;
      foreach $comp (@comps_during_l) {
        %comp = %{decode_json($comp)};

        # Match docUrl
        if ($comp{"docUrl"} ne $hol{"docUrl"}) {
          next;
        }
        # Match url
        if ($comp{"urlRecalcStyle"} ne $hol{"url"}) {
          next;
        }

        # comp found!
        $comp_hol = $comp;
        last;
      }
    }

    if ($hol{"type"} == 1) { # parsing-blocking js
      $hol{"hols_prev"} = encode_json(\@hols_prev);
      $hols_prev = undef;
      @hols_prev = ();
      push(@hols_prev, $comp_hol);

      # create ref for css
      my @ppp = ($comp_hol);
      $ref_js = encode_json(\@ppp);

      #print $hol{"type"} . " " . $hol{"url"} . "\n";
      #print $hol{"hols_prev"} . "\n\n";

    } elsif ($hol{"type"} == 4) { # css
      #$hol{"hols_prev"} = $ref_js;
      push(@hols_prev, $comp_hol);

      #print $hol{"type"} . " " . $hol{"url"} . "\n";
      #print $hol{"hols_prev"} . "\n\n";
    }

    push(@hols_trimmed, encode_json(\%hol));
    #print encode_json(\%hol) . "\n";
  }

  # add dependencies to comps
  # Union dependencies and comps
  my $i = 0;
  foreach $parse (@parses) {
    %parse = %{decode_json($parse)};
    @comps_during_l = @{$parse{"during_l"}};

    my $j = 0;
    foreach $comp (@comps_during_l) {
      %comp = %{decode_json($comp)};

      foreach $hol (@hols_trimmed) {
        %hol = %{decode_json($hol)};
        # Match docUrl
        if ($comp{"docUrl"} ne $hol{"docUrl"}) {
          next;
        }
        # Match url
        if ($comp{"urlRecalcStyle"} ne $hol{"url"}) {
          next;
        }

        # add to @prev in parse
        my %pr = (
          "id", $comp{"obj_id"},
          "at", $comp{"endTime"},
          "rt", $comp{"endTime"} - $comp{"startTime"},
          "rs", "resource",
          "if", $comp{"endTime"} - $parse{"start"},
        );

        # push to prev
        my @prev = ();
        if ($parse{"prev"}) {
          @prev = @{decode_json($parse{"prev"})};
        }
        push(@prev, encode_json(\%pr));
        $parse{"prev"} = encode_json(\@prev);

        # push to js_ids
        if ($hol{"type"} == 1) {
          @js_ids = ();
          if ($parse{"js_ids"}) {
            @js_ids = @{decode_json($parse{"js_ids"})};
          }
          push(@js_ids, $comp{"obj_id"});
          $parse{"js_ids"} = encode_json(\@js_ids);
        }

        # Matched! Add dependency
        if ($hol{"hols_prev"}) {
          @hols_prev = @{decode_json($hol{"hols_prev"})};
          foreach $hol_comp (@hols_prev) {
            if (!$hol_comp) {
              next;
            }
            %hol_comp = %{decode_json($hol_comp)};

            # set critical time
            #print $hol_comp{"endTime"} . " " . $comp{"critical_time"} . "\n";
            if ($hol_comp{"endTime"} > $comp{"critical_time"}) {
              $comp{"critical"} = $hol_comp{"obj_id"};
              $comp{"critical_time"} = $hol_comp{"endTime"};
            }


            # push to prev
            #my @prev = ();
            #if ($comp{"prev"}) {
            @prev = @{decode_json($comp{"prev"})};
            #}
            # add to @prev
            my %pr = (
              "id", $hol_comp{"obj_id"},
              "at", $hol_comp{"endTime"},
              "rt", $hol_comp{"endTime"} - $hol_comp{"startTime"},
              "rs", "control",
            );
            push(@prev, encode_json(\%pr));
            # add to @prev
            my %pr = (
              "id", $parse{"obj_id"},
              "at", $comp{"startTime"},
              "rt", $comp{"startTime"} - $parse{"start"},
              "rs", "resource",
            );
            push(@prev, encode_json(\%pr));
            $comp{"prev"} = encode_json(\@prev);
          }
        }

        #print $comp{"obj_id"} . " " . $comp{"startTime"} . "\n";
        #print $comp{"urlRecalcStyle"} . "\n";
        #print $comp{"prev"} . "\n\n";

        #print $comp . "\n\n";
        $comp{"hol_type"} = $hol{"type"};
        last;
      }

      # do something if not matched
      if (!$comp{"hol_type"}) {
        $comp{"hol_type"} = 2; # async
      }

      # calculate what's critical

      $comps_during_l[$j] = encode_json(\%comp);
      #print $comps_during_l[$j] . "\n\n";
      ++$j;
    }
    $parse{"during_l"} = \@comps_during_l;
    $parses[$i] = encode_json(\%parse);
    ++$i;
  }

  $self->{_parses} = \@parses;
}

sub addE2DDependencies {
  my ($self, $info, $parses) = @_;
  $info = $self->{_info};

  $pageUrl = $info->getPageUrl();
  $pageStart = $info->getPageStart();
  @resources = @{$info->getResources()};
  @parses = @{$self->{_parses}};
  @comps_post_l = @{$self->{_comps_post_l}};
  @mcaus = @{$info->getMatchedCSSAndUrls()};
  @preloads = @{$info->getPreloads()};

  # Extract css->img dependency
  # store in %img_resource for future use
  my %img_resource = ();
  foreach $mcaus (@mcaus) {
    %mcaus = %{decode_json($mcaus)};
    $imgUrl = $mcaus{"imgUrl"};
    if (!$img_resource{$imgUrl}) {
      $resource = $self->findResourceByUrl($mcaus{"url"});
      $img_resource{$imgUrl} = $resource;
    }
  }

  # Extract preloading dependency
  # store in %preload_dep for future use
  my %preload_dep = ();
  $alpha = 1; # ms
  foreach $preload (@preloads) {
    %preload = %{decode_json($preload)};
    $preload{"time"} = 1000 * ($preload{"time"} - $pageStart);
    $preload = encode_json(\%preload);
    $url = $preload{"url"};

    $resource = $self->findResourceByUrl($url);
    if (!$resource) {
      next;
    }
    %resource = %{decode_json($resource)};
    $diff = $preload{"time"} - $resource{"sentTime"};
    if ($diff > $alpha or $diff < -$alpha) {
      next;
    }

    $preload_dep{$url} = $preload;
  }

  # add dependencies
  my $j = 0;
  foreach $resource (@resources) {
    %r = %{decode_json($resource)};
    $url = $r{"url"};

    # Match with css->img dependency
    if ($img_resource{$url}) {
      %obj = %{decode_json($img_resource{$url})};

      # add to @prev
      my %pr = (
        "id", $obj{"obj_id"},
        "at", $obj{"receivedTime"},
        "rt", $obj{"receivedTime"} - $obj{"sentTime"},
        "rs", "css2img",
      );

      # push to prev
      my @prev = ();
      if ($r{"prev"}) {
        @prev = @{decode_json($r{"prev"})};
      }
      push(@prev, encode_json(\%pr));
      $r{"prev"} = encode_json(\@prev);
    }

    # Match with preloading dependency
    if ($preload_dep{$url}) {
      %preload = %{decode_json($preload_dep{$url})};
      #print $preload_dep{$url} . "\n";

      # search for "obj"
      my $obj = undef;
      foreach $parse (@parses) {
        %parse = %{decode_json($parse)};
        if ($parse{"url"} ne $preload{"docUrl"}) {
          next;
        }

        if (!$parse{"objects_hash"}) {
          next;
        }
        %objects = %{decode_json($parse{"objects_hash"})};
        $obj = $objects{$preload{"code"}};

        last;
      }

      #print $obj . "\n";
      %obj = %{decode_json($obj)};

      # add to @prev
      my %pr = (
        "id", $obj{"code"},
        "at", $obj{"time"},
        "rt", $obj{"time"} - $parse{"start"},
        "rs", "preload",
      );

      # push to prev
      my @prev = ();
      if ($r{"prev"}) {
        @prev = @{decode_json($r{"prev"})};
      }
      push(@prev, encode_json(\%pr));
      $r{"prev"} = encode_json(\@prev);
      #print $r{"prev"} . "\n";
    }

    # First, match with comps not during html parsing
    my $n = @comps_post_l;
    for ($i = $n - 1; $i >= 0; --$i) {
      $comp = $comps_post_l[$i];
      %comp = %{decode_json($comp)};
if (0) {
      print "\n" . $r{"url"} . "\n";
      print $comp{"urlRecalcStyle"} . "\n";
      print $r{"sentTime"} . " " . $comp{"startTime"} . " " . $comp{"endTime"} . "\n";
}
      if ($r{"sentTime"} > $comp{"startTime"} and $r{"sentTime"} < $comp{"endTime"}) {
        $r{"E2D"} = $comp{"obj_id"};
        $r{"critical"} = $comp{"obj_id"};
        $r{"critical_time"} = $comp{"endTime"};

        # add to @prev
        my %pr = (
          "id", $comp{"obj_id"},
          "at", $r{"sentTime"},
          "rt", $r{"sentTime"} - $comp{"startTime"},
          "rs", "data2",
        );

        # push to prev
        my @prev = ();
        if ($r{"prev"}) {
          @prev = @{decode_json($r{"prev"})};
        }
        push(@prev, encode_json(\%pr));
        $r{"prev"} = encode_json(\@prev);
      }
    }

    # Second, match with html parsing
    if (!$r{"E2D"}) {
      my $n = @parses;
      for ($i = $n - 1; $i >= 0; --$i) {
        $parse = $parses[$i];
        %parse = %{decode_json($parse)};
if (0) {
	print "\n" . $r{"url"} . "\n";
	print $r{"sentTime"} . " " . $parse{"start"} . " " . $parse{"end"} . "\n";
}
        if ($r{"sentTime"} > $parse{"start"} and $r{"sentTime"} < $parse{"end"}) {
          $r{"E2D"} = $parse{"obj_id"};
          $r{"critical"} = $parse{"obj_id"};
          $r{"critical_time"} = $parse{"end"};
	#print "E2D : " . $r{"E2D"} . "\n";

if (0) {
          $obj = undef;
          if ($parse{"objectsUrl"}) {
            @objects = @{decode_json($parse{"objectsUrl"})};
            foreach $object (@objects) {
              if ($object{"url"} eq $r{"url"}) {
                $obj = $object;
                last;
              }
            }
          }
          print $obj . "\n";
}

          # add to @prev
          my %pr = (
            "id", $parse{"obj_id"},
            "at", $r{"sentTime"},
            "rt", $r{"sentTime"} - $parse{"start"},
            "rs", "data2",
          );

          # push to prev
          my @prev = ();
          if ($r{"prev"}) {
            @prev = @{decode_json($r{"prev"})};
          }
          push(@prev, encode_json(\%pr));
          $r{"prev"} = encode_json(\@prev);
        }
      }
    }

    # Third, for those that are not matched, match with the main html
    # We could fix bugs here
    $urlf = $pageUrl;
    $urlf =~ s/\_/\//g;
    if (!$r{"E2D"}) {
      my $n = @parses;
      for ($i = $n - 1; $i >= 0; --$i) {
        $parse = $parses[$i];
        %parse = %{decode_json($parse)};
        @a = split(/\/\//, $parse{"url"});
        if ($a[1] eq $urlf and $r{"sentTime"} > $parse{"end"}) {
          #print $a[1] . " " . $urlf . "\n";
          #print $r{"sentTime"} . " " . $parse{"start"} . " " . $parse{"end"} . "\n";
          $r{"E2D"} = $parse{"obj_id"};
          $r{"E2D_miss"} = $r{"sentTime"} - $parse{"end"};
          $r{"critical"} = $parse{"obj_id"};
          $r{"critical_time"} = $parse{"end"};

          # add to @prev
          my %pr = (
            "id", $parse{"obj_id"},
            "at", $r{"sentTime"},
            "rt", $r{"sentTime"} - $parse{"start"},
            "miss", $r{"sentTime"} - $parse{"end"},
            "rs", "data2",
          );

          # push to prev
          my @prev = ();
          if ($r{"prev"}) {
            @prev = @{decode_json($r{"prev"})};
          }
          push(@prev, encode_json(\%pr));
          $r{"prev"} = encode_json(\@prev);
        }
      }
    }

    $resources[$j] = encode_json(\%r);
    ++$j;
  }

  $info->setResources(\@resources);
}

# Creates the Dependency graph: Name, Objs, deps, Start activity, Load activity
sub generateDependencyGraph {
  my ($self, $info, $parses) = @_;
  my $info = $self->{_info};
  my $json = JSON->new->allow_nonref;

  # Get required resources
  my @resources = @{$info->getResources()};
  my @parses = @{$self->{_parses}};
  my @comps_post_l = @{$self->{_comps_post_l}};
  my @comps_post_n = @{$self->{_comps_post_n}};
  my $url = $info->getPageUrl();
  my %objecthashes = %{$info->getObjecthashes()};
  my $pageStart = $info->getPageStart();

  # Initialize graph
  my $graph = {};
  $graph->{name} = $url;
  $graph->{objs} = [];
  $graph->{deps} = [];
  $graph->{start_activity} = "";
  $graph->{load_activity} = -1;
  my $i_dep = 0;

  # Prepare files to log the dependency graph
  my $filename = "dep_logs/$url";
  open FP, ">>$filename";

  # Construct downloads
  $n_download_no_trigger = 0;
  my @data_uris = [];
  for my $rr (@resources) {
    next if (!$rr);
    my $r = decode_json($rr);
    if ($r->{url} !~ /^http/) {
      #print "[rrr] $rr\n\n";

      if ($r->{prev}) {
        push(@data_uris, $rr);
      } else {
        $n_download_no_trigger++;
      }

      next;
    }

    # Add to graph
    my $obj = {};
    $obj->{id} = "r" . $r->{id};
    $obj->{url} = $r->{url}; # To calculate host and path
    $obj->{when_comp_start} = ($r->{mimeType} =~ /html/) ? 1 : -1;
    $obj->{download}->{type} = $r->{mimeType};
    $obj->{download}->{s_time} = $r->{sentTime};
    #$obj->{download}->{id} = "download_" . $r->{id};
    $obj->{download}->{id} = $r->{obj_id};
    $obj->{comps} = [];
    push($graph->{objs}, $obj);

    # print info
    $cmd = $json->pretty->encode($r);
    print FP "[resource] $cmd";

    if ($r->{'prev'}) {
      my $prev = decode_json($r->{'prev'});
      my $cmd1 = $json->pretty->encode($prev);
      print FP "[resource_prev] $cmd1";
    } else {
      $n_download_no_trigger++;
      $graph->{start_activity} = $obj->{download}->{id} if (!$graph->{start_activity});
    }
    print FP "\n";
  }
  $graph->{n_download_no_trigger} = $n_download_no_trigger;

  # Construct parses and comps in parses
  for my $pp (@parses) {
    next if (!$pp);
    my $p = decode_json($pp);
    next if ($p->{url} !~ /^http/);

    # Find corresponding download activity
    my $i = 0;
    my $obj;
    for my $o (@{$graph->{objs}}) {
      if ($o->{url} eq $p->{url}) {
        $obj = $o;
        last;
      }
      $i++;
    }
    $obj->{comps} = [] if (!$obj->{comps});

    # Print info
    $cmd = $json->pretty->encode($p);
    print FP "[parse] $cmd";

    # Construct $comp
    my $j = 1;
    my $comp = {};
    $comp->{id} = $obj->{id} . "_c$j";
    $comp->{type} = "evalhtml";
    $comp->{s_time} = $p->{start};

    if ($p->{'during_l'}) {
      # First, cut HTML evaluation into activities by parsing blocking JS
      for $during_ll (@{$p->{'during_l'}}) {
        my $during_l = decode_json($during_ll);
        next if ($during_l->{hol_type} != 1);

        # Finish the current activity
        my $code = $during_l->{code};
        my $objhash = decode_json($objecthashes{$code});
        $comp->{e_time} = ($objhash->{time} - $pageStart) * 1000;
        $obj->{comps} = [] if (!$obj->{comps});
        push($obj->{comps}, decode_json(encode_json($comp)));

        # Start a new activity
        $j++;
        $comp->{id} = $obj->{id} . "_c$j";
        $comp->{type} = "evalhtml";
        $comp->{s_time} = $during_l->{endTime};

        # [add dep] The new activity depends on completion of $during_l
        my $dep = {};
        $i_dep++;
        $dep->{id} = "dep$i_dep";
        $dep->{a1} = $during_l->{obj_id};
        $dep->{a2} = $comp->{id};
        $dep->{time} = -1;
        push($graph->{deps}, $dep);
      }
      $comp->{e_time} = $p->{end};
      $obj->{comps} = [] if (!$obj->{comps});
      push($obj->{comps}, $comp);
      $graph->{objs}[$i] = $obj;

      # Second, add comp activity to objects and add output dependencies
      for $during_ll (@{$p->{'during_l'}}) {
        my $during_l = decode_json($during_ll);
        next if ($during_l->{'type'} ne "execScript" and $during_l->{'type'} ne "recalcStyle");

        # Find corresponding object
        my $i = 0;
        my $obj;
        for my $o (@{$graph->{objs}}) {
          if ($o->{url} eq $during_l->{urlRecalcStyle}) {
            $obj = $o;
            last;
          }
          $i++;
        }

        # If obj is not found, this should evaluate a data uri which has been included in another comp.
        # So just skip
        if (!$obj) {
          next;
        }

        my $comp = {};
        $comp->{id} = $during_l->{obj_id};
        $comp->{type} = $during_l->{hol_type};
        $comp->{s_time} = $during_l->{startTime};
        $comp->{e_time} = $during_l->{endTime};
        $obj->{comps} = [] if (!$obj->{comps});
        push($obj->{comps}, $comp);
        $graph->{objs}[$i] = $obj;

        # Print out info
        my $cmd1 = $json->pretty->encode($during_l);
        print FP "[parse_during_l] $cmd1";

        my $code = $during_l->{code};
        my $objhash = $objecthashes{$code};
        print FP "[parse_during_l_object] $objhash\n";

        if ($during_l->{'prev'}) {
          my $prev = decode_json($during_l->{'prev'});
          my $cmd2 = $json->pretty->encode($prev);
          print FP "[parse_during_l_prev] $cmd2";

          # [add dep] Add output dependency
          for $pr (@$prev) {
            $pr = decode_json($pr);
            if ($pr->{rs} eq "control") {
              my $dep = {};
              $i_dep++;
              $dep->{id} = "dep$i_dep";
              $dep->{a1} = $pr->{id};
              $dep->{a2} = $during_l->{obj_id};
              $dep->{time} = -1;
              push($graph->{deps}, $dep);

              print FP "[parsing_during_l_prev_code] " . $objecthashes{$code} . "\n";
            }
          }
        }
      }
    }
    print FP "\n";
  }

  # Construct comps outside of parses
  for my $cc (@comps_post_l) {
    next if (!$cc);
    my $c = decode_json($cc);
    next if ($c->{'type'} ne "execScript" and $c->{'type'} ne "recalcStyle");

    # Find corresponding object
    my $n_objs = @{$graph->{objs}};
    my $i = 0;
    my $obj;
    for my $o (@{$graph->{objs}}) {
      if ($o->{url} eq $c->{urlRecalcStyle}) {
        $obj = $o;
        last;
      }
      $i++;
    }

    # If obj is not found, this should evaluate a data url which has been included in another comp.
    # So just skip
    if (!$obj) {
      next;
    }

    my $comp = {};
    $comp->{id} = $c->{obj_id};
    $comp->{type} = $c->{hol_type};
    $comp->{s_time} = $c->{startTime};
    $comp->{e_time} = $c->{endTime};
    $obj->{comps} = [] if (!$obj->{comps});
    push($obj->{comps}, $comp);
    $graph->{objs}[$i] = $obj;


    $cmd = $json->pretty->encode($c);
    print FP "[comp] $cmd";

    if ($c->{'prev'}) {
      my $prev = decode_json($c->{'prev'});
      $cmd1 = $json->pretty->encode($prev);
      print FP "[resource_prev] $cmd1";
    }
    print FP "\n";
  }

  # Add E2D dependency info
  # This might change e_time of a comp activity
  # Note that we do this backward to make sure that e_time is changed first
  my $n_resources = @resources;
  for (my $i_resources = $n_resources - 1; $i_resources >= 0; $i_resources--) {
    my $rr = $resources[$i_resources];
    next if (!$rr);
    my $r = decode_json($rr);

    next if ($r->{url} !~ /^http/);

    # Get $obj
    my $obj;
    for my $o (@{$graph->{objs}}) {
      if ($o->{download}->{id} eq $r->{obj_id}) {
        $obj = $o;
        last;
      }
    }

    if ($r->{prev}) {
      my @prevs = @{decode_json($r->{prev})};
      for my $prevv (@prevs) {
        my $prev = decode_json($prevv);

        # Get $parse
        my $parse = -1;
        for my $pp (@parses) {
          next if (!$pp);
          my $p = decode_json($pp);
          if ($prev->{id} eq $p->{obj_id}) {
            $parse = $p;
            last;
          }
        }

        # Get comp if no $parse
        if ($parse == -1) {
          # Get comp in obj
          my $comp;
          my $is_found_comp = 0;
          for my $o (@{$graph->{objs}}) {
            for my $c (@{$o->{comps}}) {
              if ($prev->{id} eq $c->{id}) {
                $comp = $c;
                $is_found_comp = 1;
                last;
              }
            }
            last if ($is_found_comp > 0);
          }

          if ($is_found_comp > 0) {
            # [add dep]
            my $dep = {};
            $i_dep++;
            $dep->{id} = "dep$i_dep";
            $dep->{a1} = $comp->{id};
            $dep->{a2} = $obj->{download}->{id};
            $dep->{time} = $obj->{download}->{s_time} - $comp->{s_time};

            if ($obj->{download}->{s_time} > $comp->{e_time}) {
              $comp->{e_time} = $obj->{download}->{s_time};
              $dep->{time} = -1;
            }

            push($graph->{deps}, $dep);
          } else {
            # If no comp is matched, it means that this object download is triggered
            # by firing events. So we connect it back to $parse
            $parse = decode_json($parses[0]);
          }
        }
        next if ($parse == -1);

        # Get $obj_parse
        my $obj_parse;
        for my $o (@{$graph->{objs}}) {
          if ($o->{url} eq $parse->{url}) {
            $obj_parse = $o;
            last;
          }
        }

        # Add dependency
        my $n_comps = @{$obj_parse->{comps}};
        my $comp_fake = {};
        $comp_fake->{s_time} = 1000000000;
        for (my $i = 0; $i < $n_comps; $i++) {
          my $comp = $obj_parse->{comps}[$i];
          my $comp_next = ($i < $n_comps - 1) ? $obj_parse->{comps}[$i + 1] : $comp_fake;
          if ($obj->{download}->{s_time} > $comp->{s_time} and $obj->{download}->{s_time} < $comp_next->{s_time}) {
            # [add dep]
            my $dep = {};
            $i_dep++;
            $dep->{id} = "dep$i_dep";
            $dep->{a1} = $comp->{id};
            $dep->{a2} = $obj->{download}->{id};
            $dep->{time} = $obj->{download}->{s_time} - $comp->{s_time};

            if ($obj->{download}->{s_time} > $comp->{e_time}) {
              $comp->{e_time} = $obj->{download}->{s_time};
              $dep->{time} = -1;
            }

            push($graph->{deps}, $dep);
            last;
          }
        }
      }
    }
  }

  # Calculate the elapsed time in comp
  my $i = 0;
  for my $o (@{$graph->{objs}}) {
    my $j = 0;
    for my $c (@{$o->{comps}}) {
      $c->{time} = $c->{e_time} - $c->{s_time};
      #delete $c->{s_time};
      #delete $c->{e_time};
      $o->{comps}[$j] = $c;
      $j++;
    }
    $graph->{objs}[$i] = $o;
    $i++;
  }

  close FP;

  my $filename1 = "graphs/$url";
  open FH, ">$filename1.json";
  print FH $json->pretty->encode($graph);
  close FH;
}

# What is this what if analysis on?
sub whatIfAnalysis {
  my ($self, $info, $parses) = @_;
  $info = $self->{_info};
  $url = $info->getPageUrl();
  $pageStart = $info->getPageStart();
  $pageEnd = $info->getPageEnd();
  $pageEndTime = ($pageEnd - $pageStart) * 1000;

  @resources = @{$info->getResources()};
  @parses = @{$self->{_parses}};
  @comps_post_l = @{$self->{_comps_post_l}};

  %objs = ();

  # convert array to hash for
  # @resources, @parses, and @comps_post_l
  foreach $resource (@resources) {
    %resource = %{decode_json($resource)};
    $objs{$resource{"obj_id"}} = $resource;
  }

  foreach $parse (@parses) {
    %parse = %{decode_json($parse)};
    $objs{$parse{"obj_id"}} = $parse;
  }

  foreach $comp (@comps_post_l) {
    %comp = %{decode_json($comp)};
    $objs{$comp{"obj_id"}} = $comp;
  }

  # add succ to dependency
  foreach $resource (@resources) {
    %resource = %{decode_json($resource)};
    if (!$resource{"prev"}) {
      next;
    }
    @prev = @{decode_json($resource{"prev"})};
    #print "\n" . $resource{"url"} . "\n";
    foreach $prev (@prev) {
      #print $prev . "\n";
      %prev = %{decode_json($prev)};
      my %pr = (
        "rs", $prev{"rs"},
        "at", $prev{"at"},
        "rt", $prev{"rt"},
        "id", $resource{"obj_id"},
        "miss", $prev{"miss"},
      );

      if ($objs{$prev{"id"}}) {
        $obj = $objs{$prev{"id"}};
        %obj = %{decode_json($obj)};
        @succ = ();
        if ($obj{"succ"}) {
          @succ = @{decode_json($obj{"succ"})};
        }
        push(@succ, encode_json(\%pr));
        $obj{"succ"} = encode_json(\@succ);
        $objs{$prev{"id"}} = encode_json(\%obj);
        
        #print $prev{"id"} . "\n";
        #print $objs{$prev{"id"}}{"succ"} . "\n";
      }
    }
  }

  foreach $comp (@comps_post_l) {
    %comp = %{decode_json($comp)};
    if (!$comp{"prev"}) {
      next;
    }
    @prev = @{decode_json($comp{"prev"})};
    #print "\n" . $comp{"urlRecalcStyle"} . "\n";
    foreach $prev (@prev) {
      #print $prev . "\n";
      %prev = %{decode_json($prev)};
      my %pr = (
        "rs", $prev{"rs"},
        "at", $prev{"at"},
        "rt", $prev{"rt"},
        "id", $comp{"obj_id"},
        "miss", $prev{"miss"},
      );

      if ($objs{$prev{"id"}}) {
        $obj = $objs{$prev{"id"}};
        %obj = %{decode_json($obj)};
        @succ = ();
        if ($obj{"succ"}) {
          @succ = @{decode_json($obj{"succ"})};
        }
        push(@succ, encode_json(\%pr));
        $obj{"succ"} = encode_json(\@succ);
        $objs{$prev{"id"}} = encode_json(\%obj);
        
        #print $prev{"id"} . "\n";
        #print $objs{$prev{"id"}}{"succ"} . "\n";
      }
    }
  }

  foreach $parse (@parses) {
    %parse = %{decode_json($parse)};
    if (!$parse{"prev"}) {
      next;
    }
    @prev = @{decode_json($parse{"prev"})};
    #print "\n" . $parse{"url"} . "\n";
    foreach $prev (@prev) {
      #print $prev . "\n";
      %prev = %{decode_json($prev)};
      my %pr = (
        "rs", $prev{"rs"},
        "at", $prev{"at"},
        "rt", $prev{"rt"},
        "id", $parse{"obj_id"},
        "miss", $prev{"miss"},
      );

      if ($objs{$prev{"id"}}) {
        $obj = $objs{$prev{"id"}};
        %obj = %{decode_json($obj)};
        @succ = ();
        if ($obj{"succ"}) {
          @succ = @{decode_json($obj{"succ"})};
        }
        push(@succ, encode_json(\%pr));
        $obj{"succ"} = encode_json(\@succ);
        $objs{$prev{"id"}} = encode_json(\%obj);
        
        #print $prev{"id"} . "\n";
        #print $objs{$prev{"id"}}{"succ"} . "\n";
      }
    }

    if (!$parse{"during_l"}) {
      next;
    }

    my %comps = ();
    @comps = @{$parse{"during_l"}};
    foreach $comp (@comps) {
      %comp = %{decode_json($comp)};
      # push to hash
      $comps{$comp{"obj_id"}} = $comp;

      if (!$comp{"prev"}) {
        next;
      }
      #print "\n" . $comp{"urlRecalcStyle"} . "\n";
      @prev = @{decode_json($comp{"prev"})};
      foreach $prev (@prev) {
        #print $prev . "\n";
      %prev = %{decode_json($prev)};
      my %pr = (
        "rs", $prev{"rs"},
        "at", $prev{"at"},
        "rt", $prev{"rt"},
        "id", $comp{"obj_id"},
        "miss", $prev{"miss"},
      );

      if ($objs{$prev{"id"}}) {
        $obj = $objs{$prev{"id"}};
        %obj = %{decode_json($obj)};
        @succ = ();
        if ($obj{"succ"}) {
          @succ = @{decode_json($obj{"succ"})};
        }
        push(@succ, encode_json(\%pr));
        $obj{"succ"} = encode_json(\@succ);
        $objs{$prev{"id"}} = encode_json(\%obj);
        
        #print $prev{"id"} . "\n";
        #print $objs{$prev{"id"}}{"succ"} . "\n";
      }
      }
    }
    # add comps to parse
    $id = $parse{"obj_id"};
    $p = $objs{$id};
    %p = %{decode_json($p)};
    $p{"comps_hash"} = encode_json(\%comps);
    $objs{$id} = encode_json(\%p);
  }

  # from the root activity (download the html page) to the last activity
  # change the timing depending on "what-if" policies
  my $str_objs = encode_json(\%objs);
  my @results = ();
  # percentage
  print "PLT\t" . $pageEndTime . "\n";
  my @nn = (0, 0.25, 0.5, 0.75, 1);
  my @cc = (0, 0.25, 0.5, 0.75, 1);
  foreach $n(@nn) {
    foreach $c (@cc) {
      $pp = $self->whatIfAnalysisStart($str_objs, 1, $n, $c);
      push(@results, $pp);
      #print $n . "\t" . $c . "\t" . $pp . "\n";
    }
  }
  # compare two setups
  $pp = $self->whatIfAnalysisStart($str_objs, 1, 1, 1.5);
  push(@results, $pp);
  #print $pp . "\n";
  # dns
  $pp = $self->whatIfAnalysisStart($str_objs, 2, 1, 1);
  push(@results, $pp);
  #print $pp . "\n";
  # conn
  $pp = $self->whatIfAnalysisStart($str_objs, 3, 1, 1);
  push(@results, $pp);
  #print $pp . "\n";

  return  encode_json(\@results);
}


sub whatIfAnalysisStart {
  my ($self, $info, $parses) = @_;
  $info = $self->{_info};
  $url = $info->getPageUrl();
  $pageStart = $info->getPageStart();
  $pageEnd = $info->getPageEnd();
  $pageEndTime = ($pageEnd - $pageStart) * 1000;

  $pageEndIf = -1;

  %objs = %{decode_json($_[1])};
  $isPercent = $_[2];
  $paramNet = $_[3];
  $paramComp = $_[4];

  # address the download_0
  $id = "download_0";
  $obj = $objs{$id};
  if ($obj) {
    %obj = %{decode_json($obj)};
    @succ = ();
    if ($obj{"succ"}) {
      @succ = @{decode_json($obj{"succ"})};
    } else {
      return;
    }
    %succ_0 = %{decode_json($succ[0])};

    # calculate relative time based on what-if policies
    $obj{"ifStart"} = 0;
    if ($isPercent == 1) {
      $obj{"if"} = $succ_0{"rt"} * $paramNet;
    } else {
      if ($isPercent == 2) { # DNS
        $obj{"if"} = $succ_0{"rt"} - $obj{"dns"};
      } elsif ($isPercent == 3) { # TCP conn.
        $obj{"if"} = $succ_0{"rt"} - $obj{"conn"};
      }
    }
    $obj{"ifEnd"} = $obj{"ifStart"} + $obj{"if"};
    if ($obj{"ifEnd"} > $pageEndif) {
      $pageEndIf = $obj{"ifEnd"};
    }

    $objs{$id} = encode_json(\%obj);
    #print $objs{$id} . "\n";
    #print $obj{"if"} . "\n";
    #print $obj{"succ"} . "\n"
  }

  # address the parse_0
  $id = "parse_0";
  $obj = $objs{$id};
  if ($obj) {
    %obj = %{decode_json($obj)};
    if (!$obj{"prev"}) {
      return;
    }
    @prev = @{decode_json($obj{"prev"})};
    %prev_0 = %{decode_json($prev[0])};

    # get comps hash
    %comps = ();
    if ($obj{"comps_hash"}) {
      %comps = %{decode_json($obj{"comps_hash"})};
    }

    # set js ids
    @js_ids = ();
    if ($obj{"js_ids"}) {
      @js_ids = @{decode_json($obj{"js_ids"})};
    }

    # set the ifStart
    $prev_id = $prev_0{"id"};
    $prev_obj = $objs{$prev_id};
    %prev_obj = %{decode_json($prev_obj)};
    $obj{"ifStart"} = $prev_obj{"ifEnd"};

#################################################################################################################################################################
    # start looking at downloads 
    @succ = ();
    if ($obj{"succ"}) {
      @succ = @{decode_json($obj{"succ"})};
    }
    $i = 0;
    $anchorTime = $obj{"start"};
    $anchorTimeIf = $obj{"ifStart"};
    foreach $js_id (@js_ids) {
      if (!$comps{$js_id}) {
        next;
      }
      %anchor = %{decode_json($comps{$js_id})};
      $anchorStart = $anchor{"startTime"};
      #print "\n\n" . $anchorStart . "\n";
      while (1) {
        #print $i . "\t" . $succ[$i] . "\n";
        if (!$succ[$i]) {
          last;
        }
        %succ = %{decode_json($succ[$i])};
        $succ_id = $succ{"id"};

        if (!$objs{$succ_id}) {
          next;
        }
        %succ_obj = %{decode_json($objs{$succ_id})};

        # encounter the anchor, set the anchorTime, wrap up, and continue
        if ($succ_obj{"sentTime"} > $anchorStart) {
          # TODO compute anchorTime
          @anchor_prevs = @{decode_json($anchor{"prev"})};
          $tempEnd = -1;
          foreach $anchor_prev (@anchor_prevs) {
            %anchor_prev = %{decode_json($anchor_prev)};
            $anchor_prev_id = $anchor_prev{"id"};

            if ($objs{$anchor_prev_id}) {
              %p = %{decode_json($objs{$anchor_prev_id})};
              if ($p{"ifEnd"} > $tempEnd) {
                $tempEnd = $p{"ifEnd"};
              }
            }
            if ($comps{$anchor_prev_id}) {
              %p = %{decode_json($comps{$anchor_prev_id})};
              if ($p{"ifEnd"} > $tempEnd) {
                $tempEnd = $p{"ifEnd"};
              }
            }
          }

          # calculate eval...
          if ($tempEnd > -1) {
            $anchor{"ifStart"} = $tempEnd;
            if ($isPercent == 1) {
              $anchor{"if"} = $paramComp * ($anchor{"endTime"} - $anchor{"startTime"});
            } else {
              $anchor{"if"} = $paramComp * ($anchor{"endTime"} - $anchor{"startTime"});
            }
            $anchor{"ifEnd"} = $anchor{"if"} + $anchor{"ifStart"};
            if ($anchor{"ifEnd"} > $pageEndif) {
              $pageEndIf = $anchor{"ifEnd"};
            }

            # push back
            $comps{$js_id} = encode_json(\%anchor);
          }
          #print $anchor{"ifStart"} . "\t" . $anchor{"ifEnd"} . "\n";
          #print "aaaaaaa" . encode_json(\%anchor) . "\n";

          # set anchor time
          $anchorTime = $anchor{"endTime"};
          $anchorTimeIf = $anchor{"ifEnd"};
          last;
        }

        # obj is a download
        # calculate it's ...
        $succ_obj{"ifStart"} = $anchorTimeIf + $paramComp * ($succ_obj{"sentTime"} - $anchorTime);
        if ($isPercent == 1) {
          $succ_obj{"if"} = $paramNet * ($succ_obj{"receivedTime"} - $succ_obj{"sentTime"});
        } else {
          # TODO
          if ($isPercent == 2) { # DNS
            $succ_obj{"if"} = $succ_obj{"receivedTime"} - $succ_obj{"sentTime"} - $succ_obj{"dns"};
          } elsif ($isPercent == 3) { # TCP conn.
            $succ_obj{"if"} = $succ_obj{"receivedTime"} - $succ_obj{"sentTime"} - $succ_obj{"conn"};
          }
        }
        $succ_obj{"ifEnd"} = $succ_obj{"ifStart"} + $succ_obj{"if"};
        if ($succ_obj{"ifEnd"} > $pageEndif) {
          $pageEndIf = $succ_obj{"ifEnd"};
        }

        #print $succ_obj{"obj_id"} . "\n";
        #print $succ_obj{"url"} . "\n";
        #print $succ_obj{"sentTime"} . "\t" .$succ_obj{"ifStart"} . "\t" . $succ_obj{"ifEnd"} . "\n";

        # push back
        $objs{$succ_id} = encode_json(\%succ_obj);

        # calculate its eval if less than anchor time
        if (!$succ_obj{"succ"}) {
          ++$i;
          next;
        }
        @succ_succs = @{decode_json($succ_obj{"succ"})};

        # look at eval that css/js dependent
        foreach $succ_succ (@succ_succs) {
          %succ_succ = %{decode_json($succ_succ)};
          $succ_succ_id = $succ_succ{"id"};
          if (!$comps{$succ_succ_id}) {
            next;
          }
          %succ_succ_obj = %{decode_json($comps{$succ_succ_id})};

          if ($succ_succ_obj{"endTime"} >= $anchorStart) { # We use endTime here to eliminate ambiguity
            next;
          }
          if (!$succ_succ_obj{"prev"}) {
            next;
          }
          @succ_succ_prevs = @{decode_json($succ_succ_obj{"prev"})};

          # find out the largest endTime
          $tempEnd = -1;
          foreach $succ_succ_prev (@succ_succ_prevs) {
            %succ_succ_prev = %{decode_json($succ_succ_prev)};
            $succ_succ_prev_id = $succ_succ_prev{"id"};

            if ($objs{$succ_succ_prev_id}) {
              %p = %{decode_json($objs{$succ_succ_prev_id})};
              if ($p{"ifEnd"} > $tempEnd) {
                $tempEnd = $p{"ifEnd"};
              }
            }
            if ($comps{$succ_succ_prev_id}) {
              %p = %{decode_json($comps{$succ_succ_prev_id})};
              if ($p{"ifEnd"} > $tempEnd) {
                $tempEnd = $p{"ifEnd"};
              }
            }
          }

          # calculate eval...
          if ($tempEnd > -1) {
            $succ_succ_obj{"ifStart"} = $tempEnd;
            if ($isPercent == 1) {
              $succ_succ_obj{"if"} = $paramComp * ($succ_succ_obj{"endTime"} - $succ_succ_obj{"startTime"});
            } else {
              if ($isPercent == 2) { # DNS
                $succ_succ_obj{"if"} = $succ_succ_obj{"receivedTime"} - $succ_succ_obj{"sentTime"} - $succ_succ_obj{"dns"};
              } elsif ($isPercent == 3) { # TCP conn.
                $succ_succ_obj{"if"} = $succ_succ_obj{"receivedTime"} - $succ_succ_obj{"sentTime"} - $succ_succ_obj{"conn"};
              }
            }
            $succ_succ_obj{"ifEnd"} = $succ_succ_obj{"if"} + $succ_succ_obj{"ifStart"};
            if ($succ_succ_obj{"ifEnd"} > $pageEndif) {
              $pageEndIf = $succ_succ_obj{"ifEnd"};
            }

            # push back
            $objs{$succ_succ_id} = encode_json(\%succ_succ_obj);
            #print $succ_succ_obj{"ifStart"} . "\t" . $succ_succ_obj{"ifEnd"} . "\n";
          }
        }

        #print $objs{$succ_id} . "\n";
        ++$i;
      }
    }

    # calculate the rest until parse ends
    while (1) {
      #print $i . "\t" . $succ[$i] . "\n";
      if (!$succ[$i]) {
        last;
      }
      %succ = %{decode_json($succ[$i])};
      $succ_id = $succ{"id"};

      if (!$objs{$succ_id}) {
        ++$i;
        next;
      }

      %succ_obj = %{decode_json($objs{$succ_id})};

      if (!$succ_obj{"sentTime"}) {
        ++$i;
        next;
      }

      # obj is a download
      # calculate it's ...
      $succ_obj{"ifStart"} = $anchorTimeIf + $paramComp * ($succ_obj{"sentTime"} - $anchorTime);
      if ($isPercent == 1) {
        $succ_obj{"if"} = $paramNet * ($succ_obj{"receivedTime"} - $succ_obj{"sentTime"});
      } else {
        # TODO
        if ($isPercent == 2) { # DNS
          $succ_obj{"if"} = $succ_obj{"receivedTime"} - $succ_obj{"sentTime"} - $succ_obj{"dns"};
        } elsif ($isPercent == 3) { # TCP conn.
          $succ_obj{"if"} = $succ_obj{"receivedTime"} - $succ_obj{"sentTime"} - $succ_obj{"conn"};
        }
      }
      $succ_obj{"ifEnd"} = $succ_obj{"ifStart"} + $succ_obj{"if"};
      if ($succ_obj{"ifEnd"} > $pageEndif) {
        $pageEndIf = $succ_obj{"ifEnd"};
      }

      #print $succ_obj{"obj_id"} . "\n";
      #print $succ_obj{"url"} . "\n";
      #print $succ_id . "\t" . $succ_obj{"sentTime"} . "\t" .$succ_obj{"ifStart"} . "\t" . $succ_obj{"ifEnd"} . "\n";

      # push back
      $objs{$succ_id} = encode_json(\%succ_obj);

      ++$i;
    }

    # parse end
    if ($isPercent = 1) {
      $obj{"ifEnd"} = $anchorTimeIf + $paramComp * ($obj{"end"} - $anchorTime);
      $obj{"if"} = $obj{"ifEnd"} - $obj{"ifStart"};
    } else {
      $obj{"ifEnd"} = $anchorTimeIf + $paramComp * ($obj{"end"} - $anchorTime);
      $obj{"if"} = $obj{"ifEnd"} - $obj{"ifStart"};
    }
    # push back
   $objs{$id} = encode_json(\%obj);

    #print "parse:\t" . $obj{"ifStart"} . "\t" . $obj{"ifEnd"} . "\n";
  }

  # address the others by sort...
  my %undone = ();
  foreach $id (keys %objs) {
    %obj = %{decode_json($objs{$id})};
    if (!$obj{"if"}) {
      $ts = $obj{"start"};
      if ($obj{"obj_id"} =~ /comp/) {
        $ts = $obj{"startTime"};
      } elsif ($obj{"obj_id"} =~ /download/) {
        $ts = $obj{"sentTime"};
      }
      $undone{$ts} = $id;
    }
  }

  foreach $ts (sort {$a <=> $b} keys %undone) {
    $id = $undone{$ts};
    %obj = %{decode_json($objs{$id})};
    #print $ts . "\t" . $obj{"prev"} . "\n";
    if (!$obj{"prev"}) {
      next;
    }
    @prevs = @{decode_json($obj{"prev"})};
    $tempEnd = -1;
    foreach $prev (@prevs) {
      %prev = %{decode_json($prev)};
      $prev_id = $prev{"id"};
      if (!$objs{$prev_id}) {
        next;
      }
      %prev_obj = %{decode_json($objs{$prev_id})};
      #print $prev . "\n";
      if ($prev_id =~ /download/) {
        if ($prev_obj{"ifEnd"} > $tempEnd) {
          $tempEnd = $prev_obj{"ifEnd"};
        }
      } elsif ($prev_id =~ /comp/) {
        $ttt = $prev_obj{"ifStart"} + $paramComp * $prev{"rt"};
        if ($ttt > $tempEnd) {
          $tempEnd = $ttt;
        }
      }
    }

    # calculate it's ...
    $obj{"ifStart"} = $tempEnd;
    #if ($isPercent == 1) {
      if ($id =~ /download/) {
        $obj{"if"} = $paramNet * ($obj{"receivedTime"} - $obj{"sentTime"});
      } else {
        $obj{"if"} = $paramComp * ($obj{"endTime"} - $obj{"startTime"});
      }
    #} else {
      if ($isPercent == 2) {
        $obj{"if"} = $obj{"receivedTime"} - $obj{"sentTime"} - $obj{"dns"};
      } elsif ($isPercent == 3) {
        $obj{"if"} = $obj{"receivedTime"} - $obj{"sentTime"} - $obj{"conn"};
      }
    #}
    $obj{"ifEnd"} = $obj{"ifStart"} + $obj{"if"};
    #print $obj{"ifStart"} . "\t" . $obj{"ifEnd"} . "\n";
    if ($obj{"ifEnd"} > $pageEndIf) {
      $pageEndIf = $obj{"ifEnd"};
    }

    # push back
    $objs{$id} = encode_json(\%obj);
  }

  return $pageEndIf;
}

# Finds the critical part in the path, Utilized earlier.
sub criticalPathAnalysis {
  my ($self, $info, $parses) = @_;
  $info = $self->{_info};
  $url = $info->getPageUrl();
  $pageStart = $info->getPageStart();
  $pageEnd = $info->getPageEnd();
  $pageEndTime = ($pageEnd - $pageStart) * 1000;

  @resources = @{$info->getResources()};
  @parses = @{$self->{_parses}};
  @comps_post_l = @{$self->{_comps_post_l}};

  # find out the one with the highest end time
  %ret = %{$self->cpaFindLastActivity()};
  $obj = $ret{"obj"};
  $obj_end = $ret{"obj_end"};
  $obj_type = $ret{"obj_type"};

  print "pageEnd: " . $pageEndTime . "\n";
  my %ret;
  my $obj_prev = "{}";
  my %obj_domains;
  my @arr_domain_tcp_net_cp;
  my @arr_domain_tcp_net_all;
  my @act_timings;

  my $level = 0;
  my $time_comp = 0;
  my $time_block = 0;
  my $time_download = 0;

  my $download_blocking = 0;
  my $download_proxy = 0;
  my $download_dns = 0;
  my $download_conn = 0;
  my $download_ssl = 0;
  my $download_send = 0;
  my $download_receiveFirst = 0;
  my $download_receiveLast = 0;

  my $parse_style = 0;
  my $parse_script = 0;
  my $parse_layout = 0;
  my $parse_paint = 0;
  my $parse_other = 0;
  my $parse_undefined = 0;

  my $dep_D2E = 0;
  my $dep_E2D_html = 0;
  my $dep_E2D_css = 0;
  my $dep_E2D_js = 0;
  my $dep_E2D_timer = 0;
  my $dep_RFB = 0;
  my $dep_HOL_js = 0;
  my $dep_HOL_css = 0;

  my $time_download_html = 0;
  my $time_download_css = 0;
  my $time_download_js = 0;
  my $time_download_img = 0;
  my $time_download_o = 0;
  my $time_block_css = 0;
  my $time_block_js = 0;
  my $time_ttfb = 0;
  my $num_objs_cp = 0;
  my $num_bytes_cp = 0;
  my $num_send_cp = 0;
  my $num_conn_cp = 0;

  my $time_;
  while (1) {
    if (!$obj) {
      last;
    }
    %obj = %{decode_json($obj)};
    %obj_prev = %{decode_json($obj_prev)};
    $id = $obj{"critical"};
    $obj{"onCP"} = "y";

    $ret = $self->cpaCalculateDep(\%obj, \%obj_prev);
    %ret = %{$ret};
    $dep_D2E += $ret{"dep_D2E"};
    $dep_E2D_html += $ret{"dep_E2D_html"};
    $dep_E2D_css += $ret{"dep_E2D_css"};
    $dep_E2D_js += $ret{"dep_E2D_js"};
    $dep_E2D_timer += $ret{"dep_E2D_timer"};

    # Output ... info
    if ($obj_type eq "comp") {
      $comps_post_l[$obj{"index"}] = encode_json(\%obj);

      %actt = (
        "type", "parse",
        "url", $obj{"url"},
        "s", $obj{"startTime"},
        "e", $obj{"endTime"},
      );
      push(@act_timings, encode_json(\%actt));
      print $obj{"obj_id"} . " " . $obj{"urlRecalcStyle"} . "\n\n";

      if ($obj{"type"} eq "execScript") {
        $parse_script += $obj{"endTime"} - $obj{"startTime"};
      } elsif ($obj{"type"} eq "recalcStyle") {
        $parse_style += $obj{"endTime"} - $obj{"startTime"};
      }

    # downloads
    } elsif ($obj_type eq "download") {
      $resources[$obj{"index"}] = encode_json(\%obj);

      ++$level;
      ++$num_objs_cp;
      $num_bytes_cp += $obj{"len"};
      if ($obj{"send"}) {
        ++$num_send_cp;
      }
      if ($obj{"conn"}) {
        ++$num_conn_cp;
      }

      $endTime = $obj{"receivedTime"};
      if ($obj_prev{"startTime"} and $obj_prev{"startTime"} < $endTime) {
        $endTime = $obj_prev{"startTime"};
      }
      if ($obj_prev{"start"} and $obj_prev{"start"} < $endTime) {
        $endTime = $obj_prev{"start"};
      }
      $time_download += $endTime - $obj{"sentTime"};

      # classify download time according to mime type
      $mime = $obj{"mimeType"};
      if ($mime =~ /html/) {
        $time_download_html += $endTime - $obj{"sentTime"};
      } elsif ($mime =~ /javascript/) {
        $time_download_js += $endTime - $obj{"sentTime"};
      } elsif ($mime =~ /css/) {
        $time_download_css += $endTime - $obj{"sentTime"};
      } elsif ($mime =~ /image/) {
        $time_download_img += $endTime - $obj{"sentTime"};
      } else {
        $time_download_o += $endTime - $obj{"sentTime"};
      }

      # classify downloads according to whether it's ttfb
      if ($obj{"index"} == 0) {
        $time_ttfb = $endTime - $obj{"sentTime"};
      }

      # calculate # domains on the CP
      @a = split(/\//, $obj{"url"});
      $a = @a;
      if ($a >= 3) {
        if ($obj_domains{$a[2]}) {
          $obj_domains{$a[2]} += $endTime - $obj{"sentTime"};
        } else {
          $obj_domains{$a[2]} = $endTime - $obj{"sentTime"};
        }
      }

      # add dns and tcp conn. setup info
      my %ha = (
        "url", $obj{"url"},
        "dns", $obj{"dns"},
        "conn", $obj{"conn"},
        "net", $endTime - $obj{"sentTime"},
      );
      push(@arr_domain_tcp_net_cp, encode_json(\%ha));

      $download_blocking += $obj{"blocking"};
      $download_proxy += $obj{"proxy"};
      $download_dns += $obj{"dns"};
      $download_conn += $obj{"conn"};
      $download_ssl += $obj{"ssl"};
      $download_send += $obj{"send"};
      $download_receiveFirst += $obj{"receiveFirst"};
      $download_receiveLast += $endTime - $obj{"receiveHeadersEnd"} - $obj{"requestTime"};

      %actt = (
        "type", "download",
        "url", $obj{"url"},
        "s", $obj{"sentTime"},
        "e", $endTime,
      );
      push(@act_timings, encode_json(\%actt));
      print $obj{"obj_id"} . " " . $obj{"url"} . " " . $obj{"sentTime"} . " " . $endTime . "\n\n";

      if ($obj{"E2D_miss"}) {
        $parse_undefined += $obj{"E2D_miss"};
if (0) {
        print "E2D miss: " . $obj{"E2D_miss"} . "\n\n";
}
      }

    # parses
    } elsif ($obj_type eq "parse") {
      $parses[$obj{"index"}] = encode_json(\%obj);

      #print "cpaFindInner 1\n\n";
      $inner = $self->cpaFindInnerParser(\@obj, \@obj_prev);
      %inner = %{$inner};
      $time_block += $inner{"time_block"};
      @timings_block = @{$inner{"timings_block"}};
      $dep_D2E += $inner{"dep_D2E"};
      $dep_E2D_html += $inner{"dep_E2D_html"};
      $dep_RFB += $inner{"dep_RFB"};
      $dep_HOL_js += $inner{"dep_HOL_js"};
      $dep_HOL_css += $inner{"dep_HOL_css"};
      $time_block_js += $inner{"time_block_js"};
      $time_block_css += $inner{"time_block_css"};
      $num_objs_cp += $inner{"num_objs_cp"};
      $num_bytes_cp += $inner{"num_bytes_cp"};
      $num_send_cp += $inner{"num_send_cp"};
      $num_conn_cp += $inner{"num_conn_cp"};

      # calculate # domains on the CP
      foreach $b (@timings_block) {
        %b = %{decode_json($b)};
        @a = split(/\//, $b{"url"});
        $a = @a;
        if ($a >= 3) {
          if ($obj_domains{$a[2]}) {
            $obj_domains{$a[2]} += $b{"receivedTime"} - $b{"sentTime"};
          } else {
            $obj_domains{$a[2]} = $b{"receivedTime"} - $b{"sentTime"};
          }
        }
        # add dns and tcp conn. setup info
        my %ha = (
          "url", $b{"url"},
          "dns", $b{"dns"},
          "conn", $b{"conn"},
          "net", $b{"receivedTime"} - $b{"sentTime"},
        );
        push(@arr_domain_tcp_net_cp, encode_json(\%ha));
      }

      %actt = (
        "type", "parse",
        "url", $obj{"url"},
        "s", $obj{"start"},
        "e", $obj{"end"},
      );
      push(@act_timings, encode_json(\%actt));
      print $obj{"obj_id"} . " " . $obj{"url"} . " " . $obj{"start"} . " " . $obj{"end"} . "\n\n";

      @comps_during_l = @{$obj{"during_l"}};
      @comps_during_n = @{$obj{"during_n"}};

      #print "cpaFindInner 2\n\n";
      # Profile fine-grained computations within html parsing
      $inner_comps = $self->cpaFindInnerComps(\@comps_during_n, $obj{"start"}, $obj{"end"});
      %inner_comps = %{$inner_comps};
      $parse_style += $inner_comps{"parse_style"};
      $parse_script += $inner_comps{"parse_script"};
      $parse_layout += $inner_comps{"parse_layout"};
      $parse_paint += $inner_comps{"parse_paint"};
      foreach $timing (@timings_block) {
        %timing = %{decode_json($timing)};
        $s = $timing{"sentTime"};
        $e = $timing{"receivedTime"};
      #print "cpaFindInner 3\n\n";
        $inner_comps = $self->cpaFindInnerComps(\@comps_during_n, $s, $e);
        %inner_comps = %{$inner_comps};
        $parse_style -= $inner_comps{"parse_style"};
        $parse_script -= $inner_comps{"parse_script"};
        $parse_layout -= $inner_comps{"parse_layout"};
        $parse_paint -= $inner_comps{"parse_paint"};
      }

if (0) {
      print "style: " . $inner_comps{"parse_style"} . "\n";
      print "script: " . $inner_comps{"parse_script"} . "\n";
      print "layout: " . $inner_comps{"parse_layout"} . "\n";
      print "paint: " . $inner_comps{"parse_paint"} . "\n\n";
}

      $parse_other += $obj{"end"} - $obj{"start"} - $inner{"time_block"} - $inner_comps{"parse_style"} - $inner_comps{"parse_script"} - $inner_comps{"parse_layout"} - $inner_comps{"parse_paint"};
    }

    @a = split(/\_/, $id);
    $obj_type = $a[0];
    if (!$obj_type) {
      last;
    }

    $obj_prev = $obj;
    # Find obj by id
    if ($obj_type eq "comp") {
      $obj = $self->findCompById($id);
    } elsif ($obj_type eq "parse") {
      $obj = $self->findParseById($id);
    } elsif ($obj_type eq "download") {
      $obj = $self->findResourceById($id);
    }
  }

  $info->setResources(\@resources);
  $self->{_parses} = \@parses;
  $self->{_comps_post_l} = \@comps_post_l;

  # calculate # of domains on cp
  my $num_domains_cp = 0;
  my $text_domains_cp = encode_json(\%obj_domains);
  foreach $domain (keys %obj_domains) {
     #print $domain . "\t" . $obj_domains{$domain} . "\n";
     ++$num_domains_cp;
  }
  my %obj_domains = ();

  # calculate # of domains on cp
  my $num_objs_all = 0;
  my $num_bytes_all = 0;
  my $num_send_all = 0;
  my $num_conn_all = 0;
  foreach $resource (@resources) {
    ++$num_objs_all;
    %resource = %{decode_json($resource)};
    $num_bytes_all += $resource{"len"};
    if ($resource{"send"}) {
      ++$num_send_all;
    }
    if ($resource{"conn"}) {
      ++$num_conn_all;
    }

    $url = $resource{"url"};
    @a = split(/\//, $url);
    $a = @a;
    if ($a >= 3) {
      $obj_domains{$a[2]} = 1;
    }
    my %ha = (
      "url", $resource{"url"},
      "dns", $resource{"dns"},
      "conn", $resource{"conn"},
      "net", $resource{"receivedTime"} - $resource{"sentTime"},
    );
    push(@arr_domain_tcp_net_all, encode_json(\%ha));
  }

  my $num_domains_all = 0;
  foreach $domain (keys %obj_domains) {
    ++$num_domains_all;
  }
  my $text_domains_all = encode_json(\%obj_domains);

  my $text_domain_tcp_net_cp = encode_json(\@arr_domain_tcp_net_cp);
  my $text_domain_tcp_net_all = encode_json(\@arr_domain_tcp_net_all);
  #print $text_domain_tcp_net_cp . "\n";
  #print $text_domain_tcp_net_all . "\n";

  $ret{"level"} = $level;
  $ret{"time_download"} = $time_download;
  $ret{"time_block"} = $time_block;
  $ret{"time_comp"} = $pageEndTime - $time_download - $time_block;
  $ret{"download_blocking"} = $download_blocking;
  $ret{"download_proxy"} = $download_proxy;
  $ret{"download_dns"} = $download_dns;
  $ret{"download_conn"} = $download_conn;
  $ret{"download_ssl"} = $download_ssl;
  $ret{"download_send"} = $download_send;
  $ret{"download_receiveFirst"} = $download_receiveFirst;
  $ret{"download_receiveLast"} = $download_receiveLast;
  $ret{"parse_style"} = $parse_style;
  $ret{"parse_script"} = $parse_script;
  $ret{"parse_layout"} = $parse_layout;
  $ret{"parse_paint"} = $parse_paint;
  $ret{"parse_other"} = $parse_other;
  $ret{"parse_undefined"} = $parse_undefined;
  $ret{"dep_D2E"} = $dep_D2E;
  $ret{"dep_E2D_html"} = $dep_E2D_html;
  $ret{"dep_E2D_css"} = $dep_E2D_css;
  $ret{"dep_E2D_js"} = $dep_E2D_js;
  $ret{"dep_E2D_timer"} = $dep_E2D_timer;
  $ret{"dep_RFB"} = $dep_RFB;
  $ret{"dep_HOL_css"} = $dep_HOL_css;
  $ret{"dep_HOL_js"} = $dep_HOL_js;
  $ret{"time_download_html"} = $time_download_html;
  $ret{"time_download_css"} = $time_download_css;
  $ret{"time_download_js"} = $time_download_js;
  $ret{"time_download_img"} = $time_download_img;
  $ret{"time_download_o"} = $time_download_o;
  $ret{"time_block_css"} = $time_block_css;
  $ret{"time_block_js"} = $time_block_js;
  $ret{"time_ttfb"} = $time_ttfb;
  $ret{"num_domains_cp"} = $num_domains_cp;
  $ret{"num_domains_all"} = $num_domains_all;
  $ret{"text_domains_cp"} = $text_domains_cp;
  $ret{"text_domains_all"} = $text_domains_all;
  $ret{"num_send_cp"} = $num_send_cp;
  $ret{"num_send_all"} = $num_send_all;
  $ret{"num_conn_cp"} = $num_conn_cp;
  $ret{"num_conn_all"} = $num_conn_all;
  $ret{"num_bytes_cp"} = $num_bytes_cp;
  $ret{"num_bytes_all"} = $num_bytes_all;
  $ret{"num_objs_cp"} = $num_objs_cp;
  $ret{"num_objs_all"} = $num_objs_all;
  $ret{"text_domain_tcp_net_cp"} = $text_domain_tcp_net_cp;
  $ret{"text_domain_tcp_net_all"} = $text_domain_tcp_net_all;
  $ret{"act_timings"} = encode_json(\@act_timings);

  return \%ret;
}

# What is this doing??
sub cpaFindLastActivity {
  my ($self, $info, $parses) = @_;
  $info = $self->{_info};
  @resources = @{$info->getResources()};
  @parses = @{$self->{_parses}};
  @comps_post_l = @{$self->{_comps_post_l}};

  my $obj;
  my $obj_type;
  my $obj_end = 0;
  my $load = $self->{_load};
  my $delta = -0.00001;

  my $i = 0;
  foreach $resource (@resources) {
    %resource = %{decode_json($resource)};
    $resource{"index"} = $i;
    $resources[$i] = encode_json(\%resource);
    if ($resource{"receivedTime"} > $obj_end and $load - $resource{"receivedTime"} >= $delta) {
      $obj_end = $resource{"receivedTime"};
      $obj = $resource;
      $obj_type = "download";
    }
    ++$i;
  }
  $info->setResources(\@resources);

  my $i = 0;
  foreach $parse (@parses) {
    %parse = %{decode_json($parse)};
    $parse{"index"} = $i;
    $parses[$i] = encode_json(\%parse);
    if ($parse{"end"} > $obj_end and $load - $parse{"end"} >= $delta) {
      $obj_end = $parse{"end"};
      $obj = $parse;
      $obj_type = "parse";
    }
    ++$i;
  }
  $self->{_parses} = \@parses;

  my $i = 0;
  foreach $comp (@comps_post_l) {
    %comp = %{decode_json($comp)};
    $comp{"index"} = $i;
    $comps_post_l[$i] = encode_json(\%comp);
    if ($comp{"endTime"} > $obj_end and $load - $comp{"endTime"} >= $delta) {
      $obj_end = $comp{"endTime"};
      $obj = $comp;
      $obj_type = "comp";
    }
    ++$i;
  }
  $self->{_comps_post_l} = \@comps_post_l;

  my %ret;
  $ret{"obj"} = $obj;
  $ret{"obj_end"} = $obj_end;
  $ret{"obj_type"} = $obj_type;

  print "last: " . $obj_end . " " . $load . "\n";

  return \%ret;
}

# What??
sub cpaFindInnerParser {
  my ($self, $info, $parses) = @_;
  $info = $self->{_info};
  @resources = @{$info->getResources()};
  @parses = @{$self->{_parses}};
  @comps_post_l = @{$self->{_comps_post_l}};

  @obj = @{$_[1]};
  @obj_prev = @{$_[2]};
  my $time_block = 0;
  my @timings_block;
  my $dep_D2E = 0;
  my $dep_E2D_html = 0;
  my $dep_RFB = 0;
  my $dep_HOL_js = 0;
  my $dep_HOL_css = 0;
  my $time_block_css = 0;
  my $time_block_js = 0;
  my $num_objs_cp = 0;
  my $num_bytes_cp = 0;
  my $num_send_cp = 0;
  my $num_conn_cp = 0;

  if ($obj_prev{"obj_id"} =~ /download/) {
    @comps_during_l = @{$obj{"during_l"}};
    $num = @comps_during_l;
    my %prev = %obj_prev;
    my $critic_id;
    for ($i = $num - 1; $i >= 0; --$i) {
      #print "cpaFindInnerParser for $num $i\n\n";
      $comp = $comps_during_l[$i];
      %comp = %{decode_json($comp)};
      if ($prev{"sentTime"} > $comp{"startTime"} and $comp{"hol_type"} == 1) {
        #print "prev: " . $prev{"url"} . "\n";
        #print "comp: " . $comp{"urlRecalcStyle"} . "\n";
        #print $prev{"sentTime"} . " " . $comp{"startTime"} . "\n";
        #print $comp . "\n\n";

        # Find the downloaded resource
        $critic_id = $comp{"critical"};
        @a = split(/\_/, $critic_id);
        while ($a[0] ne "download") {
          if (!$a[0]) {
            last;
          }
          #print $critical_id . "\n";
          if ($a[0] eq "parse") {
            $prev = $self->findParseById($critic_id);
          } elsif ($a[0] eq "comp") {
            $prev = undef;
            foreach $c (@comps_during_l) {
              %c = %{decode_json($c)};
              if ($c{"obj_id"} eq $critic_id) {
                $prev = $c;
                last;
              }
            }
          }
          if (!$prev) {
            last;
          }
          %prev = %{decode_json($prev)};
          $critic_id = $prev{"critical"};
          @a = split(/\_/, $critic_id);
          #print $critic_id . " " . $prev . "\n\n";

          # Profile dependencies
          if ($critic_id =~ "download") {
            $dep_D2E++;
            $dep_E2D_html++; # split preload
            $dep_RFB++;
          } else {
            $dep_HOL_js++;
          }
        }

        # Find blocking time
        if ($a[0] eq "download") {
          $prev = $self->findResourceById($critic_id);
          %prev = %{decode_json($prev)};
          if ($prev{"mimeType"} =~ /html/) {
            next;
          }
          #print $comp . "\n";
          #print $prev{"mimeType"} . " " . $prev . "\n\n";
          #print $prev{"sentTime"} . " " . $prev{"receivedTime"} . "\n";
          $time_block += $prev{"receivedTime"} - $prev{"sentTime"};
          ++$num_objs_cp;
          $num_bytes_cp += $prev{"len"};
          if ($prev{"send"}) {
            ++$num_send_cp;
          }
          if ($prev{"conn"}) {
            ++$num_conn_cp;
          }

          # classify blocking time according to ...
          if ($prev{"mimeType"} =~ /javascript/) {
            $time_block_js += $prev{"receivedTime"} - $prev{"sentTime"};
          } elsif ($prev{"mimeType"} =~ /css/) {
            $time_block_css += $prev{"receivedTime"} - $prev{"sentTime"};
          }

          push(@timings_block, $prev);
        }
        #print $critic_id . "\n\n";
      }
    }
  }

  #print $dep_D2E . " " . $dep_HOL_js . "\n";

  my %ret;
  $ret{"time_block"} = $time_block;
  $ret{"timings_block"} = \@timings_block;
  $ret{"dep_D2E"} = $dep_D2E;
  $ret{"dep_E2D_html"} = $dep_E2D_html;
  $ret{"dep_RFB"} = $dep_RFB;
  $ret{"dep_HOL_js"} = $dep_HOL_js;
  $ret{"dep_HOL_css"} = $dep_HOL_css;
  $ret{"time_block_js"} = $time_block_js;
  $ret{"time_block_css"} = $time_block_css;
  $ret{"num_objs_cp"} = $num_objs_cp;
  $ret{"num_bytes_cp"} = $num_bytes_cp;
  $ret{"num_conn_cp"} = $num_conn_cp;
  $ret{"num_send_cp"} = $num_send_cp;
  return \%ret;
}

# InnerComps??
sub cpaFindInnerComps {
  my ($self, $info, $parses) = @_;
  $info = $self->{_info};
  @comps_during_n = @{$_[1]};
  $start = $_[2];
  $end = $_[3];

  # sanitize timings_block
  my $i = 0;
  foreach $comp (@comps_during_n) {
    %comp = %{decode_json($comp)};
    $cs = $comp{"startTime"};
    $ce = $comp{"endTime"};
  }

  my $parse_style = 0;
  my $parse_script = 0;
  my $parse_layout = 0;
  my $parse_paint = 0;

  my $parse_style_end = -1;
  my $parse_script_end = -1;
  my $parse_layout_end = -1;
  my $parse_paint_end = -1;

  foreach $comp (@comps_during_n) {
    %comp = %{decode_json($comp)};
    $s = $comp{"startTime"};
    $e = $comp{"endTime"};

    if ($e < $start or $s > $end) {
      next;
    }
    if ($s < $start) {
      $s = $start;
    }
    if ($e > $end) {
      $e = $end;
    }

    if ($comp{"type"} eq "recalcStyle") {
      # update others
      if ($s < $parse_script_end) {
        $parse_script -= $parse_script_end - $s;
        $parse_script_end = $s;
      }
      if ($s < $parse_layout_end) {
        $parse_layout -= $parse_layout_end - $s;
        $parse_layout_end = $s;
      }
      if ($s < $parse_paint_end) {
        $parse_paint -= $parse_paint_end - $s;
        $parse_paint_end = $s;
      }

      # update self
      if ($s > $parse_style_end) {
        $parse_style += $e - $s;
      } else {
        $parse_style += $e - $parse_style_end;
      }
      $parse_style_end = $e;

    } elsif ($comp{"type"} eq "execScript") {
      # update others
      if ($s < $parse_style_end) {
        $parse_style -= $parse_style_end - $s;
        $parse_style_end = $s;
      }
      if ($s < $parse_layout_end) {
        $parse_layout -= $parse_layout_end - $s;
        $parse_layout_end = $s;
      }
      if ($s < $parse_paint_end) {
        $parse_paint -= $parse_paint_end - $s;
        $parse_paint_end = $s;
      }

      # update self
      if ($s > $parse_script_end) {
        $parse_script += $e - $s;
      } else {
        $parse_script += $e - $parse_script_end;
      }
      $parse_script_end = $e;

    } elsif ($comp{"type"} eq "layout") {
      # update others
      if ($s < $parse_style_end) {
        $parse_style -= $parse_style_end - $s;
        $parse_style_end = $s;
      }
      if ($s < $parse_script_end) {
        $parse_script -= $parse_script_end - $s;
        $parse_script_end = $s;
      }
      if ($s < $parse_paint_end) {
        $parse_paint -= $parse_paint_end - $s;
        $parse_paint_end = $s;
      }

      # update self
      if ($s > $parse_layout_end) {
        $parse_layout += $e - $s;
      } else {
        $parse_layout += $e - $parse_layout_end;
      }
      $parse_layout_end = $e;

    } elsif ($comp{"type"} eq "paint") {
      # update others
      if ($s < $parse_style_end) {
        $parse_style -= $parse_style_end - $s;
        $parse_style_end = $s;
      }
      if ($s < $parse_script_end) {
        $parse_script -= $parse_script_end - $s;
        $parse_script_end = $s;
      }
      if ($s < $parse_layout_end) {
        $parse_layout -= $parse_layout_end - $s;
        $parse_layout_end = $s;
      }

      # update self
      if ($s > $parse_paint_end) {
        $parse_paint += $e - $s;
      } else {
        $parse_paint += $e - $parse_paint_end;
      }
      $parse_paint_end = $e;

    }
    #print $comp . "\n";
  }

  my %ret;
  $ret{"parse_style"} = $parse_style;
  $ret{"parse_script"} = $parse_script;
  $ret{"parse_layout"} = $parse_layout;
  $ret{"parse_paint"} = $parse_paint;
  return \%ret;
}

# Calculates the dependencies?
sub cpaCalculateDep {
  my ($self, $info, $parses) = @_;
  %obj = %{$_[1]};
  %obj_prev = %{$_[2]};

  my $dep_D2E = 0;
  my $dep_E2D_html = 0;
  my $dep_E2D_css = 0;
  my $dep_E2D_js = 0;
  my $dep_E2D_timer = 0;
  my $dep_RFB = 0;
  my $dep_HOL_js = 0;
  my $dep_HOL_css = 0;

  #print $obj{"obj_id"} . " " . $obj_prev{"obj_id"} . "\n";
  if ($obj{"obj_id"} =~ /download/ and $obj_prev{"obj_id"}) {
    $dep_D2E++;
  } elsif ($obj{"obj_id"} =~ /parse/ and $obj_prev{"obj_id"} =~ /download/) {
    if ($obj_prev{"E2D_miss"}) {
      $dep_E2D_timer++;
    } else {
      # find whether in comps
      @comps_during_l = @{$obj{"during_l"}};
      $found = 0;
      $s = $obj_prev{"sentTime"};
      foreach $comp (@comps_during_l) {
        %comp = %{decode_json($comp)};
        if ($s > $comp{"startTime"} and $s < $comp{"endTime"}) {
          #print $comp . "\n";
          if ($comp{"type"} eq "execScript") {
            $dep_E2D_js++;
          } else {
            $dep_E2D_css++;
          }
          $found = 1;
          last;
        }
      }
      if (!$found) {
        $dep_E2D_html++; # need to split preload
      }
    }
  } elsif ($obj{"obj_id"} =~ /comp/ and $obj_prev{"obj_id"} =~ /download/) {
    if ($obj{"type"} eq "execScript") {
      $dep_E2D_js++;
    } elsif ($obj{"type"} eq "recalcStyle") {
      $dep_E2D_css++;
    }
  }

  my %ret;
  $ret{"dep_D2E"} = $dep_D2E;
  $ret{"dep_E2D_html"} = $dep_E2D_html;
  $ret{"dep_E2D_css"} = $dep_E2D_css;
  $ret{"dep_E2D_js"} = $dep_E2D_js;
  $ret{"dep_E2D_timer"} = $dep_E2D_timer;
  return \%ret;
}

# Finds the resources for specific urls, used earlier on I believe.
sub findResourceByUrl {
  my ($self, $info, $parses) = @_;
  $info = $self->{_info};
  @resources = @{$info->getResources()};
  $url = $_[1];

  foreach $resource (@resources) {
    %resource = %{decode_json($resource)};
    if ($resource{"url"} eq $url) {
      return $resource;
    }
  }
  return undef;
}

# Finds the resources given the object id.
sub findResourceById {
  my ($self, $info, $parses) = @_;
  $info = $self->{_info};
  @resources = @{$info->getResources()};
  $obj_id = $_[1];

  foreach $resource (@resources) {
    %resource = %{decode_json($resource)};
    if ($resource{"obj_id"} eq $obj_id) {
      return $resource;
    }
  }
  return undef;
}

# Finds the Comp given the object id.
sub findCompById {
  my ($self, $info, $parses) = @_;
  @comps_post_l = @{$self->{_comps_post_l}};
  $obj_id = $_[1];

  foreach $comp (@comps_post_l) {
    %comp = %{decode_json($comp)};
    if ($comp{"obj_id"} eq $obj_id) {
      return $comp;
    }
  }
  return undef;
}

# Finds the parse given object id
sub findParseById {
  my ($self, $info, $parses) = @_;
  @parses = @{$self->{_parses}};
  $obj_id = $_[1];

  foreach $parse (@parses) {
    %parse = %{decode_json($parse)};
    if ($parse{"obj_id"} eq $obj_id) {
      return $parse;
    }
  }
  return undef;
}

1;
