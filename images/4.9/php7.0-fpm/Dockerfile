FROM wordpress:4.9-php7.0-fpm

LABEL maintainer="mathieu.brunot at monogramm dot io"

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
        soap \
        zip \
    && \
    pecl install \
        apcu-5.1.11 \
        memcached-3.0.4 \
    && \	
    docker-php-ext-enable \
        apcu \
        memcached \
    # Variant extras
    #
     \
    # Edit permissions of web directories
    #
    && chown www-data:www-data /var/www /var/www/html


# https://make.wordpress.org/cli/2018/05/31/gpg-signature-change/
# pub   rsa2048 2018-05-31 [SC]
#       63AF 7AA1 5067 C056 16FD  DD88 A3A2 E8F2 26F0 BC06
# uid           [ unknown] WP-CLI Releases <releases@wp-cli.org>
# sub   rsa2048 2018-05-31 [E]
ENV WORDPRESS_CLI_GPG_KEY 63AF7AA15067C05616FDDD88A3A2E8F226F0BC06

ENV WORDPRESS_CLI_VERSION 2.0.1
ENV WORDPRESS_CLI_SHA512 21b9c1d65993f88bf81cc73c0a832532cc424bea8c15563a77af1905d0dc4714f2af679dfadedd3b683f3968902b4b6be4c6cf94285da9f5582b30c1dac5397f

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
CMD ["php-fpm"]
