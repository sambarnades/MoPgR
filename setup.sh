#!/bin/bash
set -x

# --- Configuration from environment (with defaults) ---
MOODLE_WWWROOT="${MOODLE_WWWROOT:-http://127.0.0.1}"
MOODLE_LANG="${MOODLE_LANG:-fr}"
MOODLE_DATAROOT="${MOODLE_DATAROOT:-/data/moodledata}"
MOODLE_DBTYPE="${MOODLE_DBTYPE:-pgsql}"
MOODLE_DBHOST="${MOODLE_DBHOST:-postgres}"
MOODLE_DBNAME="${MOODLE_DBNAME:-moodle}"
MOODLE_DBUSER="${MOODLE_DBUSER:-moodleadmin}"
MOODLE_DBPASS="${MOODLE_DBPASS:-moodlepass}"
MOODLE_ADMINUSER="${MOODLE_ADMINUSER:-moodle}"
MOODLE_ADMINPASS="${MOODLE_ADMINPASS:-moodlepass}"
MOODLE_ADMINEMAIL="${MOODLE_ADMINEMAIL:-admin@moodle.com}"
MOODLE_SUPPORTEMAIL="${MOODLE_SUPPORTEMAIL:-support@moodle.com}"
MOODLE_FULLNAME="${MOODLE_FULLNAME:-Moodle}"
MOODLE_SHORTNAME="${MOODLE_SHORTNAME:-Moodle}"
MOODLE_SSLPROXY="${MOODLE_SSLPROXY:-false}"

# Create Moodle data directory with proper permissions
mkdir -p /data/moodledata && \
chown -R root:www-data /data/moodledata && \
chmod -R 0775 /data/moodledata

# Configure Apache to use 'localhost' as ServerName
echo ServerName localhost >> /etc/apache2/apache2.conf

# Remove any existing symlink to moodle_listeners.conf
rm -f /etc/apache2/sites-enabled/moodle_listeners.conf

echo "=== MoPgR Setup ==="

# =========================================================================
# MOODLE INSTALLATION OR UPGRADE (CLI)
# ------------------------------------------------------------------------
# Idempotent: if config.php already exists, run upgrade.php instead of
# install.php. This allows the script to run safely at every container start.
# ------------------------------------------------------------------------

if [ -f /var/www/html/moodle/config.php ]; then
    echo "config.php exists — running Moodle upgrade..."
    php /var/www/html/moodle/admin/cli/upgrade.php --non-interactive
else
    echo "First installation — running Moodle install..."
    php /var/www/html/moodle/admin/cli/install.php \
      --wwwroot="${MOODLE_WWWROOT}" \
      --lang="${MOODLE_LANG}" \
      --dataroot="${MOODLE_DATAROOT}" \
      --dbtype="${MOODLE_DBTYPE}" \
      --dbhost="${MOODLE_DBHOST}" \
      --dbname="${MOODLE_DBNAME}" \
      --dbuser="${MOODLE_DBUSER}" \
      --dbpass="${MOODLE_DBPASS}" \
      --adminuser="${MOODLE_ADMINUSER}" \
      --adminpass="${MOODLE_ADMINPASS}" \
      --adminemail="${MOODLE_ADMINEMAIL}" \
      --supportemail="${MOODLE_SUPPORTEMAIL}" \
      --agree-license \
      --non-interactive \
      --fullname="${MOODLE_FULLNAME}" \
      --shortname="${MOODLE_SHORTNAME}"

    # Set proper permissions for config.php
    chown root:www-data /var/www/html/moodle/config.php
    chmod 775 /var/www/html/moodle/config.php

    # Configure Moodle to indicate that the router is configured
    echo "\$CFG->routerconfigured = true;" >> /var/www/html/moodle/config.php
    echo "Moodle router configuration set successfully!"
fi

# SSL proxy (conditional, driven by MOODLE_SSLPROXY env var)
if [ "${MOODLE_SSLPROXY}" = "true" ]; then
    echo "\$CFG->sslproxy = true;" >> /var/www/html/moodle/config.php
    echo "SSL proxy configuration set."
fi

echo "Moodle setup complete."

# --------------- CRON & CRON-LOGS ---------------
mkdir -p /var/log/moodle
touch /var/log/moodle/cron.log
chown www-data:www-data /var/log/moodle/cron.log

# Write once (overwrite) to /etc/cron.d/moodle - cron.php + adhoc_task.php
cat > /etc/cron.d/moodle << 'EOF'
* * * * * www-data /usr/local/bin/php /var/www/html/moodle/admin/cli/cron.php >> /var/log/moodle/cron.log 2>&1
* * * * * www-data /usr/local/bin/php /var/www/html/moodle/admin/cli/cron.php >> /var/log/moodle/cron.log 2>&1
* * * * * www-data /usr/local/bin/php /var/www/html/moodle/admin/cli/cron.php >> /var/log/moodle/cron.log 2>&1
* * * * * www-data /usr/local/bin/php /var/www/html/moodle/admin/cli/adhoc_task.php --execute --keep-alive=59 >> /var/log/moodle/cron.log 2>&1
* * * * * www-data /usr/local/bin/php /var/www/html/moodle/admin/cli/adhoc_task.php --execute --keep-alive=59 >> /var/log/moodle/cron.log 2>&1
* * * * * www-data /usr/local/bin/php /var/www/html/moodle/admin/cli/adhoc_task.php --execute --keep-alive=59 >> /var/log/moodle/cron.log 2>&1

EOF

# Start cron in the background
cron &
