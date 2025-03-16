#!/bin/bash
# Script: nginx-remove-certbot-challenge
# Usage: ./nginx-remove-certbot-challenge [domain]
# Example: ./nginx-remove-certbot-challenge example.com
#
# This script removes any server block from the nginx configuration
# that contains the specified domain (via server_name) and a location block
# for /.well-known/acme-challenge. It creates a backup of nginx.conf before modifying.
#
# WARNING: Automatic modifications can be error-prone.
#          Always test your configuration with "sudo nginx -t" before reloading nginx.

# Step 1: Validate arguments.
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 [domain]"
    exit 1
fi

DOMAIN=$1
NGINX_CONF="./nginx.conf"

echo "Backing up ${NGINX_CONF} to ${NGINX_CONF}.bak"
sudo cp ${NGINX_CONF} ${NGINX_CONF}.bak

TMPFILE=$(mktemp)

# Step 2: Process the file using awk.
# The awk script collects server blocks (starting at a line matching "server {").
# It uses a brace counter to determine when the block ends.
# If the block contains both the given domain (via "server_name") and a reference to
# the ACME challenge (via "location /.well-known/acme-challenge"), it is skipped.
# Otherwise, it is printed.
awk -v domain="$DOMAIN" '
function print_block(lines, n) {
    for (i = 1; i <= n; i++) {
        print lines[i]
    }
}
{
    # When we detect the start of a server block.
    if ($0 ~ /^[ \t]*server[ \t]*{/) {
        in_block = 1
        block_line = 1
        delete block
        block[block_line] = $0
        # Initialize brace_count to 1 (for the “{” in "server {").
        brace_count = 1
        remove_block = 0
        # Check current line for domain (if present) – it may be on the same line.
        if ($0 ~ "server_name[ \t]+" domain) {
            remove_block = 1
        }
        next
    }

    if (in_block) {
        block_line++
        block[block_line] = $0
        # Count "{" and "}" in this line.
        n_open = gsub(/{/,"&")
        n_close = gsub(/}/,"&")
        brace_count += n_open - n_close

        # If this line contains the domain in a server_name directive.
        if ($0 ~ "server_name[ \t]+" domain) {
            remove_block = 1
        }
        # Also check for the ACME challenge location.
        if ($0 ~ "location[ \t]+/\\.well-known/acme-challenge") {
            remove_block = 1
        }
        # When the block is closed (brace_count returns to 0), decide whether to print it.
        if (brace_count == 0) {
            if (remove_block) {
                # Skip printing this block.
                # Optionally, print a message to stderr.
                # print "Removing block for domain: " domain > "/dev/stderr"
            } else {
                print_block(block, block_line)
            }
            in_block = 0
            next
        }
        next
    }
    # Lines outside any server block.
    print $0
}' "$NGINX_CONF" > "$TMPFILE"

# Step 3: Replace the original configuration file with the modified file.
sudo mv "$TMPFILE" "$NGINX_CONF"

echo "If a matching Certbot challenge server block was found, it has been removed from ${NGINX_CONF}."
echo "Please test your configuration with: sudo nginx -t"
echo "Then reload nginx with: sudo systemctl reload nginx"
