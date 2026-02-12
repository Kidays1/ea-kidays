#!/bin/sh

cd /var/www/html

if [ ! -f config.php ]; then
cat > config.php <<EOF
<?php

class Config {

    const BASE_URL = '${BASE_URL}';
    const LANGUAGE = 'english';
    const DEBUG_MODE = FALSE;

    const DB_HOST = '${MYSQLHOST}';
    const DB_NAME = '${MYSQLDATABASE}';
    const DB_USERNAME = '${MYSQLUSER}';
    const DB_PASSWORD = '${MYSQLPASSWORD}';
    const DB_PORT = '${MYSQLPORT}';
}
EOF
fi

php-fpm &
caddy run --config /etc/caddy/Caddyfile
