FROM wordpress:4.9-php5.6-apache

LABEL maintainer="mb.mathieu.brunot@gmail.com"

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
		bzip2 \
		csstidy \
		tidy \
		unzip \
		zip \
	&& \
    mkdir -p /usr/src/php/ext && \
    # Install needed php extensions
    #
    apt-get install -y \
        libcurl4-openssl-dev \
        libfreetype6-dev \
        libicu-dev \
        libjpeg-dev \
        libldap2-dev \
        libmcrypt-dev \
        libmemcached-dev \
        libpng12-dev \
        libpq-dev \
        libxml2-dev \
        libz-dev \
    && \
    debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)" && \
    docker-php-ext-configure gd --with-freetype-dir=/usr --with-png-dir=/usr --with-jpeg-dir=/usr && \
    docker-php-ext-configure ldap --with-libdir="lib/$debMultiarch" && \
    docker-php-ext-install \
        exif \
        gd \
        intl \
        ldap \
        mbstring \
        mcrypt \
        mysqli \
        opcache \
        pcntl \
        pdo_mysql \
        zip \
    && \
    pecl install \
        APCu-5.1.11 \
        memcached-3.0.4 \
    ; \	
    docker-php-ext-enable \
        apcu \
        memcached \
    ; \
    # Install needed wordpress extensions: WP-FFPC
    #
    cd /usr/src/wordpress/wp-content/plugins && \
    curl -o wp-ffpc.zip -L https://downloads.wordpress.org/plugin/wp-ffpc.zip && \
        unzip -o wp-ffpc.zip && \
        chown -R www-data:www-data wp-ffpc && \
        rm -f wp-ffpc.zip && \
    # Enable Wordpress Caching
    cd /usr/src/wordpress && ls -l && \
    sed -ri -e "s#(<\?php)#\\1\ndefine('WP_CACHE', 'true');#g" wp-config-sample.php && \
    # Install needed wordpress extensions: Simple-Ldap-Login
    #
    cd /usr/src/wordpress/wp-content/plugins && \
    curl -o simple-ldap-login.zip -L https://downloads.wordpress.org/plugin/simple-ldap-login.1.6.0.zip && \
        unzip -o simple-ldap-login.zip && \
        chown -R www-data:www-data simple-ldap-login && \
        rm -f simple-ldap-login.zip && \
    # Cleanup
    rm -rf /var/lib/apt/lists/*


# ENTRYPOINT resets CMD
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
