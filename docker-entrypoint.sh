#!/bin/bash

if [ `ls /etc/apache2/sites-available/ | wc -l` -eq 0 ]
then
  cp -r /etc/apache2/sites-available_default/* /etc/apache2/sites-available/
fi

#List site and enable
ls /etc/apache2/sites-available/ -1A | a2ensite *.conf

#LETSECNRYPT
/usr/sbin/apache2ctl start
certbot --apache -n -d $LETSENCRYPTDOMAINS --agree-tos --email $LETSENCRYPTEMAIL
/usr/sbin/apache2ctl stop

#Start Cron
/etc/init.d/anacron start
/etc/init.d/cron start

#Launch Apache on Foreground
/usr/sbin/apache2ctl -D FOREGROUND
