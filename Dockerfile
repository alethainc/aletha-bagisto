# main image
FROM php:8.3-apache

# installing dependencies
RUN apt-get update && apt-get install -y \
    git \
    ffmpeg \
    libfreetype6-dev \
    libicu-dev \
    libgmp-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libxpm-dev \
    libzip-dev \
    unzip \
    zlib1g-dev

# configuring php extension
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp
RUN docker-php-ext-configure intl

# installing php extension
RUN docker-php-ext-install bcmath calendar exif gd gmp intl mysqli pdo pdo_mysql zip

# installing composer
COPY --from=composer:2.7 /usr/bin/composer /usr/local/bin/composer

# installing node js
COPY --from=node:23 /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node:23 /usr/local/bin/node /usr/local/bin/node
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm

# setting work directory
WORKDIR /var/www/html

# adding user
RUN useradd -G www-data,root -u 1000 -d /home/bagisto bagisto
RUN mkdir -p /home/bagisto/.composer && \
    chown -R bagisto:bagisto /home/bagisto

# Create necessary directories
RUN mkdir -p storage/framework/{sessions,views,cache} \
    && mkdir -p storage/logs \
    && mkdir -p bootstrap/cache \
    && mkdir -p routes \
    && mkdir -p vendor

# setting apache
COPY ./.configs/apache.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite

# Copy application code
COPY . /var/www/html

# setting up project permissions
RUN chmod -R 775 /var/www/html
RUN chown -R bagisto:www-data /var/www/html

# Copy startup script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# changing user
USER bagisto

# Install dependencies
RUN composer update league/flysystem-aws-s3-v3 --with-dependencies && \
    composer install --no-dev --optimize-autoloader

# Set entrypoint
ENTRYPOINT ["docker-entrypoint.sh"] 