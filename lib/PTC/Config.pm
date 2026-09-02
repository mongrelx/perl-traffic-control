package PTC::Config;

use strict;
use warnings;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(get_config get_dbh get_radius_dbh get_opennms_dbh);

my $config;

sub get_config {
    return $config if $config;

    $config = {
        ptc => {
            host => $ENV{PTC_DB_HOST} || 'localhost',
            name => $ENV{PTC_DB_NAME} || 'ptc',
            user => $ENV{PTC_DB_USER} || 'ptc_user',
            pass => $ENV{PTC_DB_PASSWORD} || 'ptc_pass',
        },
        radius => {
            host => $ENV{PTC_RADIUS_DB_HOST} || 'localhost',
            name => $ENV{PTC_RADIUS_DB_NAME} || 'radius',
            user => $ENV{PTC_RADIUS_DB_USER} || 'radius',
            pass => $ENV{PTC_RADIUS_DB_PASSWORD} || 'radpass',
        },
        opennms => {
            host => $ENV{PTC_OPENNMS_DB_HOST} || 'localhost',
            name => $ENV{PTC_OPENNMS_DB_NAME} || 'opennms',
            user => $ENV{PTC_OPENNMS_DB_USER} || 'opennms',
            pass => $ENV{PTC_OPENNMS_DB_PASSWORD} || 'opennms',
        },
        home => $ENV{PTC_HOME} || '/opt/perl-traffic-control',
        region => $ENV{PTC_REGION} || 'default',
        purpose => $ENV{PTC_PURPOSE} || 'router',
        debug => $ENV{PTC_DEBUG} || 0,
    };

    return $config;
}

sub get_dbh {
    my $cfg = get_config()->{ptc};
    return DBI->connect(
        "DBI:mysql:database=$cfg->{name};host=$cfg->{host}",
        $cfg->{user},
        $cfg->{pass},
        { RaiseError => 1, PrintError => 0 }
    );
}

sub get_radius_dbh {
    my $cfg = get_config()->{radius};
    return DBI->connect(
        "DBI:mysql:database=$cfg->{name};host=$cfg->{host}",
        $cfg->{user},
        $cfg->{pass},
        { RaiseError => 1, PrintError => 0 }
    );
}

sub get_opennms_dbh {
    my $cfg = get_config()->{opennms};
    return DBI->connect(
        "DBI:Pg:database=$cfg->{name};host=$cfg->{host}",
        $cfg->{user},
        $cfg->{pass},
        { RaiseError => 1, PrintError => 0 }
    );
}

1;
