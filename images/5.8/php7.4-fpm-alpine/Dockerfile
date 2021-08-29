FROM wordpress:5.8-php7.4-fpm-alpine

LABEL maintainer="Monogramm maintainers <opensource at monogramm dot io>"

# Install needed libraries
# Install needed php extensions
# Variant extras
# Edit permissions of web directories
RUN set -ex; \
	\
	apk add --no-cache --update \
		bash \
		bzip2 \
		less \
		libldap \
		memcached \
		mysql-client \
		oniguruma-dev \
		unzip \
		zip \
	; \
	mkdir -p /usr/src/php/ext; \
	apk add --no-cache --virtual .build-deps \
		$PHPIZE_DEPS \
		curl-dev \
		freetype-dev \
		icu-dev \
		jpeg-dev \
		memcached-dev \
		libmemcached-dev \
		openldap-dev \
		libpng-dev \
		libpq \
		libxml2-dev \
		libzip-dev \
	; \
	docker-php-ext-configure gd; \
	docker-php-ext-configure ldap; \
	docker-php-ext-install -j "$(nproc)" \
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
	; \
	pecl install \
		apcu-5.1.18 \
		memcached-3.1.5 \
	; \
	docker-php-ext-enable \
		apcu \
		memcached \
	 \
	&& chown www-data:www-data /var/www /var/www/html; \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --virtual .wordpress-phpexts-rundeps $runDeps; \
	apk del .build-deps


# https://make.wordpress.org/cli/2018/05/31/gpg-signature-change/
# pub   rsa2048 2018-05-31 [SC]
#	   63AF 7AA1 5067 C056 16FD  DD88 A3A2 E8F2 26F0 BC06
# uid		   [ unknown] WP-CLI Releases <releases@wp-cli.org>
# sub   rsa2048 2018-05-31 [E]
ENV WORDPRESS_CLI_GPG_KEY 63AF7AA15067C05616FDDD88A3A2E8F226F0BC06

ARG WORDPRESS_CLI_VERSION=2.4.0
ARG WORDPRESS_CLI_SHA512=4049c7e45e14276a70a41c3b0864be7a6a8cfa8ea65ebac8b184a4f503a91baa1a0d29260d03248bc74aef70729824330fb6b396336172a624332e16f64e37ef

WORKDIR /var/www/html

# Install wp-cli dependencies
# Cleanup
RUN set -ex; \
	\
	apk add --no-cache --virtual .fetch-deps \
		gnupg \
	; \
	\
	curl -o /usr/local/bin/wp.gpg -fSL "https://github.com/wp-cli/wp-cli/releases/download/v${WORDPRESS_CLI_VERSION}/wp-cli-${WORDPRESS_CLI_VERSION}.phar.gpg"; \
	\
	export GNUPGHOME="$(mktemp -d)"; \
	for server in $(shuf -e ha.pool.sks-keyservers.net \
							hkp://p80.pool.sks-keyservers.net:80 \
							keyserver.ubuntu.com \
							hkp://keyserver.ubuntu.com:80 \
							pgp.mit.edu) ; do \
		gpg --keyserver "$server" --recv-keys "$WORDPRESS_CLI_GPG_KEY" && break || : ; \
	done; \
	gpg --batch --decrypt --output /usr/local/bin/wp /usr/local/bin/wp.gpg; \
	rm -rf "$GNUPGHOME" /usr/local/bin/wp.gpg; \
	\
	echo "$WORDPRESS_CLI_SHA512 */usr/local/bin/wp" | sha512sum -c -; \
	chmod +x /usr/local/bin/wp; \
	\
	apk del .fetch-deps; \
	\
	wp --allow-root --version

# ENTRYPOINT resets CMD
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]
