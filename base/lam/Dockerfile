FROM phusion/baseimage
MAINTAINER cronfy <cronfy@gmail.com>

# Based on mattrayner/lamp:latest-1604
ENV REFRESHED_AT 2018-02-19

#
# Fresh Ubuntu
#

# Install packages
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get -y upgrade

#
# LAM - no P yet
#

# Apache

ENV DOCKER_USER_ID 501 
ENV DOCKER_USER_GID 20

ENV BOOT2DOCKER_ID 1000
ENV BOOT2DOCKER_GID 50

# Tweaks to give Apache write permissions to the app
RUN usermod -u ${BOOT2DOCKER_ID} www-data && \
    usermod -G staff www-data && \
    useradd -r mysql && \
    usermod -G staff mysql

RUN groupmod -g $(($BOOT2DOCKER_GID + 10000)) $(getent group $BOOT2DOCKER_GID | cut -d: -f1)
RUN groupmod -g ${BOOT2DOCKER_GID} staff

RUN  apt-get -y install apache2

ADD supporting_files/start-apache2.sh /start-apache2.sh

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# config to enable .htaccess
ADD supporting_files/apache_default /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite

# Configure /app folder with sample app
RUN mkdir -p /app && rm -fr /var/www/html && ln -s /app /var/www/html
ADD app/ /app

# Mysql

RUN  apt-get -y install mysql-server pwgen

ENV MYSQL_PASS:-$(pwgen -s 12 1)

# Add MySQL utils
ADD supporting_files/start-mysqld.sh /start-mysqld.sh
ADD supporting_files/create_mysql_users.sh /create_mysql_users.sh

# Remove pre-installed database
RUN rm -rf /var/lib/mysql

# Supervisor

RUN  apt-get -y install supervisor 

ADD supporting_files/supervisord-apache2.conf /etc/supervisor/conf.d/supervisord-apache2.conf
ADD supporting_files/supervisord-mysqld.conf /etc/supervisor/conf.d/supervisord-mysqld.conf

# Entrypoint

ADD supporting_files/run.sh /run.sh

# Chmod

RUN chmod 755 /*.sh

# Final

RUN apt-get -y autoremove

# Bugs

RUN mkdir -p /var/lock/apache2
RUN mkdir -p /var/run/apache2

# Add volumes for the app and MySql
VOLUME  ["/etc/mysql", "/var/lib/mysql", "/app" ]

#EXPOSE 80 3306
CMD ["/run.sh"]

