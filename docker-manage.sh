#!/bin/bash

# Function to check environment file
check_env() {
    if [ ! -f .env ]; then
        echo "Error: .env file not found"
        echo "Please create a .env file with your database and application settings"
        echo "Required environment variables:"
        echo "  - APP_URL"
        echo "  - DB_HOST"
        echo "  - DB_DATABASE"
        echo "  - DB_USERNAME"
        echo "  - DB_PASSWORD"
        exit 1
    fi
}

# Function to stop and remove existing container
cleanup_container() {
    echo "Stopping existing container if running..."
    docker stop bagisto 2>/dev/null || true
    echo "Removing container..."
    docker rm bagisto 2>/dev/null || true
}

# Function to rebuild the image
rebuild_image() {
    echo "Building fresh Docker image..."
    docker build --platform linux/amd64 -t bagisto:latest .
}

# Function to setup directories
setup_directories() {
    echo "Setting up directories..."
    mkdir -p storage/app/public/{theme,product,category,cache}
    mkdir -p storage/framework/{cache,sessions,views}
    mkdir -p storage/logs
    mkdir -p bootstrap/cache
    chmod -R 775 storage bootstrap/cache
}

# Function to start container
start_container() {
    local env_file=$1
    echo "Starting container with environment from: $env_file"
    
    setup_directories
    
    docker run -d \
        --platform linux/amd64 \
        --name bagisto \
        -p 8080:8080 \
        --env-file $env_file \
        -v $(pwd)/storage:/var/www/html/storage \
        -v $(pwd)/bootstrap/cache:/var/www/html/bootstrap/cache \
        bagisto:latest

    echo "Container started! Waiting for initialization..."
    sleep 5

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

    # Follow logs until we see Apache start or error
    docker logs -f bagisto &
    PID=$!

    # Wait for either Apache to start or container to fail
    TIMEOUT=120
    while [ $TIMEOUT -gt 0 ]; do
        if docker logs bagisto 2>&1 | grep -q "apache2-foreground"; then
            kill $PID
            echo -e "\nBagisto is ready!"
            echo "Frontend: http://localhost:8080"
            echo "Admin Panel: http://localhost:8080/admin"
            echo "Default Admin Credentials:"
            echo "  Email: admin@example.com"
            echo "  Password: admin123"
            return 0
        fi
        if ! docker ps -q -f name=bagisto > /dev/null 2>&1; then
            kill $PID
            echo -e "\nContainer failed to start. Check logs for details."
            docker logs bagisto
            return 1
        fi
        sleep 1
        TIMEOUT=$((TIMEOUT - 1))
    done

    kill $PID
    echo -e "\nTimeout waiting for Bagisto to start"
    return 1
}

# Function to run diagnostics
run_diagnostics() {
    echo "🔍 Running Bagisto diagnostics..."
    docker exec bagisto bash -c '
        cd /var/www/html && \
        echo "📁 Storage permissions:" && ls -la storage/ && \
        echo "\n🔒 Installation status:" && \
        if [ -f "storage/installed" ]; then echo "✅ Installed"; else echo "❌ Not installed"; fi && \
        echo "\n📊 Database connection:" && \
        php artisan db:show --json && \
        echo "\n👤 Admin users:" && \
        php artisan tinker --execute="echo DB::table('\''admins'\'')->count();" && \
        echo "\n🔧 Environment status:" && \
        php artisan env && \
        echo "\n🔑 Application key:" && \
        echo "Current APP_KEY: $(grep "^APP_KEY=" .env | cut -d "=" -f2)" && \
        echo "\n🌐 Apache configuration:" && \
        apache2ctl -S && \
        echo "\n📜 Apache error log:" && \
        tail -n 10 /var/log/apache2/error.log && \
        echo "\n📝 Laravel log:" && \
        tail -n 10 storage/logs/laravel.log
    '
}

# Main script
case "$1" in
    "rebuild")
        check_env
        cleanup_container
        rebuild_image
        start_container .env
        ;;
    "start")
        check_env
        cleanup_container
        start_container .env
        ;;
    "stop")
        cleanup_container
        ;;
    "restart")
        cleanup_container
        start_container .env
        ;;
    "logs")
        docker logs -f bagisto
        ;;
    "shell")
        docker exec -it bagisto bash
        ;;
    "diagnose")
        run_diagnostics
        ;;
    *)
        echo "Usage: $0 {rebuild|start|stop|restart|logs|shell|diagnose}"
        echo "Commands:"
        echo "  rebuild  - Rebuild image and start container"
        echo "  start    - Start container with existing image"
        echo "  stop     - Stop and remove container"
        echo "  restart  - Restart container"
        echo "  logs     - View container logs"
        echo "  shell    - Access container shell"
        echo "  diagnose - Run diagnostics"
        exit 1
        ;;
esac