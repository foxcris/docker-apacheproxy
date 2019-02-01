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
 
 ### Apache Configuration
  | PATH in container | Description |
  | ---------------------- | ----------- |
  | /etc/apache2/sites-available | Directory of all sites configurations to activate an run. If this directory is empty on start default Apache sites are provided. Sites have to use the file extension _.conf_ |
  | /var/log/apache2 | Logging directory |
  | /etc/letsencrypt | Storage of the created let's encrypt certificates |
 
 ### Letsencrypt
  | Environment Variable | Description |
  | ---------------------- | ----------- |
  | LETSENCRYPTDOMAINS | Comma seperated list of all domainnames to request/renew a let's encrypt certificate |
  | LETSENCRYPTEMAIL | E-Mail to be used for notifications from let's encrypt |
