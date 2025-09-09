#!/bin/sh
set -e

WEB_ROOT="/var/www/html"
CUSTOM_WP_CONFIG="/usr/local/etc/wp-config.php"
ROOT_PASSWORD=$(cat /run/secrets/root_password)
USER_PASSWORD=$(cat /run/secrets/user_password)

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

# Copy your custom wp-config.php if present
if [ -f "$CUSTOM_WP_CONFIG" ]; then
    echo ">>> Using custom wp-config.php"
    cp "$CUSTOM_WP_CONFIG" "$WEB_ROOT/wp-config.php"
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
until mariadb -h "$HOST" -u root -p"$ROOT_PASSWORD" -e "SELECT 1;" >/dev/null 2>&1; do
    sleep 2
done

echo ">>> WordPress initialization complete."

exec php-fpm84 -F