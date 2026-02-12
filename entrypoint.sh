#!/bin/sh
set -e

cd /var/www/html

# Toujours régénérer config.php (pas de cache)
rm -f config.php

cat > config.php <<EOF
<?php

class Config {
  const BASE_URL = '${BASE_URL}';
  const LANGUAGE = 'english';
  const DEBUG_MODE = false;

  const DB_HOST = '${MYSQLHOST}';
  const DB_NAME = '${MYSQL_DATABASE}';
  const DB_USERNAME = '${MYSQLUSER}';
  const DB_PASSWORD = '${MYSQLPASSWORD}';
  const DB_PORT = '${MYSQLPORT}';
}
EOF

echo "================= GENERATED /var/www/html/config.php ================="
nl -ba /var/www/html/config.php | sed -n '1,120p'
echo "======================================================================"

php-fpm &
caddy run --config /etc/caddy/Caddyfile
