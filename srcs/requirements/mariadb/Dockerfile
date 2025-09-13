FROM alpine:3.21

#install mariadb server and mariadb command-line client
RUN apk update && apk add mariadb mariadb-client

#neccessary dirs made, mariaDB runs as mysql user and has write access
RUN mkdir -p /var/lib/mysql /run/mysqld \
	&& chown -R mysql:mysql /var/lib/mysql /run/mysqld 

COPY ./tools/init_mariadb.sh /usr/local/bin/init_mariadb.sh
RUN chmod +x /usr/local/bin/init_mariadb.sh

COPY ./conf/mariadb.conf /usr/local/etc/mariadb.conf

EXPOSE 3306

CMD ["init_mariadb.sh"]