FROM php:8.2-fpm

ARG VERSION=1.5.2

RUN apt-get update \
    && apt-get install -y unzip wget libpng-dev libjpeg-dev libfreetype6-dev \
    && docker-php-ext-install pdo pdo_mysql mysqli gd

# Install Caddy
RUN apt-get install -y curl \
    && curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg \
    && curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list \
    && apt-get update \
    && apt-get install -y caddy

WORKDIR /var/www/html

RUN wget -O easyappointments.zip "https://sourceforge.net/projects/easyappointments.mirror/files/${VERSION}/easyappointments-${VERSION}.zip/download" \
    && unzip easyappointments.zip \
    && rm easyappointments.zip \
    && chown -R www-data:www-data /var/www/html

# Caddy config
RUN echo ":80 {\n\
    root * /var/www/html\n\
    php_fastcgi 127.0.0.1:9000\n\
    file_server\n\
}" > /etc/caddy/Caddyfile

EXPOSE 80

CMD ["sh", "-c", "php-fpm & caddy run --config /etc/caddy/Caddyfile"]
