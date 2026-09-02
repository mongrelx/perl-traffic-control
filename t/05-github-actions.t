use strict;
use warnings;
use Test::More;

# Test GitHub Actions workflow files exist
my @workflows = qw(
    .github/workflows/ci.yml
    .github/workflows/docker.yml
);

for my $file (@workflows) {
    ok(-f $file, "$file exists");
}

# Test CI workflow content
open my $fh, '<', '.github/workflows/ci.yml' or die "Cannot open ci.yml: $!";
my $ci = do { local $/; <$fh> };
close $fh;

like($ci, qr/name: CI/, 'CI workflow has correct name');
like($ci, qr/perl-syntax/, 'CI has perl-syntax job');
like($ci, qr/perl-critic/, 'CI has perl-critic job');
like($ci, qr/unit-tests/, 'CI has unit-tests job');
like($ci, qr/docker-build/, 'CI has docker-build job');
like($ci, qr/prove -v t\//, 'CI runs tests with prove');

# Test Docker workflow content
open $fh, '<', '.github/workflows/docker.yml' or die "Cannot open docker.yml: $!";
my $docker = do { local $/; <$fh> };
close $fh;

like($docker, qr/name: Docker Image/, 'Docker workflow has correct name');
like($docker, qr/build-and-push/, 'Docker has build-and-push job');
like($docker, qr/ghcr\.io/, 'Docker uses GitHub Container Registry');
like($docker, qr/linux\/amd64,linux\/arm64/, 'Docker builds for multiple platforms');

done_testing();
