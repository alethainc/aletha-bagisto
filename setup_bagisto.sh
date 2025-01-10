#!/bin/bash

echo "Setting up Bagisto environment..."

# Login to ECR
echo "Logging into ECR..."
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 536473282634.dkr.ecr.us-east-2.amazonaws.com

# Cleanup existing containers and images
echo "Cleaning up existing container..."
docker stop bagisto 2>/dev/null || true
docker rm bagisto 2>/dev/null || true

# Pull latest image with platform specification
echo "Pulling latest image..."
docker pull --platform linux/amd64 536473282634.dkr.ecr.us-east-2.amazonaws.com/alethahealth/aletha-bagisto:latest

if [ $? -eq 0 ]; then
    echo "✅ Latest image pulled successfully"
else
    echo "❌ Error: Cannot pull from ECR. Please check instance role permissions"
    exit 1
fi

# Create required directories and set permissions
echo "Setting up directories..."
mkdir -p storage/app/public/{theme,product,category,cache}
mkdir -p storage/framework/{cache,sessions,views}
mkdir -p storage/logs
mkdir -p bootstrap/cache
chmod -R 775 storage bootstrap/cache

# Start container with platform specification and volume mounts
echo "Starting container..."
docker run -d \
    --platform linux/amd64 \
    --name bagisto \
    -p 8080:8080 \
    --env-file .env \
    -v $(pwd)/storage:/var/www/html/storage \
    -v $(pwd)/bootstrap/cache:/var/www/html/bootstrap/cache \
    536473282634.dkr.ecr.us-east-2.amazonaws.com/alethahealth/aletha-bagisto:latest

# Wait for container to start
echo "Waiting for container to initialize..."
sleep 10

# Initialize the application
echo "Initializing Bagisto..."
docker exec bagisto bash -c '
    cd /var/www/html && \
    php artisan optimize:clear && \
    php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache && \
    php artisan storage:link && \
    echo "$(date)" > storage/installed && \
    chown -R www-data:www-data storage bootstrap/cache && \
    chmod -R 775 storage bootstrap/cache
'

echo
echo "Container started! To view logs:"
echo "docker logs -f bagisto" 