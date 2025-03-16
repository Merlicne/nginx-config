#!/bin/bash
# Script: nginx-add-certbot-challenge
# Usage: ./nginx-add-certbot-challenge [domain] [challenge_directory]
# Example: ./nginx-add-certbot-challenge example.com /var/www/certbot
#
# This script adds a server block to the nginx configuration that serves files from
# the specified directory under the /.well-known/acme-challenge/ path.
#
# It creates a backup of your original nginx.conf before modifying.
#
# WARNING: Automatic modifications can be error-prone.
#          Always test your configuration with "sudo nginx -t" before reloading nginx.

# Step 1: Validate arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 [domain]"
    exit 1
fi

DOMAIN=$1
CHALLENGE_DIR="/letsencrypt/"

# Step 2: Build the server block snippet for serving Certbot challenges.
read -r -d '' SNIPPET << EOM
server {
    listen 80;
    server_name ${DOMAIN};

    location /.well-known/acme-challenge/ {
        root ${CHALLENGE_DIR};
    }
}
EOM

# Step 3: Specify the path to your nginx configuration file (adjust if necessary)
NGINX_CONF="./nginx.conf"

echo "Backing up ${NGINX_CONF} to ${NGINX_CONF}.bak"
sudo cp ${NGINX_CONF} ${NGINX_CONF}.bak

echo "Inserting Certbot challenge server block for domain ${DOMAIN} into ${NGINX_CONF}..."
TMPFILE=$(mktemp)

# Step 4: Insert the snippet into the 'http' block.
# The awk command finds the "http {" block, tracks its braces,
# and inserts the new server block snippet just before the block closes.
awk -v snippet="$SNIPPET" '
/http\s*\{/ {
    print;
    in_http=1;
    brace_count=1;
    next;
}
in_http {
    count = gsub(/{/,"{");
    brace_count += count;
    count = gsub(/}/,"}");
    brace_count -= count;
    if (brace_count == 0 && in_http) {
        print snippet;
        in_http=0;
    }
}
{ print }
' ${NGINX_CONF} > ${TMPFILE}

# Step 5: Replace the original configuration with the modified version
sudo mv ${TMPFILE} ${NGINX_CONF}

echo "Certbot challenge server block added to ${NGINX_CONF}."
echo "Please test your configuration with: sudo nginx -t"
echo "Then reload nginx with: sudo systemctl reload nginx"
