package Hive;

use Moose;
use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Cookies;
use HTTP::Request::Common;
use JSON;

has username => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);

has password => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);

has ua => (
  is => 'ro',
  isa => 'LWP::UserAgent',
  lazy_build => 1,
);

sub _build_ua {
  my $self = shift;

  LWP::UserAgent->new(
    cookie_jar => HTTP::Cookies->new,
  );
}

has base_url => (
  is => 'ro',
  isa => 'Str',
  default => 'https://api.hivehome.com/v5/',
);

has json => (
  is => 'ro',
  isa => 'JSON',
  lazy_build => 1,
);

sub _build_json {
  my $self = shift;
  return JSON->new->utf8;
}


sub BUILD {
  my $self = shift;

  my $req = POST $self->base_url . '/login',
               [ username => $self->username, password => $self->password ];
  $self->ua->request($req);
}

sub get_temperature {
  my $self = shift;

  return $self->get('/widgets/temperature');
}

sub get_target_temperature {
  my $self = shift;

  return $self->get('/widgets/climate/targetTemperature');
}

sub get {
  my $self = shift;

  my $url = $self->base_url . '/users/' . $self->username . shift;

  my $req = GET $url;
  return $self->json->decode($self->ua->request($req)->content);
}


1;
