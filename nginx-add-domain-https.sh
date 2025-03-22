#!/bin/bash
# Script: nginx-add-domain-https
# Usage: ./nginx-add-domain-https [domain] [destination:port]
# Example: ./nginx-add-domain-https dev.webdev.com localhost:8080
#
# This script adds a new server block for HTTPS to the nginx configuration.
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
CERT="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
KEY="/etc/letsencrypt/live/${DOMAIN}/privkey.pem"

# Step 2: Build the server block snippet for HTTPS.
read -r -d '' SNIPPET << EOM
# HTTPS server for ${DOMAIN}
server {
    listen 443 ssl http2;
    server_name ${DOMAIN};

    # SSL configuration
    ssl_certificate ${CERT};
    ssl_certificate_key ${KEY};
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_stapling on;
    ssl_stapling_verify on;

    # Security headers
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Frame-Options SAMEORIGIN;
    add_header Referrer-Policy strict-origin-when-cross-origin;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Proxy configuration
    location / {
        proxy_pass http://${DEST};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_buffering on;
    }

    # Cache static assets
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        proxy_pass http://${DEST};
        proxy_set_header Host \$host;
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }
}
EOM

# Step 3: Set the path to nginx.conf (adjust if necessary)
NGINX_CONF="./nginx.conf"

echo "Backing up ${NGINX_CONF} to ${NGINX_CONF}.bak"
cp ${NGINX_CONF} ${NGINX_CONF}.bak

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
mv ${TMPFILE} ${NGINX_CONF}

echo "HTTPS server block added to ${NGINX_CONF}."
echo "Please test your configuration with: nginx -t"
echo "Then reload nginx with: systemctl reload nginx"
