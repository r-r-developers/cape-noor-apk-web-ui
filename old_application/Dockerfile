FROM php:8.1-apache

# Enable Apache modules
RUN a2enmod rewrite headers

# Install PHP extensions needed by the app
RUN apt-get update \
    && apt-get install -y libxml2-dev libcurl4-openssl-dev \
    && docker-php-ext-install pdo pdo_mysql mysqli dom curl fileinfo \
    && rm -rf /var/lib/apt/lists/*

# Remap www-data to UID/GID 1000 so Apache can write to bind-mounted volumes
# that are owned by the host user (UID 1000) on exFAT / ext4 drives.
RUN usermod -u 1000 www-data && groupmod -g 1000 www-data

# Replace default Apache vhost with our config (AllowOverride All)
COPY docker/apache.conf /etc/apache2/sites-available/000-default.conf

# Copy entrypoint that fixes writable-directory permissions at startup
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Pre-create upload/cache dirs so they exist in the image layer
RUN mkdir -p /var/www/html/cache \
             /var/www/html/uploads/logos \
             /var/www/html/uploads/sponsors \
    && chown -R www-data:www-data /var/www/html

# Copy the app (overridden by volume mount in docker-compose for dev)
COPY public/ /var/www/html/

EXPOSE 80

ENTRYPOINT ["entrypoint.sh"]
CMD ["apache2-foreground"]
