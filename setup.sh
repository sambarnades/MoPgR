#!/bin/bash
set -x

# Create Moodle data directory with proper permissions
# root owns the directory, www-data/Apache group has write access, good for maintenance
mkdir -p /data/moodledata && \
chown -R root:www-data /data/moodledata && \
chmod -R 0775 /data/moodledata

# Configure Apache to use 'localhost' as ServerName
echo ServerName localhost >> /etc/apache2/apache2.conf

# Remove any existing symlink to moodle_listeners.conf
rm -f /etc/apache2/sites-enabled/moodle_listeners.conf

# Entrypoint script for Moodle container
echo "Installing Moodle..."

# =========================================================================
# MOODLE INSTALLATION (CLI)
# ------------------------------------------------------------------------
# Executes Moodle's non-interactive installation via admin/cli/install.php.
# All parameters use default values for Docker environment.
#
# PARAMETERS:
#   --wwwroot="http://127.0.0.1"       # Base URL for Moodle (http:// or https://)
#   --lang="fr"                        # Interface language (ISO 639-1: fr, en, es, etc.)
#   --dataroot="/data/moodledata"     # Data directory (MUST be outside webroot)
#   --dbtype="pgsql"                  # Database type: pgsql, mysqli, mariadb, oci, sqlsrv
#   --dbhost="postgres"               # Database host (Docker service name or IP)
#   --dbname="moodle"                 # Database name
#   --dbuser="moodleadmin"            # Database username
#   --dbpass="moodlepass"             # Database password
#   --adminuser="moodle"              # Moodle admin username
#   --adminpass="moodlepass"          # Moodle admin password
#   --adminemail="admin@moodle.com"  # Administrator email (required)
#   --supportemail="support@moodle.com" # Support email (optional)
#   --agree-license                    # Accept Moodle GPL license (REQUIRED)
#   --non-interactive                 # Disable interactive prompts (REQUIRED)
#   --fullname="Moodle"               # Full site name
#   --shortname="Moodle"              # Short site name (displayed in browser tabs)
#
# SECURITY NOTE: For production, replace hardcoded passwords with environment
# variables (e.g., --dbpass="${POSTGRES_PASSWORD}", --adminpass="${ADMIN_PASSWORD}").
# Do NOT commit passwords to version control.
# ------------------------------------------------------------------------

php /var/www/html/moodle/admin/cli/install.php \
  --wwwroot="http://127.0.0.1" \
  --lang="fr" \
  --dataroot="/data/moodledata" \
  --dbtype="pgsql" \
  --dbhost="postgres" \
  --dbname="moodle" \
  --dbuser="moodleadmin" \
  --dbpass="moodlepass" \
  --adminuser="moodle" \
  --adminpass="moodlepass" \
  --adminemail="admin@moodle.com" \
  --supportemail="support@moodle.com" \
  --agree-license \
  --non-interactive \
  --fullname="Moodle" \
  --shortname="Moodle"

  # Set proper permissions for config.php
  chown root:www-data /var/www/html/moodle/config.php
  chmod 775 /var/www/html/moodle/config.php

  # Configure Moodle to indicate that the router is configured
  echo "\$CFG->routerconfigured = true;" >> /var/www/html/moodle/config.php
  echo "Moodle router configuration set successfully!"

  echo "Moodle installed successfully!"

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

# Start Apache in foreground
exec "$@"