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

package Gnuplot;

sub new {
  my $class = shift;

  #my $config = UtilConfig->getInstance()->getConfig();
  my $config = undef;

  my $self = {
    _config => $config,
  };
  bless $self, $class;

  $self->default();

  return $self;
}

sub default {
  my ($self, $paths, $config) = @_;

  # size
  $self->{_width} = 0.6;
  $self->{_height} = 0.4;

  # line width
  $self->{_lw} = 4;
  $self->_setLines();

  # key
  $self->_setKey();

  # tics
  @range = (0, 1);
  $self->{_xtics} = undef;
  $self->{_ytics} = undef;
  $self->{_xrange} = \@range;
  $self->{_yrange} = \@range;

  # grid
  $self->{_grid_x} = 0;
  $self->{_grid_x} = 0;

  # labels
  $self->{_xlabel_offset_x} = 0;
  $self->{_xlabel_offset_y} = 0.3;
  $self->{_ylabel_offset_x} = 2;
  $self->{_ylabel_offset_y} = 0;
  $self->{_xlabel} = undef;
  $self->{_ylabel} = undef;

  # filename
  $self->{_filename} = undef;
  $self->{_fig_folder} = "fig";
  $self->{_gnu_folder} = "gnu";

  # plot
  $self->{_plot} = undef;
}

sub setSize {
  my ($self, $paths, $config) = @_;

  $self->{_width} = $_[1];
  $self->{_height} = $_[2];
}

sub setLineWidth {
  my ($self, $paths, $config) = @_;

  $self->{_lw} = $_[1];
  $self->_setLines();
}

sub setGrid {
  my ($self, $paths, $config) = @_;
  $self->{_grid_x} = $_[1];
  $self->{_grid_y} = $_[2];
}

sub setXtics {
  my ($self, $paths, $config) = @_;
  $self->{_xtics} = $_[1];
}

sub setYtics {
  my ($self, $paths, $config) = @_;
  $self->{_ytics} = $_[1];
}

sub setXrange {
  my ($self, $paths, $config) = @_;
  $self->{_xrange} = $_[1];
}

sub setYrange {
  my ($self, $paths, $config) = @_;
  $self->{_yrange} = $_[1];
}

sub setXlabel {
  my ($self, $paths, $config) = @_;
  $self->{_xlabel} = $_[1];
  if ($_[2]) {
    $self->{_xlabel_offset_x} = $_[2];
  }
  if ($_[3]) {
    $self->{_xlabel_offset_y} = $_[3];
  }
}

sub setYlabel {
  my ($self, $paths, $config) = @_;
  $self->{_ylabel} = $_[1];
  if ($_[2]) {
    $self->{_ylabel_offset_x} = $_[2];
  }
  if ($_[3]) {
    $self->{_ylabel_offset_y} = $_[3];
  }
}

sub setFilename {
  my ($self, $paths, $config) = @_;
  $self->{_filename} = $_[1];
}

sub setPlot {
  my ($self, $paths, $config) = @_;
  $self->{_plot} = $_[1];
}

sub _setLines {
  my ($self, $paths, $config) = @_;
  my %s = (
    1, [1, "black"],
    2, [1, "green"],
    3, [1, "red"],
    4, [1, "black"],
    5, [1, "orange"],
    6, [1, "gray90"],
    7, [1, "cyan"],
    11, [2, "black"],
    12, [2, "green"],
    13, [2, "red"],
    14, [2, "blue"],
    15, [2, "orange"],
    16, [2, "gray90"],
    17, [2, "cyan"],
    21, [4, "black"],
    22, [4, "green"],
    23, [4, "red"],
    24, [4, "blue"],
    25, [4, "orange"],
    26, [4, "gray90"],
    27, [4, "cyan"],
  );
  $self->{_style} = \%s;
}

sub _setKey {
  my ($self, $paths, $config) = @_;
  my %s = (
    "hasKey", 1,
    "place", "ins vert",
    "position", "bottom right",
  );
  $self->{_key} = \%s;
}

sub output {
  my ($self, $paths, $config) = @_;

  my $out = "";

  # size
  $out .= "set size " . $self->{_width} . ", " . $self->{_height} . "\n";

  # line types
  %s = %{$self->{_style}};
  foreach $style (keys %s) {
    @v = @{$s{$style}};
    $out .= "set style line " . $style . " lt " . $v[0] . " lc rgb \"" . $v[1] . "\" lw " . $self->{_lw} . "\n";
  }

  # key
  %key = %{$self->{_key}};
  if ($key{"hasKey"}) {
    $out .= "set key default\n";
    if ($key{"place"}) {
      $out .= "set key " . $key{"place"} . "\n";
    }
    if ($key{"position"}) {
      $out .= "set key " . $key{"position"} . "\n";
    }
  }

  # grid
  if ($self->{_grid_x} or $self->{_grid_y}) {
    $tmp = "set grid";
    if ($self->{_grid_x}) {
      $tmp .= " xtics";
    }
    if ($self->{_grid_y}) {
      $tmp .= " ytics";
    }
    $out .= $tmp . "\n";
  }

  # tics and ranges
  if ($self->{_xrange}) {
    @v = @{$self->{_xrange}};
    $out .= "set xrange [" . $v[0] . ":" . $v[1] . "]\n";
  }
  if ($self->{_yrange}) {
    @v = @{$self->{_yrange}};
    $out .= "set yrange [" . $v[0] . ":" . $v[1] . "]\n";
  }
  if ($self->{_xtics}) {
    @v = @{$self->{_xtics}};
    $n = @v;
    if ($n > 1) {
      $tmp = "";
      $i = 0;
      foreach $vv (@v) {
        ++$i;
        $tmp .= $vv;
        if ($i < $n) {
          $tmp .= ", ";
        }
      }
      $out .= "set xtics (" . $tmp . ")\n";
    }
  }
  if ($self->{_ytics}) {
    @v = @{$self->{_ytics}};
    $n = @v;
    if ($n > 1) {
      $tmp = "";
      $i = 0;
      foreach $vv (@v) {
        ++$i;
        $tmp .= $vv;
        if ($i < $n) {
          $tmp .= ", ";
        }
      }
      $out .= "set ytics (" . $tmp . ")\n";
    }
  }

  # labels
  if ($self->{_xlabel}) {
    $out .= "set xlabel \"" . $self->{_xlabel} . "\" offset " . $self->{_xlabel_offset_x} . ", " . $self->{_xlabel_offset_y} . "\n";
  }
  if ($self->{_ylabel}) {
    $out .= "set ylabel \"" . $self->{_ylabel} . "\" offset " . $self->{_ylabel_offset_x} . ", " . $self->{_ylabel_offset_y} . "\n";
  }

  # filename
  if ($self->{_filename}) {
    $out .= "set term post eps\n";
    $out .= "set output'" . $self->{_fig_folder} . "/" . $self->{_filename} . ".eps'\n";
  }

  # plot
  if ($self->{_plot}) {
    %p = %{$self->{_plot}};
    $n = keys %p;
    $i = 0;
    foreach $pp (keys %p) {
      @v = @{$p{$pp}};
      ++$i;
      if ($i == 1) {
        $out .= "plot ";
      }
      $out .= "'" . $pp . "' w l ls " . $v[0] . " title '" . $v[1] . "'";
      if ($i < $n) {
        $out .= ", \\";
      }
      $out .= "\n";
    }
  }

  # save to file
  $gnufile = $self->{_gnu_folder} . "/" . $self->{_filename} . ".gnu";
  open FP, ">$gnufile";
  print FP $out;
  close FP;

  # execute
  print `gnuplot $gnufile`;

  #print $out;
}

1;
