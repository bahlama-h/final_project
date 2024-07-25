FROM debian:latest
WORKDIR /var/www/html

RUN apt update && apt -y install apache2 
COPY . ./

EXPOSE 80
CMD apachectl -D FOREGROUND