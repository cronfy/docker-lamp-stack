FROM cronfy/lamp7.4

ENV PHPVER=7.4
ENV TIMEZONE_AREA=Europe
ENV TIMEZONE_CITY=Moscow



# Build setup

RUN apt-get update

# for apt-wget
RUN apt-get -y install wget

# build helpers
COPY scripts/apt-wget.sh /root/
COPY scripts/set-timezone.sh /root/





# System setup

# timezone
RUN /root/set-timezone.sh $TIMEZONE_AREA $TIMEZONE_CITY






# PHP setup
RUN sed -i "s/^[\s;]*date.timezone =.*/date.timezone = $TIMEZONE_AREA\/$TIMEZONE_CITY/g" /etc/php/$PHPVER/apache2/php.ini
RUN sed -i "s/^[\s;]*date.timezone =.*/date.timezone = $TIMEZONE_AREA\/$TIMEZONE_CITY/g" /etc/php/$PHPVER/cli/php.ini






# Generic project

RUN /root/apt-wget.sh git

# npm, yarn
RUN /root/apt-wget.sh curl
# yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
# node
# implies apt-get update
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash
RUN /root/apt-wget.sh nodejs yarn

# composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php && \
    php -r "unlink('composer-setup.php');" && \
    mv composer.phar /usr/local/bin/composer

# php project packages
# intl required for generic project as it is heavily used in yii projects
RUN /root/apt-wget.sh php$PHPVER-intl && update-alternatives --set php /usr/bin/php$PHPVER






# LIK setup

# ssh 
RUN mkdir -p /var/www/.ssh
COPY data/known_hosts /var/www/.ssh/

RUN chown -R www-data:staff /var/www/.ssh/
RUN chmod 700 /var/www/.ssh/
RUN chmod 644 /var/www/.ssh/known_hosts

COPY data/.bash_profile /var/www/
RUN chown www-data:staff /var/www/.bash_profile

# mail
RUN yarn global add catchmail
RUN yarn global add maildev
COPY data/catchmail-wrapper /usr/local/bin/
RUN mkdir -p /var/www/log
RUN chown www-data:staff /var/www/log
COPY data/99-sendmail.ini /etc/php/$PHPVER/cli/conf.d/
COPY data/99-sendmail.ini /etc/php/$PHPVER/apache2/conf.d/

# document root
RUN ln -nfs /app/web /var/www/html

# UPDATES

# always needed
RUN apt update && /root/apt-wget.sh mc unzip imagemagick
# mc requires this for subshell to work
RUN chsh -s /bin/bash www-data

COPY data/run.sh /run.sh

