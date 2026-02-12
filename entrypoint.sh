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
# Debug PHP (temporaire)
echo "display_errors=1" > /usr/local/etc/php/conf.d/zz-debug.ini
echo "display_startup_errors=1" >> /usr/local/etc/php/conf.d/zz-debug.ini
echo "error_reporting=E_ALL" >> /usr/local/etc/php/conf.d/zz-debug.ini
echo "log_errors=1" >> /usr/local/etc/php/conf.d/zz-debug.ini
echo "error_log=/proc/self/fd/2" >> /usr/local/etc/php/conf.d/zz-debug.ini
# Force PHP-FPM to output worker errors to logs
sed -i 's~^;catch_workers_output = yes~catch_workers_output = yes~' /usr/local/etc/php-fpm.d/www.conf || true
sed -i 's~^catch_workers_output = no~catch_workers_output = yes~' /usr/local/etc/php-fpm.d/www.conf || true

# Keep env vars accessible in PHP-FPM workers (safe)
sed -i 's~^clear_env = yes~clear_env = no~' /usr/local/etc/php-fpm.d/www.conf || true

# Ensure error_log is stderr at FPM level too
grep -q "php_admin_value\\[error_log\\]" /usr/local/etc/php-fpm.d/www.conf || \
  printf "\nphp_admin_flag[log_errors] = on\nphp_admin_value[error_log] = /proc/self/fd/2\n" >> /usr/local/etc/php-fpm.d/www.conf
# Create a diag endpoint to reveal the real PHP error + test DB
cat > /var/www/html/__diag.php <<'PHP'
<?php
error_reporting(E_ALL);
ini_set('display_errors', '1');

echo "OK: diag reached\n";

require_once __DIR__ . '/config.php';
echo "Config loaded\n";

$host = Config::DB_HOST;
$db   = Config::DB_NAME;
$user = Config::DB_USERNAME;
$pass = Config::DB_PASSWORD;
$port = Config::DB_PORT;

echo "Trying DB... host=$host db=$db user=$user port=$port\n";

try {
  $dsn = "mysql:host=$host;port=$port;dbname=$db;charset=utf8mb4";
  $pdo = new PDO($dsn, $user, $pass, [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_TIMEOUT => 5
  ]);
  echo "DB CONNECT: OK\n";
  $v = $pdo->query("SELECT VERSION()")->fetchColumn();
  echo "MySQL VERSION: $v\n";
} catch (Throwable $e) {
  echo "DB CONNECT: FAIL\n";
  echo $e->getMessage() . "\n";
}

echo "\nNow including index.php...\n";
require __DIR__ . '/index.php';
echo "\nDONE\n";
PHP
php-fpm &
caddy run --config /etc/caddy/Caddyfile
