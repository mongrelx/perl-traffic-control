# perl-traffic-control

Perl QoS and traffic shaping for ISP management.

## Features

- RRD logging & graphing
- Webmin module
- Curses interface
- Captive portal
- Scales up to 2000 users
- Per-device or per-user bandwidth control
- Blacklist management
- Timed events

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   ptc-app   │────▶│    ptc-db   │◀────│  ptc-radius │
│  (Perl QoS) │     │  (MySQL 8)  │     │ (FreeRADIUS)│
└─────────────┘     └─────────────┘     └─────────────┘
```

## Quick Start (Docker)

1. Clone the repository:
   ```bash
   git clone https://github.com/mongrelx/perl-traffic-control.git
   cd perl-traffic-control
   ```

2. Create your environment file:
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

3. Start the services:
   ```bash
   docker-compose up -d
   ```

4. Check the status:
   ```bash
   docker-compose ps
   ```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PTC_DB_HOST` | `db` | MySQL host for PTC database |
| `PTC_DB_NAME` | `ptc` | PTC database name |
| `PTC_DB_USER` | `ptc_user` | PTC database user |
| `PTC_DB_PASSWORD` | `ptc_pass` | PTC database password |
| `PTC_RADIUS_DB_HOST` | `db` | MySQL host for RADIUS database |
| `PTC_RADIUS_DB_NAME` | `radius` | RADIUS database name |
| `PTC_RADIUS_DB_USER` | `radius` | RADIUS database user |
| `PTC_RADIUS_DB_PASSWORD` | `radpass` | RADIUS database password |
| `PTC_OPENNMS_DB_HOST` | `localhost` | PostgreSQL host for OpenNMS (optional) |
| `PTC_OPENNMS_DB_NAME` | `opennms` | OpenNMS database name |
| `PTC_OPENNMS_DB_USER` | `opennms` | OpenNMS database user |
| `PTC_OPENNMS_DB_PASSWORD` | `opennms` | OpenNMS database password |
| `PTC_REGION` | `default` | Region configuration |
| `PTC_PURPOSE` | `router` | Purpose (router/nms/mail) |
| `PTC_DEBUG` | `0` | Debug level |
| `PTC_HOME` | `/opt/perl-traffic-control` | Application home directory |
| `MYSQL_ROOT_PASSWORD` | `changeme` | MySQL root password (Docker) |

### Configuration Files

- `etc/www.conf` - Main configuration (generated from environment)
- `etc/AAA/<region>.AAA.conf` - Regional configuration
- `etc/default.conf` - Default settings

## Bare Metal Installation

### Requirements

- Linux kernel with HTB support
- MySQL >= 4.0.0
- HTTP server
- iptables
- Perl >= 5.0

### Debian 11/12

```bash
apt-get install libdbi-perl librrdtool-oo-perl \
    libdbd-mysql-perl mysql-server freeradius-mysql libauthen-radius-perl \
    libcurses-perl libjson-perl libsnmp-perl libsnmp-session-perl \
    libexporter-autoclean-perl libtry-tiny-perl libwww-perl

cpanm Curses::Application

cd /opt/
git clone https://github.com/mongrelx/perl-traffic-control.git
```

### Database Setup

```bash
mysqladmin create ptc -p
mysqladmin create ptc_auth -p

mysql -p <<EOF
GRANT ALL PRIVILEGES ON ptc.* TO 'ptc_user'@'%' IDENTIFIED BY 'ptc_pass';
GRANT ALL PRIVILEGES ON ptc_auth.* TO 'ptc_user'@'%' IDENTIFIED BY 'ptc_pass';
EOF

# For Debian 11+
mysql -p ptc_auth < /etc/freeradius/3.0/mods-config/sql/main/mysql/schema.sql
```

### Configuration

1. Set environment variables or edit `etc/www.conf`
2. Configure your network in `etc/AAA/<region>.AAA.conf`
3. Generate iptables rules:
   ```bash
   bin/iptable-basic > /etc/iptables.up.rules
   iptables-restore < /etc/iptables.up.rules
   ```

## Usage

### Curses Interface

```bash
perl -Ilib bin/InfoScreen
```

### Web Interface

Configure your HTTP server to serve the `bin/` directory with CGI support.

## Security Notes

- Change all default passwords in production
- Use environment variables for credentials in Docker
- The app container requires `NET_ADMIN` and `NET_RAW` capabilities
- Consider using Docker secrets for sensitive values

## License

See [LICENSE](LICENSE) file.
