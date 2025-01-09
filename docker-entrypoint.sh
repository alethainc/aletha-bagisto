#!/bin/bash
set -e

cd /var/www/html

# Only ensure critical directories exist
echo "Checking critical directories..."
mkdir -p storage
mkdir -p bootstrap/cache

# Set base permissions
echo "Setting base permissions..."
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache

# Optimize application
echo "Optimizing application..."
php artisan optimize:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache

# Start Apache
echo "Starting Apache..."
apache2-foreground