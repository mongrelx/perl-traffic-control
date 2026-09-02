#!/bin/bash
set -e

# Generate config from environment variables
cat > /opt/ptc/etc/www.conf << EOF
main::purpose=${PTC_PURPOSE:-router}
main::region=${PTC_REGION:-default}
main::regions=${PTC_REGIONS:-}
EOF

# Generate database config
cat > /opt/ptc/etc/db.conf << EOF
ptc_host=${PTC_DB_HOST:-localhost}
ptc_table=${PTC_DB_NAME:-ptc}
ptc_user=${PTC_DB_USER:-ptc_user}
ptc_pass=${PTC_DB_PASSWORD:-ptc_pass}
radius_host=${PTC_RADIUS_DB_HOST:-localhost}
radius_db=${PTC_RADIUS_DB_NAME:-radius}
radius_user=${PTC_RADIUS_DB_USER:-radius}
radius_pass=${PTC_RADIUS_DB_PASSWORD:-radpass}
EOF

# Wait for database to be ready
echo "Waiting for database..."
until perl -MDBI -e "DBI->connect('DBI:mysql:database=${PTC_DB_NAME:-ptc};host=${PTC_DB_HOST:-localhost}', '${PTC_DB_USER:-ptc_user}', '${PTC_DB_PASSWORD:-ptc_pass}')" 2>/dev/null; do
    sleep 2
done
echo "Database ready."

# Execute the main command
exec "$@"
