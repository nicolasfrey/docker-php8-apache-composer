FROM php:8.0-apache

ENV TZ=Europe/Paris
# Set Server timezone.
RUN echo $TZ > /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata
RUN echo date.timezone = $TZ > /usr/local/etc/php/conf.d/docker-php-ext-timezone.ini

### Ajout user docker dans l'image
RUN addgroup docker && \
    useradd -m -d /home/docker -g docker docker

### Config apache
RUN rm /etc/apache2/sites-enabled/000-default.conf && \
    sed -i -e "s/Listen 80/Listen 8080/g" /etc/apache2/ports.conf

# Install Tools
RUN apt-get update && apt-get -y install \
      build-essential \
      htop \
      libzip-dev \
      librecode0 \
      libsqlite3-0 \
      libxml2 \
      curl \
      wget \
      python \
      vim \
      nano \
      cron \
      git \
      unzip \
      autoconf \
      file \
      g++ \
      gcc \
      libc-dev \
      make \
      pkg-config \
      re2c \
      bison \
      apt-utils \
      ghostscript \
      ca-certificates --no-install-recommends

### Install PDFtk
ENV PDFTK_PACKAGES \
    "pdftk"

RUN mkdir -p /usr/share/man/man1 && \
    apt-get update && \
    apt-get install -y --no-install-recommends $PDFTK_PACKAGES && \
    rm -rf /var/lib/apt/lists/*

# Install PHP Extension
RUN apt-get update && apt-get install -y \
      libfreetype6-dev \
      libjpeg62-turbo-dev \
      libpng-dev \
      libsqlite3-dev \
      libssl-dev \
      libxml2-dev \
      libzzip-dev \
      libldap2-dev  \
      libicu-dev \
      libxslt-dev \
      libc-client-dev \
      libkrb5-dev \
      libxml2-dev \
      libpcre3-dev \
   && docker-php-ext-install calendar bcmath intl mysqli pdo_mysql zip soap \
   && docker-php-ext-configure opcache --enable-opcache && docker-php-ext-install opcache \
   && docker-php-ext-configure gd \
   && docker-php-ext-install gd

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Set up composer variables
ENV COMPOSER_ALLOW_SUPERUSER=1

# Install composer system-wide
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php -r "if (hash_file('sha384', 'composer-setup.php') === '906a84df04cea2aa72f40b5f787e49f22d4c2f19492ac310e8cba5b96ac8b64115ac402c8cd292b8a03482574915d1a8') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    php -r "unlink('composer-setup.php');" && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

### Install node 16 / NPM
RUN curl -sL https://deb.nodesource.com/setup_16.x -o nodesource_setup.sh && \
    bash nodesource_setup.sh && \
    apt-get update && \
    apt-get -y install nodejs

### Install Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && \
    apt-get -y --no-install-recommends install yarn

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
   echo 'opcache.memory_consumption=256'; \
   echo 'opcache.interned_strings_buffer=8'; \
   echo 'opcache.max_accelerated_files=4000'; \
   echo 'opcache.revalidate_freq=2'; \
   echo 'opcache.fast_shutdown=1'; \
   echo 'opcache.enable_cli=1'; \
   echo 'opcache.enable=1'; \
} > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN { \
   echo 'max_execution_time = 30'; \
   echo 'error_reporting =  E_ALL'; \
   echo 'log_errors = On'; \
   echo 'display_errors = Off'; \
   echo 'memory_limit = 2048M'; \
   echo 'date.timezone = Europe/Paris'; \
   echo 'soap.wsdl_cache = 0'; \
   echo 'soap.wsdl_cache_enabled = 0'; \
   echo 'post_max_size = 100M'; \
   echo 'upload_max_filesize = 100M'; \
} > /usr/local/etc/php/php.ini

# Create Volume
VOLUME ['/etc/apache2/sites-enabled','/var/www/html']

WORKDIR /var/www/html

EXPOSE 8080