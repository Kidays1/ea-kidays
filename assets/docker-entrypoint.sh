#!/bin/bash

# -----------------------------------------------------------------------------
# Easy!Appointments - Online Appointment Scheduler
#
# @package     EasyAppointments
# @author      A.Tselegidis <alextselegidis@gmail.com>
# @copyright   Copyright (c) Alex Tselegidis
# @license     https://opensource.org/licenses/GPL-3.0 - GPLv3
# @link        https://easyappointments.org
# -----------------------------------------------------------------------------

##
# Set up the currently cloned Easy!Appointments build.
#
# This script will perform the required actions so that Easy!Appointments is configured properly to work with the
# provided environment variables.
#
# Usage:
#
#  ./docker-entrypoint.sh
#

# Config

cat <<EOF >/var/www/html/config.php
<?php
class Config {
    const BASE_URL              = '${BASE_URL}';
    const LANGUAGE              = '${LANGUAGE}';
    const DEBUG_MODE            = ${DEBUG_MODE};
    const DB_HOST               = '${DB_HOST}';
    const DB_PORT               = '${DB_PORT}';
    const DB_NAME               = '${DB_NAME}';
    const DB_USERNAME           = '${DB_USERNAME}';
    const DB_PASSWORD           = '${DB_PASSWORD}';
    const GOOGLE_SYNC_FEATURE   = ${GOOGLE_SYNC_FEATURE};
    const GOOGLE_CLIENT_ID      = '${GOOGLE_CLIENT_ID}';
    const GOOGLE_CLIENT_SECRET  = '${GOOGLE_CLIENT_SECRET}';
}
EOF

# Email Config

cat <<EOF >/var/www/html/application/config/email.php
<?php defined('BASEPATH') or exit('No direct script access allowed');

// Add custom values by settings them to the $config array.
// Example: $config['smtp_host'] = 'smtp.gmail.com';
// @link https://codeigniter.com/user_guide/libraries/email.html

\$config['useragent'] = 'Easy!Appointments';
\$config['protocol'] = '${MAIL_PROTOCOL}'; // or 'smtp'
\$config['mailtype'] = 'html'; // or 'text'
\$config['smtp_debug'] = '${MAIL_SMTP_DEBUG}'; // or '1'
\$config['smtp_auth'] = ${MAIL_SMTP_AUTH}; //or FALSE for anonymous relay.
\$config['smtp_host'] = '${MAIL_SMTP_HOST}';
\$config['smtp_user'] = '${MAIL_SMTP_USER}';
\$config['smtp_pass'] = '${MAIL_SMTP_PASS}';
\$config['smtp_crypto'] = '${MAIL_SMTP_CRYPTO}'; // or 'tls'
\$config['smtp_port'] = ${MAIL_SMTP_PORT};
\$config['from_name'] = '${MAIL_FROM_NAME}';
\$config['from_address'] = '${MAIL_FROM_ADDRESS}';
\$config['reply_to'] = '${MAIL_REPLY_TO_ADDRESS}';
\$config['crlf'] = "\r\n";
\$config['newline'] = "\r\n";
EOF

# Fixed BASE_URL value

FILE=/var/www/html/application/config/config.php
STRING="\$config['base_url'] = '${BASE_URL}';"

#echo "\$config['base_url'] = '${BASE_URL}';" >> /var/www/html/application/config/config.php

if [ "$(tail -n 1 "$FILE")" != "$STRING" ]; then
    echo "$STRING" >> "$FILE"
fi

# Start Apache

exec apache2-foreground
