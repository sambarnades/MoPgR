# Use the official PHP 8.5.3 Apache image as the base
FROM php:8.5-apache

ARG GIT_REMOTE_REPO_URL=${GIT_REMOTE_REPO_URL}

# Set the working directory inside the container
WORKDIR /var/www/html/

# Copy Apache configuration files for Moodle
ADD ${GIT_REMOTE_REPO_URL}/apache_configuration/moodle_listener.conf /etc/apache2/moodle_listener.conf
RUN echo "<VirtualHost *:80>" >> /etc/apache2/sites-available/000-default.conf && \
    echo "Include /etc/apache2/moodle_listener.conf" >> /etc/apache2/sites-available/000-default.conf && \
    echo "</VirtualHost>" >> /etc/apache2/sites-available/000-default.conf

# Set permissions for the Moodle directory
RUN mkdir /var/www/html/moodle && \
    chown -R root:www-data /var/www/html/moodle/ && \
    chmod 0770 /var/www/html/moodle/

# Copy Moodle 5.2 stable content directly into the html directory
COPY ./moodle/ /var/www/html/moodle/
 
# Copy the setup script into the container
COPY ./setup.sh /var/www/html/
COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Install system dependencies required for Moodle and PHP extensions
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      git \
      unzip \
      libzip-dev \
      libjpeg-dev \
      libpng-dev \
      libfreetype6-dev \
      libpq-dev \
      libicu-dev \
      libxml2-dev \
      libonig-dev \
      nano \
      cron && \
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j$(nproc) zip gd pgsql pdo_pgsql intl soap exif

    # Set PHP settings for Moodle: max_input_vars and OPcache
RUN echo "max_input_vars=5000" >> /usr/local/etc/php/conf.d/docker-php-moodle.ini && \
    echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/docker-php-opcache.ini && \
    echo "opcache.enable_cli=1" >> /usr/local/etc/php/conf.d/docker-php-opcache.ini && \
    echo "opcache.memory_consumption=128" >> /usr/local/etc/php/conf.d/docker-php-opcache.ini && \
    echo "opcache.interned_strings_buffer=8" >> /usr/local/etc/php/conf.d/docker-php-opcache.ini && \
    echo "opcache.max_accelerated_files=10000" >> /usr/local/etc/php/conf.d/docker-php-opcache.ini && \
    echo "opcache.revalidate_freq=60" >> /usr/local/etc/php/conf.d/docker-php-opcache.ini && \
    echo "opcache.validate_timestamps=1" >> /usr/local/etc/php/conf.d/docker-php-opcache.ini && \

    # Change post_max_size; upload_max_filesize ; max_execution_time
    echo "post_max_size=100M" >> /usr/local/etc/php/conf.d/docker-php-filsize.ini && \
    echo "upload_max_filesize=100M" >> /usr/local/etc/php/conf.d/docker-php-filsize.ini && \
    echo "max_execution_time=300" >> /usr/local/etc/php/conf.d/docker-php-filsize.ini

# ----------------------------------------------------------- #

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Expose port 80 for HTTP traffic
EXPOSE 80