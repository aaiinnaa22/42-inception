FROM alpine:3.21

# Install PHP and utilities
RUN apk add --no-cache php php84-fpm php-mysqli php-pdo_mysql php-openssl \
    php-curl php-json php-mbstring php-xml php-ctype php-session \
    wget unzip shadow bash ca-certificates mariadb-client

COPY ./conf/wp.conf /usr/local/etc/www.conf

COPY ./tools/init_wp.sh /usr/local/bin/init_wp.sh
RUN chmod +x /usr/local/bin/init_wp.sh

EXPOSE 9000

CMD ["init_wp.sh"]