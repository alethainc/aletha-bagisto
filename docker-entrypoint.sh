#!/bin/bash
set -e

cd /var/www/html

# Install dependencies only if vendor directory doesn't exist
if [ ! -d "vendor" ]; then
    echo "Installing dependencies..."
    composer install --no-dev --optimize-autoloader
fi

# Create storage structure
echo "Setting up storage structure..."
mkdir -p storage/app/public/{theme,product,category,cache} \
    storage/framework/{cache,sessions,views} \
    storage/logs \
    bootstrap/cache \
    public/media

# Set up storage symlink if it doesn't exist
if [ ! -L "public/storage" ]; then
    echo "Setting up storage symlink..."
    rm -rf public/storage
    php artisan storage:link
fi

# Set proper permissions
echo "Setting permissions..."
chown -R www-data:www-data storage bootstrap/cache public/media public/storage
chmod -R 775 storage bootstrap/cache public/media public/storage

# Create health check directory and file
echo "Creating health check..."
mkdir -p public/health
echo "OK" > public/health/index.html

# Create specific .htaccess for health check
cat > public/health/.htaccess << 'EOF'
# Disable all rewrite rules for health check
<IfModule mod_rewrite.c>
    RewriteEngine Off
</IfModule>
EOF

# Start Apache in foreground
exec apache2-foreground