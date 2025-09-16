#!/bin/sh
set -e

echo ">>> Waiting for WordPress..."
until nc -z wordpress 9000; do
    sleep 2
done

echo ">>> Generating server key and certificate..."
#generate self-signed SSL certificate for HTTPS
#encrypts traffic
#proves the servers identity
#nginx cant serve https without ssl
openssl req -x509 -nodes \
    -keyout /etc/nginx/ssl/server.key \
    -out /etc/nginx/ssl/server.crt \
    -subj "/C=FI/ST=Uusimaa/L=Helsinki/O=42/OU=Hive/CN=$DOMAIN"


#so nginx can read files, limit write access
echo ">>> Fixing SSL certificate permissions..."
chmod 644 /etc/nginx/ssl/server.crt
chmod 640 /etc/nginx/ssl/server.key

echo ">>> Replacing DOMAIN env in nginx conf..."
envsubst '$DOMAIN' < /etc/nginx/temp_nginx.conf > /etc/nginx/nginx.conf


echo "------------------------------------------"
echo "| ★ ★ Nginx initialization complete! ★ ★ |"
echo "------------------------------------------"

#nginx in the foreground, and so it cant background itself
exec nginx -g "daemon off;"