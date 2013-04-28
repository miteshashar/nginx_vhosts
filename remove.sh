#!/bin/bash
# @author: Seb Dangerfield
# http://www.sebdangerfield.me.uk/ 
# Created:   02/12/2012
 
# Modify the following to match your system
NGINX_CONFIG='/etc/nginx/sites-available'
NGINX_SITES_ENABLED='/etc/nginx/sites-enabled'
PHP_INI_DIR='/etc/php5/fpm/pool.d'
NGINX_INIT='/etc/init.d/nginx'
PHP_FPM_INIT='/etc/init.d/php5-fpm'
# --------------END 
SED=`which sed`
CURRENT_DIR=`dirname $0`
 
if [ -z $1 ]; then
	echo "No domain name given"
	exit 1
fi
DOMAIN=$1
 
# check the domain is valid!
PATTERN="^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$";
if [[ "$DOMAIN" =~ $PATTERN ]]; then
	DOMAIN=`echo $DOMAIN | tr '[A-Z]' '[a-z]'`
	echo "Removing vhost for:" $DOMAIN
else
	echo "invalid domain name"
	exit 1 
fi
 
echo "What is the username for this site?"
read USERNAME
HOME_DIR=$USERNAME
 
# Remove the user and their home directory
userdel -rf $USERNAME
# Delete the users group from the system
groupdel $USERNAME
 
# Delete the virtual host config
rm -f $NGINX_CONFIG/$DOMAIN.conf
rm -f $NGINX_SITES_ENABLED/$DOMAIN.conf
 
# Delete the php-fpm config
FPMCONF="$PHP_INI_DIR/$DOMAIN.pool.conf"
rm -f $FPMCONF
 
$NGINX_INIT reload
$PHP_FPM_INIT restart
 
echo -e "\nSite removed for $DOMAIN"
