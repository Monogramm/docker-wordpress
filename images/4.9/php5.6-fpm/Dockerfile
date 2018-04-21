FROM wordpress:4.9-php5.6-fpm

LABEL maintainer="mb.mathieu.brunot@gmail.com"

RUN apt-get update && \
    apt-get install --no-install-recommends -y tidy csstidy  && \
    mkdir -p /usr/src/php/ext && \
    # Install needed php extensions: memcached
    #
    apt-get install -y libmemcached-dev && \
    pecl install \
        APCu-5.1.11 \
        memcached-3.0.4 \
    ; \	
    docker-php-ext-enable \
        apcu \
        memcached \
    ; \
    # Install needed php extensions: zip
    #
    apt-get install -y libz-dev && \
    curl -o zip.tgz -SL http://pecl.php.net/get/zip-1.15.1.tgz && \
        tar -xf zip.tgz -C /usr/src/php/ext/ && \
        rm zip.tgz && \
        mv /usr/src/php/ext/zip-1.15.1 /usr/src/php/ext/zip && \
    docker-php-ext-install zip && \
    # Install needed php extensions: ldap
    #
    apt-get install libldap2-dev -y && \
	debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)" && \
	docker-php-ext-configure ldap --with-libdir="lib/$debMultiarch" && \
    docker-php-ext-install ldap && \
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
CMD ["php-fpm"]
