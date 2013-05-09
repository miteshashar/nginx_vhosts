Nginx Php Websites Vhosts Script
============

This is a simple script that allow you to create a VHost for your PHP based website on your Nginx server.
Also the system is able to create a sftp user to manage the contents, disabling the shell access.

All the websites will be stored under /srv/www directory and the main domain will always be the non-www one.

Requirements:

- PHP-FPM;
- NGINX;

Credits:

This script was inspired by the work of: http://www.sebdangerfield.me.uk/2012/05/nginx-and-php-fpm-bash-script-for-creating-new-vhosts-under-separate-fpm-pools/

Nginx Template inspired by: http://rtcamp.com/tutorials/nginx-wordpress-fastcgi_cache-with-conditional-purging/

Changelog:
============

Created:   11/08/2011
Modified:   07/01/2012
Modified:   27/11/2012
Modified: 05/06/2013 - Added support for sftp + /var/www < Matteo Crippa >
Modified: 08/06/2013 - Moved to /srv/www and subdomain support < Matteo Crippa >
Modified: 09/06/2013 - Added support with Wordpress dedicated template < Matteo Crippa >
