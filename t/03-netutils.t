use strict;
use warnings;
use lib 'lib';
use Test::More;

# Test PTC::NetUtils module loads
use_ok('PTC::NetUtils');

# Test exported functions exist
ok(defined &addBlackListItem, 'addBlackListItem function is exported');
ok(defined &addBlackListDB, 'addBlackListDB function is exported');
ok(defined &loadBlackList, 'loadBlackList function is exported');
ok(defined &loadBlackListDB, 'loadBlackListDB function is exported');
ok(defined &closeBlackListItem, 'closeBlackListItem function is exported');
ok(defined &closeBlackListDB, 'closeBlackListDB function is exported');
ok(defined &setBlackListDBReadTime, 'setBlackListDBReadTime function is exported');

# Test REASONS array
ok(@PTC::NetUtils::REASONS > 0, 'REASONS array is defined');
is(scalar @PTC::NetUtils::REASONS, 6, 'REASONS has 6 entries');

# Test REASONS content
my @expected_reasons = qw(SPAM WORM ABUSE COPYRIGHT MESSAGE LOCKED);
is_deeply(\@PTC::NetUtils::REASONS, \@expected_reasons, 'REASONS contains expected values');

done_testing();
