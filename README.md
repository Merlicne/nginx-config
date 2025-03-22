# Nginx and Certbot with Docker Compose

This project sets up Nginx and Certbot in Docker containers for serving web content and managing SSL certificates.

## Setup

1. Clone this repository
2. Make sure you have Docker and Docker Compose installed

## Usage

### Starting the services

```bash
docker-compose up -d nginx
```

This will start the Nginx service in the background.

### Nginx Host Network Mode

The Nginx container uses host network mode, which means:

- It shares the network namespace with the host
- It can directly access services running on the host machine
- Ports 80 and 443 on your host machine will be used by Nginx
- No port mapping is required

### Generating SSL certificates

To generate SSL certificates for your domain:

```bash
docker-compose run --rm certbot certonly --webroot --webroot-path=/letsencrypt -d yourdomain.com
```

Replace `yourdomain.com` with your actual domain.

### Reloading Nginx after certificate generation

After generating certificates, you may need to reload Nginx to use them:

```bash
docker-compose exec nginx nginx -s reload
```

## File Structure

- `docker-compose.yml`: Docker Compose configuration
- `nginx.conf`: Nginx configuration file
- `Dockerfile`: Used to build the Certbot image
- `certs/`: Directory where Let's Encrypt certificates are stored

## Notes

- The Certbot container is designed to run once and exit
- SSL certificates are stored in the `certs` directory
- Make sure your domain is pointing to your server before generating certificates
- Since Nginx uses host networking, make sure ports 80 and 443 are not used by other services on the host
