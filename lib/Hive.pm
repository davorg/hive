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

  $self->post('/login', {
    username => $self->username,
    password => $self->password,
  })
}

sub get_temperature {
  my $self = shift;

  return $self->get_and_decode('/widgets/temperature');
}

sub get_target_temperature {
  my $self = shift;

  return $self->get_and_decode('/widgets/climate/targetTemperature');
}

sub get {
  my $self = shift;

  my $url = $self->base_url . '/users/' . $self->username . shift;

  my $req = GET $url;
  $self->ua->request($req);
}

sub get_and_decode {
  my $self = shift;

  return $self->json->decode($self->get(@_)->content);
}

sub post {
  my $self = shift;

  my $url = $self->base_url . shift;
  my $args = @_ ? shift : {};
  my $req = POST $url, [ %$args ];
  return $self->ua->request($req);
}

1;
