# The runtime image.
FROM php:8.2-apache-bullseye

# Install nano for easier editing/debugging
RUN apt-get update && apt-get install -y nano

# Download micanto release
RUN curl -L https://github.com/micanto-music/micanto/archive/refs/tags/v1.0.0.tar.gz | tar -xz -C /tmp \
  && cd /tmp/micanto-1.0.0/ \
  && rm -rf .editorconfig \
    .git \
    .gitattributes \
    .github \
    .gitignore \
    docs \
    package.json \
    phpunit.xml.dist \
    tests \
    vite.config.js \
    yarn.lock

# Install runtime dependencies.
RUN apt-get update \
  && apt-get install --yes --no-install-recommends \
    libapache2-mod-xsendfile \
    libzip-dev \
    zip \
    locales \
    libpng-dev \
    libjpeg62-turbo-dev \
    libpq-dev \
  && docker-php-ext-configure gd --with-jpeg \
  # https://laravel.com/docs/10.x/deployment#server-requirements
  # ctype, curl, fileinfo, json, mbstring, openssl, tokenizer and xml are already activated in the base image
  && docker-php-ext-install \
     bcmath \
     exif \
     gd \
     opcache \
     pdo \
     pdo_mysql \
     pdo_pgsql \
     pgsql \
     zip \
  && apt-get clean \
  # Create the music volume so it has the correct permissions
  && mkdir /music \
  && chown www-data:www-data /music \
  # Create the search-indexes volume so it has the correct permissions
  && mkdir -p /var/www/html/storage/search-indexes \
  && chown www-data:www-data /var/www/html/storage/search-indexes \
  # Set locale to prevent removal of non-ASCII path characters when transcoding with ffmpeg
  && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
  && /usr/sbin/locale-gen

# Copy Apache configuration
COPY ./apache.conf /etc/apache2/sites-available/000-default.conf

# Copy php.ini
COPY ./php.ini "$PHP_INI_DIR/php.ini"
COPY ./opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY ./.env /var/www/html/.env
# /usr/local/etc/php/php.ini

# Deploy Apache configuration
RUN a2enmod rewrite

# Copy the downloaded release
RUN cp -R /tmp/micanto-1.0.0/. /var/www/html

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php \
    && php -r "unlink('composer-setup.php');" \
    && mv composer.phar /usr/local/bin/composer \
    && composer install


RUN chown -R www-data:www-data /var/www/html

# Volumes for the music files and search index
# This declaration must be AFTER creating the folders and setting their permissions
# and AFTER changing to non-root user.
# Otherwise, they are owned by root and the user cannot write to them.
VOLUME ["/music", "/var/www/html/storage/search-indexes"]

ENV MEDIA_PATH=/music \
    STREAMING_METHOD=x-sendfile \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Setup bootstrap script.
COPY micanto-entrypoint /usr/local/bin/
ENTRYPOINT ["micanto-entrypoint"]
CMD ["apache2-foreground"]

EXPOSE 80

# Check that the homepage is displayed
HEALTHCHECK --interval=5m --timeout=5s \
  CMD curl -f http://localhost/ || exit 1
