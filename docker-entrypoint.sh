#!/bin/bash
set -e

# Function to set up storage directories
setup_storage_directories() {
    echo "Setting up storage directories..."
    mkdir -p /var/www/html/storage/framework/{sessions,views,cache}
    mkdir -p /var/www/html/storage/logs
    mkdir -p /var/www/html/storage/app/{public,private}
    mkdir -p /var/www/html/bootstrap/cache
    mkdir -p /var/www/html/public/storage
}

# Function to set proper permissions
set_permissions() {
    echo "Setting proper permissions..."
    chown -R www-data:www-data /var/www/html
    chmod -R 775 /var/www/html/storage
    chmod -R 775 /var/www/html/bootstrap/cache
    chmod -R 775 /var/www/html/public
}

# Function to clear application cache
clear_cache() {
    echo "Clearing application cache..."
    php artisan config:clear
    php artisan cache:clear
    php artisan view:clear
}

# Function to verify storage link
verify_storage_link() {
    echo "Verifying storage link..."
    if [ ! -L public/storage ]; then
        php artisan storage:link
    fi
}

# Main execution
echo "Starting Bagisto initialization..."

setup_storage_directories
set_permissions
clear_cache
verify_storage_link

if [ "$APP_ENV" = "production" ]; then
    echo "Optimizing for production..."
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
fi

# Start Apache in foreground
echo "Starting Apache..."
apache2-foreground