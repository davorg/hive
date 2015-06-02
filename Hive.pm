package Hive;

use Moose;
use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Cookies;
use HTTP::Request::Common;

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

sub BUILD {
  my $self = shift;

  my $req = POST $self->base_url . '/login',
               [ username => $self->username, password => $self->password ];
  $self->ua->request($req);
}

sub get_user {
  my $self = shift;

  my $req = GET $self->base_url . '/users/'. $self->username;
  return $self->ua->request($req)->as_string;
}

1;
