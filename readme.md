# Nginx and cert issue

## Introduction
To start off, I run an NGINX web server. <br/>
I've created a simple `nginx-start.sh` script to start the server <br/>

```
./nginx-start.sh 
```

nginx config is at `./nginx.conf`. edit this file to change the server configuration <br/> and run:
```
./nginx-reload.sh 
```
to reload the server.

## Proxy

I've created a simple script to add configuration to the NGINX server. The script is `./nginx-add-domain.sh` <br/>
This script takes in a domain name and a destination to forward the request to using http protocol. <br/>
`./nginx-add-domain.sh [domain] [destination:port]` <br/>

```

./nginx-add-domain.sh dev.webapp.com localhost:3000

```

#### HTTPS

To add HTTPS, we need to issue a certificate.(there is script below) <br/>
To add HTTPS use this script:
`./nginx-add-domain-https.sh [domain] [destination:port]` <br/>
```
./nginx-add-domain-https.sh dev.webapp.com localhost:3000
```

## Issue certificate

To issue a certificate, we need to use certbot. <br/>
And I have a script to issue a certificate for a domain. <br/>
`./cert-issue.sh [domain]` <br/>

```
./cert-issue.sh dev.webapp.com
```

## Renewal

To do a dry run of cert renewal:

```
certbot renew --dry-run
```

Reload our NGINX web server if the certs change:

```
docker exec -it nginx sh -c "nginx -s reload"
```

Checkout the Certbot [docs](https://certbot.eff.org/instructions) for more details
