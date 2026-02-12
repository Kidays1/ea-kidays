FROM php:8.2-fpm

ARG VERSION=1.5.2

RUN apt-get update \
    && apt-get install -y unzip wget curl \
       libpng-dev libjpeg-dev libfreetype6-dev \
       caddy \
    && docker-php-ext-install pdo pdo_mysql mysqli gd

WORKDIR /var/www/html

COPY Caddyfile /etc/caddy/Caddyfile
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN wget -O easyappointments.zip "https://sourceforge.net/projects/easyappointments.mirror/files/${VERSION}/easyappointments-${VERSION}.zip/download" \
    && unzip easyappointments.zip \
    && rm easyappointments.zip \
    && chown -R www-data:www-data /var/www/html

EXPOSE 80

CMD ["/entrypoint.sh"]
