FROM cronfy/lam

ENV PHPVER=7.2
ENV TIMEZONE_AREA=Etc
ENV TIMEZONE_CITY=UTC

RUN add-apt-repository -y ppa:ondrej/php && apt-get update

RUN apt-get -y install php$PHPVER libapache2-mod-php$PHPVER php$PHPVER-mysql php$PHPVER-gd php$PHPVER-xml php$PHPVER-mbstring php$PHPVER-gettext php$PHPVER-zip php$PHPVER-curl php$PHPVER-gmp

RUN sed -i "s/^[\s;]*date.timezone =.*/date.timezone = $TIMEZONE_AREA\/$TIMEZONE_CITY/g" /etc/php/$PHPVER/apache2/php.ini
RUN sed -i "s/^[\s;]*date.timezone =.*/date.timezone = $TIMEZONE_AREA\/$TIMEZONE_CITY/g" /etc/php/$PHPVER/cli/php.ini

