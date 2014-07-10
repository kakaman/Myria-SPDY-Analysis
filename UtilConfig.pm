#!/usr/bin/perl
# ------------------------------------------------------
# Read parameters from config
#
# We use singleton to implement this.
# ------------------------------------------------------

package UtilConfig;

use Switch;

sub new {
  my $class = shift;
  my $instance;
  my $self = {
    _instance => undef,
    _config => undef,
  };
  bless $self, $class;
  $self->{_instance} = $self;
  $self->{_config} = $self->readFromFile();

  return $self;
}

sub getInstance {
  my ($self, $instance) = @_;
  if (!$self->{_instance}) {
    $self->{_instance} = new UtilConfig();
  }
  return $self->{_instance};
}

sub readFromFile {
  my %hash_ret;

  open FP, "config";
  while (my $line = <FP>) {
    if (!$line) {
      next;
    }
    if ($line =~ /^#/) {
      next;
    }
    # get to the real content
    @arr = split(/\n/, $line);
    @arr = split(/\t/, $arr[0]);
    $hash_ret{$arr[0]} = $arr[1];
  }

  return \%hash_ret;
}

sub getConfig {
  my ($self, $config) = @_;
  return $self->{_config};
}

1;
