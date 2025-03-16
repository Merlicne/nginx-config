#!/bin/bash
# Script: nginx-add-domain-https
# Usage: ./nginx-add-domain-https [domain] [destination:port] [certificate file] [key file]
# Example: ./nginx-add-domain-https dev.webdev.com localhost:8080 /etc/ssl/certs/dev.webdev.com.crt /etc/ssl/private/dev.webdev.com.key
#
# This script adds a new server block for HTTPS to the nginx configuration.
# It creates a backup of your original nginx.conf before modifying.
#
# NOTE: This example assumes your nginx configuration file is at /etc/nginx/nginx.conf.
#       Adjust paths as necessary.
#
# WARNING: Automatic modifications can be error-prone.
#          Always test your configuration with "sudo nginx -t" before reloading nginx.

# Step 1: Validate arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 [domain] [destination:port]"
    exit 1
fi

DOMAIN=$1
DEST=$2
CERT="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem;"
KEY="/etc/letsencrypt/live/${DOMAIN}/privkey.pem;"

# Step 2: Build the server block snippet for HTTPS.
read -r -d '' SNIPPET << EOM
server {
    listen 443 ssl;
    server_name ${DOMAIN};

    ssl_certificate ${CERT};
    ssl_certificate_key ${KEY};
    
    location / {
        proxy_pass http://${DEST};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOM

# Step 3: Set the path to nginx.conf (adjust if necessary)
NGINX_CONF="./nginx.conf"

echo "Backing up ${NGINX_CONF} to ${NGINX_CONF}.bak"
sudo cp ${NGINX_CONF} ${NGINX_CONF}.bak

echo "Inserting HTTPS server block for domain ${DOMAIN} into ${NGINX_CONF}..."
TMPFILE=$(mktemp)

# Step 4: Insert the snippet into the http block.
# This awk command finds the "http {" block, tracks its braces,
# and inserts the new server block right before the block closes.
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

# Step 5: Replace the original configuration file with the modified file
sudo mv ${TMPFILE} ${NGINX_CONF}

echo "HTTPS server block added to ${NGINX_CONF}."
echo "Please test your configuration with: sudo nginx -t"
echo "Then reload nginx with: sudo systemctl reload nginx"
