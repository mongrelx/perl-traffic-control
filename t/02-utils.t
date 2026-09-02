use strict;
use warnings;
use lib 'lib';
use Test::More;

# Skip if DBI not available
eval { require DBI };
if ($@) {
    plan skip_all => 'DBI not installed';
}

# Test PTC::Utils module loads
use_ok('PTC::Utils');

# Test exported functions exist
ok(defined &loadConfig, 'loadConfig function is exported');
ok(defined &printDebug, 'printDebug function is exported');
ok(defined &getCurrentLoad, 'getCurrentLoad function is exported');
ok(defined &isInSubnet, 'isInSubnet function is exported');
ok(defined &round, 'round function is exported');

# Test isInSubnet function
ok(isInSubnet('192.168.1.0/24', '192.168.1.100'), 'IP in subnet returns true');
ok(!isInSubnet('192.168.1.0/24', '192.168.2.100'), 'IP not in subnet returns false');
ok(isInSubnet('10.0.0.0/8', '10.1.2.3'), 'IP in /8 subnet returns true');
ok(!isInSubnet('10.0.0.0/8', '172.16.0.1'), 'IP not in /8 subnet returns false');

# Test round function
is(round(3.14159), '3.1', 'round function rounds to 1 decimal');
is(round(2.0), '2.0', 'round function preserves .0');
is(round(9.99), '10.0', 'round function rounds up correctly');

# Test getCurrentLoad returns a number
my $load = getCurrentLoad();
like($load, qr/^\d+\.\d+$/, 'getCurrentLoad returns a decimal number');

done_testing();
