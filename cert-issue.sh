#!/bin/bash

# Step 1: Validate arguments.
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 [domain]"
    exit 1
fi

# is nginx started?
if [ ! "$(docker ps | grep nginx)" ]; then
    echo "Nginx is not running. Please start it first."
    exit 1
fi

bash ./nginx-add-certbot-challenge.sh $1

bash ./nginx-reload.sh

echo "Certbot challenge server block added for domain $1."

bash ./certbot-start.sh

bash ./nginx-remove-certbot-challenge.sh $1

bash ./nginx-reload.sh