#!/bin/bash

NETWORK_NAME="nginx-network"

if [ ! "$(docker network ls | grep $NETWORK_NAME)" ]; then
    docker network create $NETWORK_NAME
fi

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 [domain]"
    exit 1
fi

docker build -t certbot .

# Get the Nginx user's UID from the image
NGINX_UID=$(docker run --rm nginx:alpine id -u nginx)

docker run -it --rm --name certbot \
    --user $NGINX_UID:$NGINX_UID \
    -v ${PWD}:/letsencrypt \
    -v ${PWD}/certs:/etc/letsencrypt \
    certbot certbot certonly --webroot --webroot-path=/letsencrypt -d $1