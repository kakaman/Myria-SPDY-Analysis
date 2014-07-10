#!/usr/bin/perl
# ------------------------------------------------------
# Read parameters from domain2continent
#
# We use singleton to implement this.
# ------------------------------------------------------

package UtilDomain;

use Switch;
use UtilConfig;

sub new {
  my $class = shift;
  my $instance;
  my $self = {
    _instance => undef,
    _domain_geo => undef,
  };
  bless $self, $class;
  $self->{_instance} = $self;
  $self->{_domain_geo} = $self->readFromFile();

  return $self;
}

sub getInstance {
  my ($self, $instance) = @_;
  if (!$self->{_instance}) {
    $self->{_instance} = new UtilDomain();
  }
  return $self->{_instance};
}

sub readFromFile {
  my ($self, $instance) = @_;
  my %hash_ret;

  open FP, UtilConfig->getInstance()->getConfig()->{"FileDomainGeo"};
  while (my $line = <FP>) {
    @arr = split(/\n/, $line);
    @arr = split(/\t/, $arr[0]);
    $hash_ret{$arr[0]} = $arr[1];
  }
  close FP;

  return \%hash_ret;
}

sub getDomainGeo {
  my ($self, $domain_geo) = @_;
  return $self->{_domain_geo};
}

1;
