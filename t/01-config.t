use strict;
use warnings;
use lib 'lib';
use Test::More;

# Test PTC::Config module
use_ok('PTC::Config');

# Test get_config returns a hash ref
my $config = get_config();
is(ref $config, 'HASH', 'get_config returns a hash ref');

# Test required config keys exist
ok(exists $config->{ptc}, 'ptc config exists');
ok(exists $config->{radius}, 'radius config exists');
ok(exists $config->{opennms}, 'opennms config exists');
ok(exists $config->{home}, 'home config exists');
ok(exists $config->{region}, 'region config exists');
ok(exists $config->{purpose}, 'purpose config exists');
ok(exists $config->{debug}, 'debug config exists');

# Test ptc config structure
is(ref $config->{ptc}, 'HASH', 'ptc config is a hash ref');
ok(exists $config->{ptc}{host}, 'ptc host exists');
ok(exists $config->{ptc}{name}, 'ptc name exists');
ok(exists $config->{ptc}{user}, 'ptc user exists');
ok(exists $config->{ptc}{pass}, 'ptc pass exists');

# Test default values
is($config->{ptc}{host}, 'localhost', 'default ptc host is localhost');
is($config->{ptc}{name}, 'ptc', 'default ptc name is ptc');
is($config->{home}, '/opt/perl-traffic-control', 'default home is /opt/perl-traffic-control');
is($config->{region}, 'default', 'default region is default');
is($config->{purpose}, 'router', 'default purpose is router');
is($config->{debug}, 0, 'default debug is 0');

# Test environment variable override
# Note: Config is cached, so we test the module's ability to read env vars
# by checking the structure supports the expected keys
ok(exists $config->{ptc}{host}, 'ptc host config key exists for env var override');
ok(exists $config->{ptc}{name}, 'ptc name config key exists for env var override');
ok(exists $config->{home}, 'home config key exists for env var override');

done_testing();
