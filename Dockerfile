FROM php:8.2-fpm

ARG VERSION=1.5.2

# Install system deps + PHP extensions
RUN apt-get update \
    && apt-get install -y unzip wget curl gnupg ca-certificates \
       libpng-dev libjpeg-dev libfreetype6-dev \
    && docker-php-ext-install pdo pdo_mysql mysqli gd

# Install Caddy properly
RUN mkdir -p /etc/apt/keyrings \
    && curl -1sLf https://dl.cloudsmith.io/public/caddy/stable/gpg.key \
       | gpg --dearmor -o /etc/apt/keyrings/caddy-stable.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/caddy-stable.gpg] https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt any-version main" \
       > /etc/apt/sources.list.d/caddy-stable.list \
    && apt-get update \
    && apt-get install -y caddy

WORKDIR /var/www/html

# Download EasyAppointments
RUN wget -O easyappointments.zip "https://sourceforge.net/projects/easyappointments.mirror/files/${VERSION}/easyappointments-${VERSION}.zip/download" \
    && unzip easyappointments.zip \
    && rm easyappointments.zip \
    && chown -R www-data:www-data /var/www/html

EXPOSE 80

CMD ["sh", "-c", "php-fpm & caddy run --config /etc/caddy/Caddyfile"]
