FROM alpine:3.21

RUN apk update && apk add nginx openssl gettext netcat-openbsd

RUN mkdir -p /etc/nginx/ssl

COPY ./conf/nginx.conf /etc/nginx/temp_nginx.conf

EXPOSE 443

COPY ./tools/init_nginx.sh /usr/local/bin/init_nginx.sh
RUN chmod +x /usr/local/bin/init_nginx.sh

CMD ["init_nginx.sh"]