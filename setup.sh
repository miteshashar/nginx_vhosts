#!/bin/bash
# @author: Seb Dangerfield, Matteo Crippa
# http://www.sebdangerfield.me.uk/?p=513 
# Created:   11/08/2011
# Modified:   07/01/2012
# Modified:   27/11/2012
# Modified: 05/06/2013 - Added support for sftp + /var/www < Matteo Crippa >
# Modified: 08/06/2013 - Moved to /srv/www and subdomain support
# Modified: 09/06/2013 - Added support with Wordpress dedicated template

# TODO: new way to handle, system asks for domain, then for subdomain (www and no-www) are used at the same way.
# TODO: testing

# FS structure:
# /srv/www/domain/subdomain/htdocs
# /srv/www/domain/subdomain/_session
# /srv/www/domain/subdomain/_logs


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
    echo "Invalid domain name"
    exit 1 
fi

# Keep default dir for deploy
PUBLIC_HTML_DIR='/htdocs'

# Ask for subdomain (default www)
echo "Are you configuring the www domain (y/n)?"
read CHANGEROOT
if [ $CHANGEROOT == "n" ]; then
    echo "Enter the subdomain you are configuring: (without domain and extension)"
    read SUB
else
    SUB='www'
fi

# Check if you are installing Wordpress
echo "Are you installing wordpress? (y/n)"
read WP
if [ $WP == "y" ]; then
    TEMPLATE='nginx.wordpress.vhost.conf.template'    
    echo "Remember to install W3 Total Cache plugin!!"
else
    if [ $SUB == "www" ]; then
        TEMPLATE='nginx.vhost.conf.template'
    else
        TEMPLATE='nginx.no-www.vhost.conf.template'
    fi
fi

# Create a new user
echo "Please specify the sftp username for this site:"
read USERNAME
useradd $USERNAME

# Now we need to copy the virtual host template
CONFIG=$NGINX_CONFIG/$SUB.$DOMAIN.conf
cp $CURRENT_DIR/$TEMPLATE $CONFIG
$SED -i "s/@@HOSTNAME@@/$SUB.$DOMAIN/g" $CONFIG
$SED -i "s#@@PATH@@#\/srv\/www\/"$DOMAIN\/$SUB\/$PUBLIC_HTML_DIR"#g" $CONFIG
$SED -i "s/@@LOG_PATH@@/\/srv\/www\/$DOMAIN\/$SUB\/_logs/g" $CONFIG
$SED -i "s#@@SOCKET@@#/var/run/"$SUB"."$DOMAIN"_fpm.sock#g" $CONFIG

echo "How many FPM servers would you like by default: (suggested 2)"
read FPM_SERVERS
echo "Min number of FPM servers would you like: (suggested 1)"
read MIN_SERVERS
echo "Max number of FPM servers would you like: (suggested 5)"
read MAX_SERVERS
# Now we need to create a new php fpm pool config
FPMCONF="$PHP_INI_DIR/$SUB.$DOMAIN.pool.conf"

cp $CURRENT_DIR/pool.conf.template $FPMCONF

$SED -i "s/@@USER@@/$USERNAME/g" $FPMCONF
$SED -i "s/@@DOMAIN@@/$DOMAIN/g" $FPMCONF
$SED -i "s/@@HOME_DIR@@/\/srv\/www\/$DOMAIN\/$SUB/g" $FPMCONF
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
ln -s $CONFIG $NGINX_SITES_ENABLED/$SUB.$DOMAIN.conf

# create web dirs
mkdir -p /srv/www/$DOMAIN/$SUB/$PUBLIC_HTML_DIR
mkdir /srv/www/$DOMAIN/$SUB/_logs
mkdir /srv/www/$DOMAIN/$SUB/_sessions

# set user chroot
usermod -d /srv/www/$DOMAIN/$SUB $USERNAME
chown root:root /srv/www/$DOMAIN/$SUB

# set directory permission
chown -R $USERNAME:$USERNAME /srv/www/$DOMAIN/$SUB/$PUBLIC_HTML_DIR 
chmod -R g+rw /srv/www/$DOMAIN/$SUB/$PUBLIC_HTML_DIR

# restart services
$NGINX_INIT reload
$PHP_FPM_INIT restart

echo -e "\nSite Created for $SUB.$DOMAIN with PHP support"
echo -e "\n\nIMPORTANT you need to set $USERNAME password using passwd"