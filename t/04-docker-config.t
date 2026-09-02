use strict;
use warnings;
use Test::More;

# Test Docker configuration files exist
my @required_files = qw(
    Dockerfile
    docker-compose.yml
    docker-entrypoint.sh
    .env.example
    .gitignore
    sql/init.sql
);

for my $file (@required_files) {
    ok(-f $file, "$file exists");
}

# Test Dockerfile has required content
open my $fh, '<', 'Dockerfile' or die "Cannot open Dockerfile: $!";
my $dockerfile = do { local $/; <$fh> };
close $fh;

like($dockerfile, qr/FROM perl:/, 'Dockerfile uses Perl base image');
like($dockerfile, qr/iptables/, 'Dockerfile installs iptables');
like($dockerfile, qr/nftables/, 'Dockerfile includes nftables');
like($dockerfile, qr/WORKDIR/, 'Dockerfile sets WORKDIR');
like($dockerfile, qr/ENTRYPOINT/, 'Dockerfile has ENTRYPOINT');

# Test docker-compose.yml has required services
open $fh, '<', 'docker-compose.yml' or die "Cannot open docker-compose.yml: $!";
my $compose = do { local $/; <$fh> };
close $fh;

like($compose, qr/services:/, 'docker-compose has services section');
like($compose, qr/db:/, 'docker-compose has db service');
like($compose, qr/app:/, 'docker-compose has app service');
like($compose, qr/NET_ADMIN/, 'docker-compose grants NET_ADMIN capability');

# Test .env.example has required variables
open $fh, '<', '.env.example' or die "Cannot open .env.example: $!";
my $env_example = do { local $/; <$fh> };
close $fh;

like($env_example, qr/PTC_DB_HOST/, '.env.example has PTC_DB_HOST');
like($env_example, qr/PTC_DB_NAME/, '.env.example has PTC_DB_NAME');
like($env_example, qr/PTC_DB_USER/, '.env.example has PTC_DB_USER');
like($env_example, qr/PTC_DB_PASSWORD/, '.env.example has PTC_DB_PASSWORD');

# Test SQL init script
open $fh, '<', 'sql/init.sql' or die "Cannot open sql/init.sql: $!";
my $sql = do { local $/; <$fh> };
close $fh;

like($sql, qr/CREATE TABLE.*blacklist/, 'SQL creates blacklist table');
like($sql, qr/CREATE TABLE.*routerConfig/, 'SQL creates routerConfig table');
like($sql, qr/CREATE TABLE.*sessions/, 'SQL creates sessions table');
like($sql, qr/CREATE TABLE.*radcheck/, 'SQL creates radcheck table');
like($sql, qr/CREATE TABLE.*radreply/, 'SQL creates radreply table');

done_testing();
