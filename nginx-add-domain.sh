#!/bin/bash
# Script: nginx-add-domain
# Usage: ./nginx-add-domain [domain] [destination:port]
# Example: ./nginx-add-domain dev.webdev.com localhost:8080
#
# This script adds a new server block to the nginx configuration under the "http" block.
# It creates a backup of your original nginx.conf before modifying.
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

# Step 2: Define the server block snippet.
# By default, we use HTTP. If you need HTTPS, you'll have to adjust the snippet.
PROTOCOL="http"

read -r -d '' SNIPPET << EOM
server {
    listen 80;
    server_name ${DOMAIN};

    location / {
        proxy_pass ${PROTOCOL}://${DEST};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOM

# Step 3: Set the path to nginx.conf (adjust if necessary)
NGINX_CONF="./nginx.conf"

echo "Backing up ${NGINX_CONF} to ${NGINX_CONF}.bak"
sudo cp ${NGINX_CONF} ${NGINX_CONF}.bak

echo "Inserting server block for domain ${DOMAIN} into ${NGINX_CONF}..."
TMPFILE=$(mktemp)

# Step 4: Insert the server block snippet into the http block.
# The awk command looks for the "http {" block and inserts the snippet just before its closing "}".
awk -v snippet="$SNIPPET" '
/http\s*\{/ {
    print;
    in_http=1;
    brace_count=1;
    next;
}
in_http {
    # Count occurrences of { and } to track the http block boundaries.
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

# Step 5: Replace the original nginx.conf with the modified file
sudo mv ${TMPFILE} ${NGINX_CONF}

echo "Server block added to ${NGINX_CONF}."
echo "Please test your configuration with: sudo nginx -t"
echo "Then reload nginx with: sudo systemctl reload nginx"
