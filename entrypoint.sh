#!/bin/sh
set -e

cd /var/www/html

# Toujours régénérer config.php (évite les vieux fichiers cassés)
rm -f config.php

cat > config.php <<EOF
<?php

class Config {

    const BASE_URL = '${BASE_URL}';

    const LANGUAGE = 'english';
    const DEBUG_MODE = false;

    const DB_HOST = '${MYSQLHOST}';
    const DB_NAME = '${MYSQLDATABASE}';
    const DB_USERNAME = '${MYSQLUSER}';
    const DB_PASSWORD = '${MYSQLPASSWORD}';
    const DB_PORT = '${MYSQLPORT}';

}
EOF

php-fpm &
caddy run --config /etc/caddy/Caddyfile
