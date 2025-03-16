#!/bin/bash

NETWORK_NAME="nginx-network"

# IF the network does not exist, create it
if [ ! "$(docker network ls | grep $NETWORK_NAME)" ]; then
    docker network create $NETWORK_NAME
fi


docker build -t certbot .

docker run -it --rm --name certbot \
    -v ${PWD}:/letsencrypt \
    -v ${PWD}/certs:/etc/letsencrypt \
    certbot certbot renew --dry-run