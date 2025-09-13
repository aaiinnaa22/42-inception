#!/bin/sh
set -e

echo "memory_limit = 512M" >> /etc/php83/php.ini #increase php memory limit, needed for all the wp stuff
WEB_ROOT="/var/www/html"
MARIADB_ROOT_PASSWORD=$(cat /run/secrets/mariadb_root_password)
MARIADB_USER_PASSWORD=$(cat /run/secrets/mariadb_user_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

#command-line tool to manage wordpress
echo ">>> Downloading WP-CLI..." 
wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/local/bin/wp
chmod +x /usr/local/bin/wp

echo ">>> Waiting for MariaDB..."
until mariadb -h "$HOST" -u root -p"$MARIADB_ROOT_PASSWORD" -e "SELECT 1;" >/dev/null 2>&1; do
    sleep 2
done

# Only run WordPress install/config if wp-config.php is missing
if [ ! -f "$WEB_ROOT/wp-config.php" ]; then
    echo ">>> Installing WordPress..."
    wp core download --path="$WEB_ROOT" --allow-root #downloads wordpress core files

	echo ">>> Creating config..."
	#make a conf with my database and connection info
    wp config create \
        --path="$WEB_ROOT" \
        --dbname="$DATABASE" \
        --dbuser="$MARIADB_USER" \
        --dbpass="$MARIADB_USER_PASSWORD" \
        --dbhost="$HOST" \
        --force \
        --allow-root

	#force HTTPS in conf
	echo ">>> Enabling HTTPS for Wordpress..."
    sed -i "/\/\* That's all, stop editing/i \
if ((!empty(\$_SERVER['HTTPS']) && \$_SERVER['HTTPS'] !== 'off') || (!empty(\$_SERVER['HTTP_X_FORWARDED_PROTO']) && \$_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https')) { \$_SERVER['HTTPS'] = 'on'; } \
if (!defined('FORCE_SSL_ADMIN')) define('FORCE_SSL_ADMIN', true); \
define('WP_HOME', 'https://$DOMAIN'); \
define('WP_SITEURL', 'https://$DOMAIN');" "$WEB_ROOT/wp-config.php"

	echo ">>> Installing core..."
	#does the initial wordpress installation, create url, admin and site title
    wp core install \
        --path="$WEB_ROOT" \
        --url="$DOMAIN" \
        --title="Inception Wordpress" \
        --admin_user="$WP_ADMIN" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN@example.com" \
        --skip-email \
        --allow-root

	#force HTTPS  in database
	echo ">>> Forcing HTTPS in DB..."
    wp option update siteurl "https://$DOMAIN" --path="$WEB_ROOT" --allow-root
    wp option update home "https://$DOMAIN" --path="$WEB_ROOT" --allow-root
    wp search-replace "http://$DOMAIN" "https://$DOMAIN" --path="$WEB_ROOT" --all-tables --allow-root

	echo ">>> Creating a user..."
	wp user create "$WP_USER" "$WP_USER@example.com" --role=author --user_pass="$WP_USER_PASSWORD" --path="$WEB_ROOT" --allow-root
else
    echo ">>> WordPress is already downloaded, installed, and configured."
fi

#ensures wordpress files are owned by php user
echo ">>> Fixing permissions..."
chown -R www-data:www-data "$WEB_ROOT"
chmod -R 755 "$WEB_ROOT"

echo "----------------------------------------------"
echo "| ★ ★ Wordpress initialization complete! ★ ★ |"
echo "----------------------------------------------"

#run php fastcgi process manager, runs scripts and hendles requests from nginx. -F = in the foreground

exec php-fpm83 -F
