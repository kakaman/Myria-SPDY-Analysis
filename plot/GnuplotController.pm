#!/usr/bin/perl

package GnuplotController;

use Gnuplot;
use JSON;

sub new {
  my $class = shift;

  #my $config = UtilConfig->getInstance()->getConfig();
  my $config = undef;

  my $self = {
    _config => $config,
    _control_data => $_[0],
  };
  bless $self, $class;

  return $self;
}


sub run {
  my ($self, $paths, $config, $control_data) = @_;

  @data = @{$self->{_control_data}};

  foreach $d (@data) {
    $g = new Gnuplot();

    if ($d->{size}) {
      @v = @{$d->{size}};
      $g->setSize($v[0], $v[1]);
    }
    if ($d->{lineWidth}) {
      $g->setLineWidth($d->{lineWidth});
    }
    if ($d->{grid}) {
      @v = @{$d->{grid}};
      $g->setGrid($v[0], $v[1]);
    }


    if ($d->{xrange}) {
      $g->setXrange($d->{xrange});
    }
    if ($d->{yrange}) {
      $g->setYrange($d->{yrange});
    }

    if ($d->{xtics}) {
      $g->setXtics($d->{xtics});
    }
    if ($d->{ytics}) {
      $g->setYtics($d->{ytics});
    }

    ####### must include
    $g->setXlabel($d->{xlabel});
    $g->setYlabel($d->{ylabel});
    $g->setFilename($d->{filename});
    $g->setPlot($d->{plot});

    $g->output();
  }
}

1;
