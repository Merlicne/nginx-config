#!/bin/bash

NETWORK_NAME="nginx-network"

if [ ! "$(docker network ls | grep $NETWORK_NAME)" ]; then
    docker network create $NETWORK_NAME
fi

docker pull nginx:alpine

docker run --name nginx -d --rm \
    --network $NETWORK_NAME \
    -v ${PWD}/nginx.conf:/etc/nginx/nginx.conf \
    -v ${PWD}:/letsencrypt \
    -v ${PWD}/certs:/etc/letsencrypt \
    -p 443:443 \
    -p 80:80 \
    nginx:alpine