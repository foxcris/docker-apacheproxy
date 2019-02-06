# Apache Proxy Installation

A simple apache installation with all required modules to run as a proxy in front of other webservers.
Main Features:
 * automatic creation and renew of letsencrypt certificates
 * automatic activation of all available site configuration
 
## Apache Modules
The following apache modules are activated:
 * proxy_http
 * proxy_wstunnel
 * ssl
 * remoteip
 * rewrite
 * headers
 * http2
 
## Configuration
 
### Configuration files, log files, buisness data
The following directories can be loaded from the host to keep the data and configuration files out of the container:

 | PATH in container | Description |
 | ---------------------- | ----------- |
 | /etc/apache2/sites-available | Directory of all sites configurations to activate an run. If this directory is empty on start default Apache sites are provided. Sites have to use the file extension _.conf_ |
 | /var/log/apache2 | Apache logging directory |
 | /var/log/letsencrypt | Let's encrypt logging directory |
 | /etc/letsencrypt | Storage of the created let's encrypt certificates |
 
### Environment variables
The following environment variables are available to configure the container on startup.

 | Environment Variable | Description |
 | ---------------------- | ----------- |
 | LETSENCRYPTDOMAINS | Comma seperated list of all domainnames to request/renew a let's encrypt certificate |
 | LETSENCRYPTEMAIL | E-Mail to be used for notifications from let's encrypt |

## Container Tags

 | Tag name | Description |
 | ---------------------- | ----------- |
 | latest | Latest stable version of the container |
 | stable | Latest stable version of the container |
 | dev | latest development version of the container. Do not use in production environments! |

## Usage

To run the container and store the data and configuration on the local host run the following commands:
1. Create storage directroy for the configuration files, log files and data. Also create a directroy to store the necessary script to create the docker container and replace it (if not using eg. watchtower)
```
mkdir /srv/docker/apacheproxy
mkdir /srv/docker-config/apacheproxy
```
2. Create an specific docker network to connect apacheproxy to the required subsequent containers. By using a specific docker network name resolution can be used to connect to the other containers.
```
docker network create \
 --driver=bridge \
 --subnet=172.18.0.0/16 \
 --ip-range=172.18.0.0/24 \
 apacheproxy
```

3. Create an file to store the configuration of the environment variables
```
touch /srv/docker-config/apacheproxy/env_file
``` 
```
#Comma seperated list of domainnames
LETSENCRYPTDOMAINS=subdomain-1.example.com,subdomain-2.example.com,www.example.com
LETSENCRYPTEMAIL=example@example.com
```

3. Create the docker container and configure the docker networks for the container. I always create a script for that and store it under
```
touch /srv/docker-config/apacheproxy/create.sh
```
Content of create.sh:
```
#!/bin/bash

docker pull foxcris/docker-apacheproxy
docker create\
 --restart always\
 --name apacheproxy\
 --volume "/srv/docker/apacheproxy/etc/apache2/sites-available:/etc/apache2/sites-available"\
 --volume "/srv/docker/apacheproxy/var/log/apache2:/var/log/apache2"\
 --volume "/srv/docker/apacheproxy/etc/letsencrypt:/etc/letsencrypt"\
 --env-file=/srv/docker-config/apacheproxy/env_file\
 -p 80:80\
 -p 443:443\
 foxcris/docker-apacheproxy
docker network connect apacheproxy apacheproxy
docker network disconnect bridge apacheproxy
```

4. Create replace.sh to install/update the container. Store it in
```
touch /srv/docker-config/apacheproxy/replace.sh
```
```
#/bin/bash
docker stop apacheproxy
docker rm apacheproxy
./create.sh
docker start apacheproxy
```

## Example Apache vhost Configurations

### Redirect HTTP to HTTPs
```
<VirtualHost *:80>
        ServerName example.example.com
        ServerAdmin example@example.com

        RewriteEngine On
        # This will enable the Rewrite capabilities

        RewriteCond %{HTTPS} !=on
        # This checks to make sure the connection is not already HTTPS

        RewriteRule ^/?(.*) https://%{SERVER_NAME}/$1 [R,L]
        # This rule will redirect users from their original location, to the same location but using HTTPS.
        # i.e.  http://www.example.com/foo/ to https://www.example.com/foo/
        # The leading slash is made optional so that this will work either in httpd.conf
        # or .htaccess context

        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```

### HTTP Proxy
```
<VirtualHost *:80>
        ServerName example.example.com
        ServerAdmin example@example.com

        #Hardening - start
        <IfModule mod_headers.c>
           #Instructs some browsers to not sniff the mimetype of files. This is used for example to prevent browsers from interpreting text files as JavaScript.
           Header set X-Content-Type-Options nosniff
           #Instructs browsers to enable their browser side Cross-Site-Scripting filter.
           Header set X-XSS-Protection: "1; mode=block"
           #Instructs search machines to not index these pages.
           Header set X-Robots-Tag: none
           #Prevents embedding of the Nextcloud instance within an iframe from other domains to prevent Clickjacking and other similar attacks.
           Header set X-Frame-Options: SAMEORIGIN
        </IfModule>

        #No directory Listing
        Options -Indexes

        #No module and version information of the server
        ServerSignature Off

        #Hardening - end

        Protocols h2 http/1.1

        ProxyRequests Off
        ProxyVia Off
        ProxyPreserveHost On

        <Proxy *>
          Require all granted
        </Proxy>

        ProxyPass / http://examplecontainer:80/
        ProxyPassReverse / http://examplecontainer:80/

        RemoteIPHeader X-Forwarded-For

        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```

### HTTPs to HTTP Proxy
```
<VirtualHost *:443>
        ServerName example.example.com
        ServerAdmin examplee@example.com

        #Hardening - start
        <IfModule mod_headers.c>
           #Remember HTTPS
           Header always set Strict-Transport-Security "max-age=15768000;"
           #Instructs some browsers to not sniff the mimetype of files. This is used for example to prevent browsers from interpreting text files as JavaScript.
           Header set X-Content-Type-Options nosniff
           #Instructs browsers to enable their browser side Cross-Site-Scripting filter.
           Header set X-XSS-Protection: "1; mode=block"
           #Instructs search machines to not index these pages.
           Header set X-Robots-Tag: none
           #Prevents embedding of the Nextcloud instance within an iframe from other domains to prevent Clickjacking and other similar attacks.
           Header set X-Frame-Options: SAMEORIGIN
        </IfModule>

        #No directory Listing
        Options -Indexes

        #No module and version information of the server
        ServerSignature Off

        #Hardening - end

        Protocols h2 http/1.1

        ProxyRequests Off
        ProxyVia Off
        ProxyPreserveHost On

        <Proxy *>
          Require all granted
        </Proxy>

        ProxyPass / http://examplecontainer:80/
        ProxyPassReverse / http://examplecontainer:80/

        RemoteIPHeader X-Forwarded-For
        RequestHeader set X-Forwarded-Proto "https"

        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
        
        Include /etc/letsencrypt/options-ssl-apache.conf
        SSLCertificateFile /etc/letsencrypt/live/example.example.com/fullchain.pem
        SSLCertificateKeyFile /etc/letsencrypt/live/example.example.com/privkey.pem
</VirtualHost>

```

### HTTPs to HTTPs Proxy
```
<VirtualHost *:443>
        ServerName example.example.com
        ServerAdmin examplee@example.com

        #Hardening - start
        <IfModule mod_headers.c>
           #Remember HTTPS
           Header always set Strict-Transport-Security "max-age=15768000;"
           #Instructs some browsers to not sniff the mimetype of files. This is used for example to prevent browsers from interpreting text files as JavaScript.
           Header set X-Content-Type-Options nosniff
           #Instructs browsers to enable their browser side Cross-Site-Scripting filter.
           Header set X-XSS-Protection: "1; mode=block"
           #Instructs search machines to not index these pages.
           Header set X-Robots-Tag: none
           #Prevents embedding of the Nextcloud instance within an iframe from other domains to prevent Clickjacking and other similar attacks.
           Header set X-Frame-Options: SAMEORIGIN
        </IfModule>

        #No directory Listing
        Options -Indexes

        #No module and version information of the server
        ServerSignature Off

        #Hardening - end

        Protocols h2 http/1.1

        ProxyRequests Off
        ProxyVia Off
        ProxyPreserveHost On

        <Proxy *>
          Require all granted
        </Proxy>

        ProxyPass / http://examplecontainer:443/
        ProxyPassReverse / http://examplecontainer:443/

        RemoteIPHeader X-Forwarded-For
        RequestHeader set X-Forwarded-Proto "https"

        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
        
        Include /etc/letsencrypt/options-ssl-apache.conf
        SSLCertificateFile /etc/letsencrypt/live/example.example.com/fullchain.pem
        SSLCertificateKeyFile /etc/letsencrypt/live/example.example.com/privkey.pem
</VirtualHost>

```
