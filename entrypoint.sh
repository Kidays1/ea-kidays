#!/bin/sh

cd /var/www/html

if [ ! -f config.php ]; then
  cp config-sample.php config.php

  sed -i "s/DB_HOST.*/DB_HOST', '${MYSQLHOST}');/" config.php
  sed -i "s/DB_NAME.*/DB_NAME', '${MYSQLDATABASE}');/" config.php
  sed -i "s/DB_USERNAME.*/DB_USERNAME', '${MYSQLUSER}');/" config.php
  sed -i "s/DB_PASSWORD.*/DB_PASSWORD', '${MYSQLPASSWORD}');/" config.php
  sed -i "s/DB_PORT.*/DB_PORT', '${MYSQLPORT}');/" config.php
  sed -i "s|BASE_URL.*|BASE_URL', '${BASE_URL}');|" config.php
fi

php-fpm &
caddy run --config /etc/caddy/Caddyfile
