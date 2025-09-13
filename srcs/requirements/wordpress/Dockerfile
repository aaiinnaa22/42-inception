FROM alpine:3.21

#mariadb-client -> interact with mariaDB
#php83 -> php runtime, wordpress cant run without it
#php83-fpm -> fastCGI process manager, for nginx->php communication (php returns wordpress html)
#php83-phar -> needed for WP-CLI
#php83-curl -> wordress can make HTTP requests
#php83-mysqli -> for mariadb connection
#php83-iconv -> text encoding conversion
#php83-json -> json parsing support
#wget -> download files from internet

RUN apk update && apk add mariadb-client \
	php83 \
	php83-fpm \
	php83-phar \
	php83-curl \
	php83-mysqli \
	php83-iconv \
	php83-json \
	wget

COPY ./conf/www.conf /etc/php83/php-fpm.d/www.conf

RUN mkdir -p /var/www/html
#/var/www/wp

COPY ./tools/init_wp.sh /usr/local/bin/init_wp.sh
RUN chmod +x /usr/local/bin/init_wp.sh

#create a non-root user to run php with
RUN adduser -D -H -s /sbin/nologin -g www-data -G www-data www-data

EXPOSE 9000

CMD ["init_wp.sh"]