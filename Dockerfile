FROM php:8.2-fpm

ARG VERSION=1.5.2

# Install system deps + PHP extensions
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

EXPOSE 80

CMD ["sh", "-c", "php-fpm & caddy run --config /etc/caddy/Caddyfile"]
