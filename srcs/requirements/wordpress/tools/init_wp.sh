#!/bin/sh
set -e

WEB_ROOT="/var/www/html"
CUSTOM_WP_CONFIG="/usr/local/etc/wp-config.php"
MARIADB_ROOT_PASSWORD=$(cat /run/secrets/mariadb_root_password)
MARIADB_USER_PASSWORD=$(cat /run/secrets/mariadb_user_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

echo ">>> Initializing WordPress..."

# Download WordPress if not exists
if [ ! -f "$WEB_ROOT/wp-config.php" ]; then
    echo ">>> Downloading WordPress..."
    wget https://wordpress.org/latest.zip -O /tmp/wordpress.zip
    unzip -o  -q /tmp/wordpress.zip -d /tmp
    cp -a /tmp/wordpress/. "$WEB_ROOT/"
    rm -rf /tmp/wordpress /tmp/wordpress.zip
    echo ">>> WordPress downloaded."
fi

if ! getent group www-data > /dev/null; then
    addgroup -S www-data
fi

# Create www-data user if it doesn't exist
if ! id -u www-data > /dev/null 2>&1; then
    adduser -S -G www-data www-data
fi

# Set permissions
echo ">>> Setting permissions..."
chown -R www-data:www-data "$WEB_ROOT"
find "$WEB_ROOT" -type d -exec chmod 755 {} \;
find "$WEB_ROOT" -type f -exec chmod 644 {} \;

# Wait for MariaDB to be ready
echo ">>> Waiting for MariaDB..."
until mariadb -h "$HOST" -u root -p"$MARIADB_ROOT_PASSWORD" -e "SELECT 1;" >/dev/null 2>&1; do
    sleep 2
done

if [ ! -f "$WEB_ROOT/wp-config.php" ]; then
    echo ">>> Generating wp-config.php..."
    wp core config \
        --path="$WEB_ROOT" \
        --dbname="$DATABASE" \
        --dbuser="$MARIADB_USER" \
        --dbpass="$MARIADB_USER_PASSWORD" \
        --dbhost="$HOST" \
        --allow-root
fi

if  ! wp core is-installed --path="$WEB_ROOT" --allow-root; then
    echo ">>> Running wp core install..."
    wp core install \
        --path="$WEB_ROOT" \
        --url="$DOMAIN" \
        --title="Inception wordpress" \
        --admin_user="$WP_ADMIN" \
        --admin_password="$WP_ADMIN_PASSWORD" \
		--admin_email="$WP_ADMIN@example.com" \
        --skip-email \
        --allow-root

	wp user create "$WP_USER" "$WP_USER@example.com" \
		--path="$WEB_ROOT" \
        --role=author \
        --user_pass="$WP_USER_PASSWORD" \
        --allow-root
else
    echo ">>> WordPress already installed."
fi

echo ">>> WordPress initialization complete."

exec php-fpm84 -F