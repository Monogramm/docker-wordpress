FROM wordpress:4.9-php7.2-apache

LABEL maintainer="mb.mathieu.brunot@gmail.com"

RUN set -ex; \
	\
    apt-get update && \
    apt-get install --no-install-recommends -y \
		bzip2 \
		csstidy \
		tidy \
		unzip \
		zip \
	&& \
    mkdir -p /usr/src/php/ext && \
    # Install needed libraries
    #
    apt-get install -y \
        libcurl4-openssl-dev \
        libfreetype6-dev \
        libicu-dev \
        libjpeg-dev \
        libldap2-dev \
        libmemcached-dev \
        libpng-dev \
        libpq-dev \
        libxml2-dev \
        libz-dev \
    && \
    # Install needed php extensions
    #
    debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)" && \
    docker-php-ext-configure gd --with-freetype-dir=/usr --with-png-dir=/usr --with-jpeg-dir=/usr && \
    docker-php-ext-configure ldap --with-libdir="lib/$debMultiarch" && \
    docker-php-ext-install \
        exif \
        gd \
        intl \
        ldap \
        mbstring \
        mysqli \
        opcache \
        pcntl \
        pdo_mysql \
        zip \
    && \
    pecl install \
        apcu-5.1.11 \
        memcached-3.0.4 \
    && \	
    docker-php-ext-enable \
        apcu \
        memcached \
    # Edit permissions of web directories
    #
    && chown www-data:www-data /var/www /var/www/html


# pub   2048R/2F6B6B7F 2016-01-07
#       Key fingerprint = 3B91 9162 5F3B 1F1B F5DD  3B47 673A 0204 2F6B 6B7F
# uid                  Daniel Bachhuber <daniel@handbuilt.co>
# sub   2048R/45F9CDE2 2016-01-07
ENV WORDPRESS_CLI_GPG_KEY 3B9191625F3B1F1BF5DD3B47673A02042F6B6B7F

ENV WORDPRESS_CLI_VERSION 1.5.0
ENV WORDPRESS_CLI_SHA512 9385c63ab835c7c450529035cdb1f524b5878a67c7565c3497628e5ec4ec07ae4a34ef25c59a9e7d6edea7cdb039fcef7a1f731b922782b8c70418480bdff122

WORKDIR /var/www/html

RUN set -ex; \
	\
    # Install wp-cli dependencies
    #
    apt-get install --no-install-recommends -y \
        dirmngr \
		gnupg \
		less \
		mysql-client \
	; \
	\
	curl -o /usr/local/bin/wp.gpg -fSL "https://github.com/wp-cli/wp-cli/releases/download/v${WORDPRESS_CLI_VERSION}/wp-cli-${WORDPRESS_CLI_VERSION}.phar.gpg"; \
	\
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$WORDPRESS_CLI_GPG_KEY"; \
	gpg --batch --decrypt --output /usr/local/bin/wp /usr/local/bin/wp.gpg; \
	rm -rf "$GNUPGHOME" /usr/local/bin/wp.gpg; \
	\
	echo "$WORDPRESS_CLI_SHA512 */usr/local/bin/wp" | sha512sum -c -; \
	chmod +x /usr/local/bin/wp; \
	\
    # Cleanup
    rm -rf /var/lib/apt/lists/* && \
	\
	wp --allow-root --version

# ENTRYPOINT resets CMD
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
