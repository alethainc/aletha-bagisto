#!/bin/bash
set -e

# Function to fetch secrets from AWS Secrets Manager
fetch_secrets() {
    if [ ! -z "$AWS_SECRET_ARN" ]; then
        echo "Fetching secrets from AWS Secrets Manager..."
        secrets=$(aws secretsmanager get-secret-value --secret-id "$AWS_SECRET_ARN" --query SecretString --output text)
        
        # Parse JSON and set environment variables
        while IFS="=" read -r key value; do
            if [ ! -z "$key" ]; then
                export "$key"="$value"
            fi
        done < <(echo "$secrets" | jq -r 'to_entries | .[] | "\(.key)=\(.value)"')
    fi
}

# Fetch secrets if AWS_SECRET_ARN is provided
fetch_secrets

cd /var/www/html

# Debug: Print current environment variables (excluding secrets)
echo "Current environment:"
env | grep -v -E "PASSWORD|KEY|SECRET"

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

# Verify database connection
echo "Verifying database connection..."
if php artisan db:show --json; then
    echo "✅ Database connection successful"
else
    echo "❌ Database connection failed"
    echo "Database configuration:"
    php artisan config:show database
    exit 1
fi

# Run database migrations and seed with debug
echo "Running database migrations..."
php artisan migrate:status
php artisan migrate --seed --force -vvv

# Create admin user if not exists
echo "Checking for admin user..."
ADMIN_COUNT=$(php artisan tinker --execute="echo \DB::table('admins')->count();")
if [ "$ADMIN_COUNT" -eq "0" ]; then
    echo "Creating admin user..."
    php artisan tinker --execute="
        \DB::table('admins')->insert([
            'name' => 'Admin',
            'email' => 'admin@example.com',
            'password' => bcrypt('admin123'),
            'role_id' => 1,
            'status' => 1,
            'created_at' => now(),
            'updated_at' => now()
        ]);
    "
    echo "✅ Admin user created"
else
    echo "✅ Admin user already exists"
fi

# Verify installation
echo "Verifying Bagisto installation..."
if [ -f "storage/installed" ]; then
    echo "✅ Bagisto installation file found"
else
    echo "❌ Bagisto installation file missing"
    echo "Creating installation file..."
    echo "$(date)" > storage/installed
fi

# Set proper permissions
echo "Setting permissions..."
chown -R www-data:www-data storage bootstrap/cache public/media public/storage
chmod -R 775 storage bootstrap/cache public/media public/storage
chmod -R 775 storage/app/public/cache

# Create health check file
echo "Creating health check file..."
echo "OK" > public/health.txt
chown www-data:www-data public/health.txt
chmod 644 public/health.txt

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