#!/bin/sh

# Generate config.php from Railway env variables
cat > /var/www/html/config.php <<EOF
<?php
define("BASE_URL", getenv("BASE_URL"));
define("DB_HOST", getenv("MYSQLHOST"));
define("DB_NAME", getenv("MYSQLDATABASE"));
define("DB_USERNAME", getenv("MYSQLUSER"));
define("DB_PASSWORD", getenv("MYSQLPASSWORD"));
define("DB_PORT", getenv("MYSQLPORT"));
EOF

php-fpm &
caddy run --config /etc/caddy/Caddyfile
