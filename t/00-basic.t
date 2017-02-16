use Test::More;
use Test::Exception;

BEGIN {
  use_ok('WebService::Hive');
}

throws_ok { my $hive = WebService::Hive->new }
  qr/Attribute .+ is required/,
  'Username and password are required';

done_testing;
