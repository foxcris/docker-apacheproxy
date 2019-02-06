FROM debian:stretch

MAINTAINER foxcris

#repositories richtig einrichten
RUN echo 'deb http://deb.debian.org/debian stretch main' > /etc/apt/sources.list
RUN echo 'deb http://deb.debian.org/debian stretch-updates main' >> /etc/apt/sources.list
RUN echo 'deb http://security.debian.org stretch/updates main' >> /etc/apt/sources.list
#backports fuer certbot
RUN echo 'deb http://ftp.debian.org/debian stretch-backports main' >> /etc/apt/sources.list

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y locales && apt-get clean
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    echo 'LANG="en_US.UTF-8"'>/etc/default/locale && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

ENV LANG en_US.UTF8
#automatische aktualiserung installieren + basic tools
RUN apt-get update && apt-get -y upgrade && DEBIAN_FRONTEND=noninteractive apt-get install -y nano less wget anacron unattended-upgrades apt-transport-https htop && apt-get clean

#apache
RUN apt-get update && apt-get -y upgrade && DEBIAN_FRONTEND=noninteractive apt-get install -y apache2 && apt-get clean

#certbot
RUN apt-get update && apt-get -y upgrade && DEBIAN_FRONTEND=noninteractive apt-get install -y python-certbot-apache -t stretch-backports && apt-get clean

RUN a2enmod proxy_http
RUN a2enmod proxy_wstunnel
RUN a2enmod ssl
RUN a2enmod remoteip
RUN a2enmod rewrite
RUN a2enmod headers
RUN a2enmod http2
RUN a2dissite 000-default.conf 

RUN mv /etc/apache2/sites-available/ /etc/apache2/sites-available_default
RUN mkdir /etc/apache2/sites-available
RUN mv /etc/letsencrypt/ /etc/letsencrypt_default
RUN mkdir /etc/letsencrypt

VOLUME /etc/apache2/sites-available
VOLUME /var/log/apache2
VOLUME /var/log/letsencrypt
VOLUME /etc/letsencrypt

EXPOSE 80 443
COPY docker-entrypoint.sh /
RUN chmod 755 /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
