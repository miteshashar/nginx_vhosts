Nginx Php Websites Vhosts Script
============

This is a simple script that allow you to create a VHost for your PHP based website on your Nginx server.
Also the system is able to create a sftp user to manage the contents, disabling the shell access.

All the websites will be stored under /var/www directory and the main domain will always be the non-www one.

Requirements:

- PHP-FPM;
- NGINX;

Credits:

This script was inspired by the work of: http://www.sebdangerfield.me.uk/2012/05/nginx-and-php-fpm-bash-script-for-creating-new-vhosts-under-separate-fpm-pools/
