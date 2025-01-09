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
    docker build -t bagisto:latest .
}

# Function to start container
start_container() {
    local env_file=$1
    echo "Starting container with environment from: $env_file"
    
    docker run -d \
        --name bagisto \
        -p 8080:8080 \
        --env-file $env_file \
        bagisto:latest

    echo "Container started! Waiting for initialization..."
    sleep 5

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
    *)
        echo "Usage: $0 {rebuild|start|stop|restart|logs|shell}"
        echo "Commands:"
        echo "  rebuild  - Rebuild image and start container"
        echo "  start    - Start container with existing image"
        echo "  stop     - Stop and remove container"
        echo "  restart  - Restart container"
        echo "  logs     - View container logs"
        echo "  shell    - Access container shell"
        exit 1
        ;;
esac