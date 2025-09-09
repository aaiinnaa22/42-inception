#!/bin/sh
set -e

# Read passwords from secret files
MARIADB_ROOT_PASSWORD=$(cat /run/secrets/mariadb_root_password)
MARIADB_USER_PASSWORD=$(cat /run/secrets/mariadb_user_password)

echo ">>> MARIADB HAS ENV:"
echo "database: $DATABASE"
echo "user: $MARIADB_USER"
echo "root password: $MARIADB_ROOT_PASSWORD"
echo "user password: $MARIADB_USER_PASSWORD"

# Initialize database if empty
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo ">>> Initializing MariaDB database..."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql

    echo ">>> Configuring root and user..."
    mariadbd --bootstrap --user=mysql <<EOSQL
USE mysql;
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}';
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
CREATE DATABASE IF NOT EXISTS ${DATABASE};
CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'%' IDENTIFIED BY '${MARIADB_USER_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DATABASE}.* TO '${MARIADB_USER}'@'%';
FLUSH PRIVILEGES;
EOSQL

    echo ">>> Database initialization complete."
else
    echo ">>> MariaDB already exists, skipping initialization."
fi

echo ">>> Starting MariaDB in foreground..."
mariadbd --defaults-file=/usr/local/etc/mariadb.conf

