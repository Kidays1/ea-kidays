FROM php:8.2-fpm

ARG VERSION=1.5.2

RUN apt-get update \
    && apt-get install -y unzip wget curl \
       libpng-dev libjpeg-dev libfreetype6-dev \
       caddy \
    && docker-php-ext-install pdo pdo_mysql mysqli gd

WORKDIR /var/www/html

COPY Caddyfile /etc/caddy/Caddyfile

# Download EasyAppointments
RUN wget -O easyappointments.zip "https://sourceforge.net/projects/easyappointments.mirror/files/${VERSION}/easyappointments-${VERSION}.zip/download" \
    && unzip easyappointments.zip \
    && rm easyappointments.zip \
    && chown -R www-data:www-data /var/www/html

# Create entrypoint
RUN echo '#!/bin/sh
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
' > /entrypoint.sh \
 && chmod +x /entrypoint.sh

EXPOSE 80

CMD ["/entrypoint.sh"]
