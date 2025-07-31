FROM php:8.3-cli-alpine

# Install essential build tools and dependencies for IMAP
RUN apk add --update --no-cache --virtual .build-deps \
    g++ autoconf make linux-headers \
    openssl-dev \
    libzip-dev \
    curl-dev \
    imap-dev \
    krb5-dev \
    && apk add --update --no-cache \
    openssl \
    libzip \
    c-client \
    krb5 \
    curl \
    git

# Install composer
ENV COMPOSER_HOME /composer
ENV PATH ./vendor/bin:/composer/vendor/bin:$PATH
ENV COMPOSER_ALLOW_SUPERUSER 1
RUN curl -s https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer

# Configure and install PHP extensions
RUN docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install -j$(nproc) \
    imap \
    curl \
    zip \
    fileinfo \
    opcache

# Configure opcache for better performance
RUN echo 'opcache.enable=1' >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo 'opcache.memory_consumption=128' >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo 'opcache.interned_strings_buffer=8' >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo 'opcache.max_accelerated_files=4000' >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo 'opcache.revalidate_freq=2' >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo 'opcache.fast_shutdown=1' >> /usr/local/etc/php/conf.d/opcache.ini

# Clean up build dependencies
RUN apk del .build-deps \
    && rm -rf /tmp/* /var/cache/apk/*

# Set working directory
WORKDIR /app

# Create necessary directories
RUN mkdir -p attachments cache/views \
    && chmod 755 attachments cache/views

ENTRYPOINT ["php"]