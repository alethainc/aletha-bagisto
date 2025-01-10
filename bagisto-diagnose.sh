#!/bin/bash

echo "🔍 Bagisto Diagnostic Tool"
echo "========================="

# Function to check if container is running
check_container() {
    if ! docker ps -q -f name=bagisto >/dev/null 2>&1; then
        echo "❌ Bagisto container is not running"
        exit 1
    fi
    echo "✅ Bagisto container is running"
}

# Function to check storage permissions
check_storage_permissions() {
    echo -e "\n📁 Checking Storage Permissions..."
    docker exec bagisto ls -la /var/www/html/storage/
    docker exec bagisto ls -la /var/www/html/storage/framework/
    docker exec bagisto ls -la /var/www/html/bootstrap/cache/
}

# Function to check installation status
check_installation_status() {
    echo -e "\n🔒 Checking Installation Status..."
    
    # Check installed file
    if docker exec bagisto test -f /var/www/html/storage/installed; then
        echo "✅ storage/installed file exists"
    else
        echo "❌ storage/installed file missing"
    fi
    
    # Check database connection and admin user
    echo -e "\n📊 Database Status:"
    docker exec bagisto php artisan db:show --json
    
    echo -e "\n👤 Admin Users Count:"
    docker exec bagisto php artisan tinker --execute="echo DB::table('admins')->count();"
}

# Function to check environment variables
check_env_variables() {
    echo -e "\n🔧 Environment Variables:"
    docker exec bagisto php artisan env:show
    
    echo -e "\n🔑 APP_KEY Status:"
    docker exec bagisto php artisan key:status
}

# Function to check storage symlink
check_storage_symlink() {
    echo -e "\n🔗 Storage Symlink Status:"
    docker exec bagisto ls -la /var/www/html/public/storage
}

# Function to check Apache configuration
check_apache_config() {
    echo -e "\n🌐 Apache Configuration:"
    docker exec bagisto apache2ctl -S
    
    echo -e "\n📜 Apache Error Log (last 10 lines):"
    docker exec bagisto tail -n 10 /var/log/apache2/error.log
}

# Function to check Laravel logs
check_laravel_logs() {
    echo -e "\n📝 Laravel Logs (last 10 lines):"
    docker exec bagisto tail -n 10 /var/www/html/storage/logs/laravel.log
}

# Main execution
echo "Starting diagnostics..."
check_container
check_storage_permissions
check_installation_status
check_env_variables
check_storage_symlink
check_apache_config
check_laravel_logs

echo -e "\n✨ Diagnostic complete!" 