FROM alpine:3.21

#nginx  -> the web server itself servers HTTPS requests for wordpress
#openssl -> generate SSL certificate for HTTPS
#gettext  -> for env substituting
#netcat-openbsd -> nv to check connectivity with wordpress
RUN apk update && apk add nginx openssl gettext netcat-openbsd

RUN mkdir -p /etc/nginx/ssl

COPY ./conf/nginx.conf /etc/nginx/temp_nginx.conf

EXPOSE 443

COPY ./tools/init_nginx.sh /usr/local/bin/init_nginx.sh
RUN chmod +x /usr/local/bin/init_nginx.sh

CMD ["init_nginx.sh"]