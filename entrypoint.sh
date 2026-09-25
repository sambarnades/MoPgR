#!/bin/bash
set -e

echo "=== MoPgR Entrypoint ==="

# 1. Setup Moodle (install or upgrade, handled by setup.sh)
/var/www/html/setup.sh

# 2. Plugins (if the script is mounted by the overlay)
if [ -f /var/www/html/install_plugins.sh ]; then
    echo "=== Installing/Updating Plugins ==="
    /var/www/html/install_plugins.sh
fi

# 3. Start Apache
exec apache2-foreground
