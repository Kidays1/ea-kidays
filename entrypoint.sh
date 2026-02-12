#!/bin/sh
set -e

cd /var/www/html
echo "=== CHECK STATIC FILES ==="
ls -la /var/www/html/assets || true
ls -la /var/www/html/assets/css || true
ls -la /var/www/html/assets/css/style.min.css || true
echo "=========================="


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

  // ---- Feature flags expected by EasyAppointments (safe defaults) ----
  const GOOGLE_SYNC_FEATURE = false;
  const OUTLOOK_SYNC_FEATURE = false;
  const ZOOM_FEATURE = false;

  // ---- Optional Google config defaults (empty = disabled) ----
  const GOOGLE_APPLICATION_NAME = '';
  const GOOGLE_CLIENT_ID = '';
  const GOOGLE_CLIENT_SECRET = '';
  const GOOGLE_REDIRECT_URI = '';
  const GOOGLE_API_KEY = '';
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

function out($s){ echo $s . "\n"; @ob_flush(); @flush(); }

register_shutdown_function(function () {
  $e = error_get_last();
  if ($e) {
    out("=== PHP LAST ERROR ===");
    out(print_r($e, true));
  } else {
    out("=== PHP LAST ERROR: none ===");
  }
});

out("OK: diag reached");

require_once __DIR__ . '/config.php';
out("Config loaded");

$checks = [
  'curl','mbstring','intl','zip','xml','dom','gd','mysqli','pdo_mysql'
];

out("=== EXTENSIONS ===");
foreach ($checks as $ext) {
  out($ext . ": " . (extension_loaded($ext) ? "YES" : "NO"));
}

out("=== DB TEST ===");
try {
  $dsn = "mysql:host=".Config::DB_HOST.";port=".Config::DB_PORT.";dbname=".Config::DB_NAME.";charset=utf8mb4";
  $pdo = new PDO($dsn, Config::DB_USERNAME, Config::DB_PASSWORD, [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_TIMEOUT => 5
  ]);
  out("DB CONNECT: OK");
  out("MySQL VERSION: " . $pdo->query("SELECT VERSION()")->fetchColumn());
} catch (Throwable $e) {
  out("DB CONNECT: FAIL");
  out($e->getMessage());
}

out("=== INCLUDING index.php (buffered) ===");
ob_start();
try {
  require __DIR__ . '/index.php';
  $buf = ob_get_clean();
  out("index.php returned normally.");
  out("=== OUTPUT (first 2000 chars) ===");
  out(substr($buf, 0, 2000));
} catch (Throwable $e) {
  $buf = ob_get_clean();
  out("THROWABLE while including index.php:");
  out($e->getMessage());
  out($e->getTraceAsString());
}
out("DONE");
PHP

php-fpm &
caddy run --config /etc/caddy/Caddyfile
