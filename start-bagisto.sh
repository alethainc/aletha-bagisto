#!/bin/bash

# Check if .env file path is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <path-to-env-file>"
    echo "Example: $0 .env"
    exit 1
fi

ENV_FILE=$1

# Check if env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Environment file $ENV_FILE not found!"
    exit 1
fi

# Stop and remove existing container if it exists
echo "Cleaning up existing container..."
docker stop bagisto 2>/dev/null || true
docker rm bagisto 2>/dev/null || true

# Pull latest image
echo "Pulling latest image..."
docker pull 536473282634.dkr.ecr.us-east-2.amazonaws.com/alethahealth/aletha-bagisto:latest

# Start container with env file
echo "Starting container..."
docker run -d \
    --name bagisto \
    -p 8080:8080 \
    --env-file "$ENV_FILE" \
    536473282634.dkr.ecr.us-east-2.amazonaws.com/alethahealth/aletha-bagisto:latest

# Check if container started successfully
if [ $? -eq 0 ]; then
    echo "Container started successfully!"
    echo "You can check logs with: docker logs -f bagisto"
    echo "Container status:"
    docker ps | grep bagisto
else
    echo "Failed to start container. Check logs with: docker logs bagisto"
fi 