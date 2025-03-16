#!/bin/bash

NETWORK_NAME="nginx-network"

# IF the network does not exist, create it
if [ ! "$(docker network ls | grep $NETWORK_NAME)" ]; then
    docker network create $NETWORK_NAME
fi

# Pull the latest nginx image
docker pull nginx:alpine

# Run nginx container
docker run --name nginx -d --rm \
    --network $NETWORK_NAME \
    -v ${PWD}/nginx.conf:/etc/nginx/nginx.conf \
    -v ${PWD}:/letsencrypt \
    -v ${PWD}/certs:/etc/letsencrypt \
    -p 443:443 \
    -p 80:80 \
    nginx:alpine

echo "Nginx is started and running on ports 80 and 443."
echo "You can access it via http://localhost or https://localhost."