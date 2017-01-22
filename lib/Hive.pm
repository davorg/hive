package Hive;

use Moose;
use Moose::Util::TypeConstraints;
use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Cookies;
use HTTP::Request::Common;
use URI;
use JSON;

subtype 'HiveURI'
  => as 'URI';

coerce 'HiveURI'
  => from 'Str'
  => via { URI->new($_) };

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
    agent      => 'bg-hive-api/1.0.5',
  );
}

has base_url => (
  is => 'ro',
  isa => 'HiveURI',
  default => 'https://api-prod.bgchprod.info/api',
  coerce => 1,
);

has user_url => (
  is => 'ro',
  isa => 'HiveURI',
  lazy_build => 1,
  coerce => 1,
);

sub _build_user_url {
  my $self = shift;
  return $self->base_url->as_string . '/users/' . $self->username;
}


has json => (
  is => 'ro',
  isa => 'JSON',
  lazy_build => 1,
);

sub _build_json {
  my $self = shift;
  return JSON->new->utf8;
}

has hubs => (
  is => 'ro',
  isa => 'ArrayRef[HashRef]',
  traits => ['Array'],
  handles => {
    all_hubs => 'elements',
  },
);

has devices => (
  is => 'ro',
);

sub BUILD {
  my $self = shift;

  $self->post('/login', {
    username => $self->username,
    password => $self->password,
  });

  $self->{hubs} = $self->get_and_decode('/hubs');

  foreach ($self->all_hubs) {
    $_->{data} = $self->get_and_decode("/hubs/$_->{id}");
  }

  $self->{devices} = $self->get_and_decode('/widgets/climate');
}

sub dump_temperature {
  my $self = shift;

  my $resp = $self->get('/widgets/temperature');
  return $resp->content;
}

sub get_temperature {
  my $self = shift;

  my $dat = $self->get_and_decode('/widgets/temperature');
  return "Inside: $dat->{inside}{now}$dat->{temperatureUnit}\n" .
         "Outside: $dat->{outside}{now}$dat->{temperatureUnit}";
}

sub dump_target_temperature {
  my $self = shift;

  my $resp = $self->get('/widgets/climate/targetTemperature');
  return $resp->content;
}

sub get_target_temperature {
  my $self = shift;

  my $dat = $self->get_and_decode('/widgets/climate/targetTemperature');
  return $dat->{temperature} . $dat->{formatting}{temperatureUnit};
}

sub get {
  my $self = shift;

  my $url = $self->user_url . shift;

  my $req = GET $url;
  my $resp = $self->ua->request($req);
  return $resp if $resp->is_success;
  die $resp->status_line;
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
