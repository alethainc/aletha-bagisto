#!/bin/bash
set -e

cd /var/www/html

# Install dependencies
echo "Installing dependencies..."
composer install --no-dev --optimize-autoloader

# Publish vendor assets
echo "Publishing vendor assets..."
php artisan bagisto:publish --force

# Create storage structure
echo "Setting up storage structure..."
mkdir -p storage/app/public/{theme,product,category,cache}
mkdir -p storage/framework/{cache,sessions,views}
mkdir -p storage/logs
mkdir -p bootstrap/cache

# Create theme files directory
echo "Setting up theme files directory..."
mkdir -p public/media

# Set up storage symlink
echo "Setting up storage symlink..."
rm -rf public/storage
php artisan storage:link

# Verify S3 configuration if using S3
if [ "$FILESYSTEM_CLOUD" = "s3" ]; then
    echo "Verifying S3 configuration..."
    if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$AWS_BUCKET" ]; then
        echo "Error: S3 configuration is incomplete"
        exit 1
    fi
fi

# Set proper permissions
echo "Setting permissions..."
chown -R www-data:www-data storage bootstrap/cache public/media public/storage
chmod -R 775 storage bootstrap/cache public/media public/storage
chmod -R 775 storage/app/public/cache

# Run database migrations and seed
echo "Running database migrations..."
php artisan migrate --seed --force

# Clear all caches
echo "Clearing application caches..."
php artisan config:clear
php artisan cache:clear
php artisan view:clear
php artisan route:clear

# Optimize application
echo "Optimizing application..."
php artisan optimize:clear
php artisan optimize
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache

# Start Apache
echo "Starting Apache..."
apache2-foreground