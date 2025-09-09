FROM alpine:3.21

# Install PHP and utilities
RUN apk update && apk add mariadb-client \
	php84 \
	php84-fpm \
	php84-phar \
	php84-curl \
	php84-mysqli \
	php84-iconv \
	php84-json \
	wget \
	curl \
	php84-mbstring

RUN ln -s /usr/bin/php84 /usr/bin/php

RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

COPY ./conf/www.conf /etc/php82/php-fpm.d/www.conf
#really used? ^

COPY ./tools/init_wp.sh /usr/local/bin/init_wp.sh
RUN chmod +x /usr/local/bin/init_wp.sh

EXPOSE 9000

CMD ["init_wp.sh"]