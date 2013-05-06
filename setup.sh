#!/bin/bash
# @author: Seb Dangerfield
# http://www.sebdangerfield.me.uk/?p=513 
# Created:   11/08/2011
# Modified:   07/01/2012
# Modified:   27/11/2012
# Modified: 05/06/2013 - Added support for sftp + /var/www < Matteo Crippa >

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
    echo "Creating hosting for:" $DOMAIN
else
    echo "invalid domain name"
    exit 1 
fi

# Create a new user
echo "Please specify the sftp username for this site:"
read USERNAME
useradd $USERNAME

PUBLIC_HTML_DIR='/htdocs'

# Now we need to copy the virtual host template
CONFIG=$NGINX_CONFIG/$DOMAIN.conf
cp $CURRENT_DIR/nginx.vhost.conf.template $CONFIG
$SED -i "s/@@HOSTNAME@@/$DOMAIN/g" $CONFIG
$SED -i "s#@@PATH@@#\/var\/www\/"$DOMAIN$PUBLIC_HTML_DIR"#g" $CONFIG
$SED -i "s/@@LOG_PATH@@/\/var/\www\/$DOMAIN\/logs/g" $CONFIG
$SED -i "s#@@SOCKET@@#/var/run/"$DOMAIN"_fpm.sock#g" $CONFIG

echo "How many FPM servers would you like by default: (suggested 2)"
read FPM_SERVERS
echo "Min number of FPM servers would you like: (suggested 1)"
read MIN_SERVERS
echo "Max number of FPM servers would you like: (suggested 5)"
read MAX_SERVERS
# Now we need to create a new php fpm pool config
FPMCONF="$PHP_INI_DIR/$DOMAIN.pool.conf"

cp $CURRENT_DIR/pool.conf.template $FPMCONF

$SED -i "s/@@USER@@/$USERNAME/g" $FPMCONF
$SED -i "s/@@HOME_DIR@@/\/var\/www\/$DOMAIN/g" $FPMCONF
$SED -i "s/@@START_SERVERS@@/$FPM_SERVERS/g" $FPMCONF
$SED -i "s/@@MIN_SERVERS@@/$MIN_SERVERS/g" $FPMCONF
$SED -i "s/@@MAX_SERVERS@@/$MAX_SERVERS/g" $FPMCONF
MAX_CHILDS=$((MAX_SERVERS+START_SERVERS))
$SED -i "s/@@MAX_CHILDS@@/$MAX_CHILDS/g" $FPMCONF

# disable shell for user
usermod -s /bin/false $USERNAME

# set user groups
adduser $USERNAME sftp
adduser $USERNAME www-data

# move the config file
chmod 600 $CONFIG
ln -s $CONFIG $NGINX_SITES_ENABLED/$DOMAIN.conf

# create web dirs
mkdir -p /var/www/$DOMAIN/htdocs
mkdir /var/www/$DOMAIN/logs
mkdir /var/www/$DOMAIN/sessions

# set user chroot
usermod -d /var/www/$DOMAIN $USERNAME
chown root:root /var/www/$DOMAIN

# set directory permission
chown -R $USERNAME:$USERNAME /var/www/$DOMAIN/htdocs 
chmod -R g+rw /var/www/$DOMAIN/htdocs

#$NGINX_INIT reload
#$PHP_FPM_INIT restart

echo -e "\nSite Created for $DOMAIN with PHP support"