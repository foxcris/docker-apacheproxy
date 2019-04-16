#!/bin/bash

if [ `ls /etc/apache2/sites-available/ | wc -l` -eq 0 ]
then
  cp -r /etc/apache2/sites-available_default/* /etc/apache2/sites-available/
fi

if [ `ls /etc/letsencrypt/ | wc -l` -eq 0 ]
then
  cp -r /etc/letsencrypt_default/* /etc/letsencrypt/
fi

#List site and enable
ls /etc/apache2/sites-available/ -1A | a2ensite *.conf

#Start Apache
/etc/init.d/apache2 start

#Start Cron
/etc/init.d/anacron start
/etc/init.d/cron start

#LETSECNRYPT
if [ "$LETSENCRYPTDOMAINS" != "" ]
then
  domains=$(echo $LETSENCRYPTDOMAINS | tr "," "\n")
  for domain in $domains
  do
    if [[ $domain == *"#"* ]]; then
      echo "SAN Certificate"
      #replace seperators
      domain=`echo $domain | sed 's/#/,/g'`
    fi
    certbot --apache --noninteractive --expand --domains $domain --agree-tos --email $LETSENCRYPTEMAIL
  done
fi

tail -f /var/log/apache2/access.log -f /var/log/apache2/error.log
