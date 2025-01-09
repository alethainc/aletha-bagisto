#!/bin/bash
set -e

# Create startup state file
echo "starting" > /tmp/health_status

# Start Apache early to accept health checks
apache2-foreground &

# Function to update health status
update_health_status() {
    echo $1 > /tmp/health_status
}

# Function to check if Apache is running
check_apache() {
    curl -s -f http://localhost:8080 > /dev/null 2>&1
}

# Wait for Apache to start
echo "Waiting for Apache to start..."
for i in {1..30}; do
    if check_apache; then
        break
    fi
    sleep 2
done

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

# Create health check endpoint
mkdir -p public/health
cat > public/health/index.php << 'EOF'
<?php
$status = file_get_contents('/tmp/health_status');
header('Content-Type: application/json');
if ($status === "starting") {
    http_response_code(200);
    echo json_encode(["status" => "starting"]);
} else {
    http_response_code(200);
    echo json_encode(["status" => "healthy"]);
}
EOF

# Mark container as ready
update_health_status "healthy"

# Keep the script running
wait