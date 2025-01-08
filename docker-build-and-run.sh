#!/bin/bash

# Function to display usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -e, --environment   Specify environment (local/production)"
    echo "  -h, --help         Show this help message"
}

# Default values
ENVIRONMENT="local"
CONTAINER_NAME="aletha-bagisto"
IMAGE_NAME="aletha-bagisto:latest"
PORT="8080"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check if .env exists for local development
if [ ! -f .env ]; then
    echo "Error: .env file not found"
    exit 1
fi

# Check if container already exists
if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
    echo "Stopping running container..."
    docker stop $CONTAINER_NAME
fi

if [ "$(docker ps -aq -f status=exited -f name=$CONTAINER_NAME)" ]; then
    echo "Removing existing container..."
    docker rm $CONTAINER_NAME
fi

# Build the Docker image
echo "Building Docker image..."
docker build -t $IMAGE_NAME .

# Start the container
echo "Starting container in $ENVIRONMENT environment..."
docker run -d \
    -p $PORT:8080 \
    --env-file .env \
    -e APP_ENV=$ENVIRONMENT \
    --add-host=host.docker.internal:host-gateway \
    --name $CONTAINER_NAME \
    $IMAGE_NAME

echo "Container started! The application should be available at http://localhost:$PORT"
echo "You can view the logs using: docker logs -f $CONTAINER_NAME" 