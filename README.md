
[uri_license]: http://www.gnu.org/licenses/agpl.html
[uri_license_image]: https://img.shields.io/badge/License-AGPL%20v3-blue.svg

[![License: AGPL v3][uri_license_image]][uri_license]
[![Build Status](https://travis-ci.org/Monogramm/docker-wordpress.svg)](https://travis-ci.org/Monogramm/docker-wordpress)
[![Docker Automated buid](https://img.shields.io/docker/build/monogramm/docker-wordpress.svg)](https://hub.docker.com/r/monogramm/docker-wordpress/)
[![Docker Pulls](https://img.shields.io/docker/pulls/monogramm/docker-wordpress.svg)](https://hub.docker.com/r/monogramm/docker-wordpress/)

# Wordpress on Docker

Docker image for Wordpress.

Provides full database configuration, memcached and LDAP support.

## What is Wordpress ?

WordPress is open source software you can use to create a beautiful website, blog, or app.

> [More informations](https://wordpress.org/)

## Supported tags

https://hub.docker.com/r/monogramm/docker-wordpress/

* Wordpress 4.9
    * `4.9.5-php7.2-apache` `4.9.5-apache` `4.9.5-php7.2` `4.9.5` `4.9-php7.2-apache` `4.9-apache` `4.9-php7.2` `4.9` `4-php7.2-apache` `4-apache` `4-php7.2` `4` `php7.2-apache` `apache` `php7.2` `latest`
    * `4.9.5-php7.2-fpm` `4.9.5-fpm` `4.9-php7.2-fpm` `4.9-fpm` `4-php7.2-fpm` `4-fpm` `php7.2-fpm` `fpm`
    * `4.9.5-php7.1-apache` `4.9.5-php7.1` `4.9-php7.1-apache` `4.9-php7.1` `4-php7.1-apache` `4-php7.1` `php7.1-apache` `php7.1`
    * `4.9.5-php7.1-fpm` `4.9-php7.1-fpm` `4-php7.1-fpm` `php7.1-fpm`
    * `4.9.5-php7.0-apache` `4.9.5-php7.0` `4.9-php7.0-apache` `4.9-php7.0` `4-php7.0-apache` `4-php7.0` `php7.0-apache` `php7.0`
    * `4.9.5-php7.0-fpm` `4.9-php7.0-fpm` `4-php7.0-fpm` `php7.0-fpm`
    * `4.9.5-php5.6-apache` `4.9.5-php5.6` `4.9-php5.6-apache` `4.9-php5.6` `4-php5.6-apache` `4-php5.6` `php5.6-apache` `php5.6`
    * `4.9.5-php5.6-fpm` `4.9-php5.6-fpm` `4-php5.6-fpm` `php5.6-fpm`

## How to run this image ?

This Docker image adds LDAP and Memcached PHP Extension to [official Wordpress image](https://hub.docker.com/_/wordpress/) for WordPress plugins.
It is inspired from [fjudith/docker-wordpress](https://github.com/fjudith/docker-wordpress) image but also provides Apache variant.

This image does not contain the database for Wordpress. You need to use either an existing database or a database container.

This image is designed to be used in a micro-service environment. There are two versions of the image you can choose from.

The `apache` tag contains a full Wordpress installation including an apache web server. It is designed to be easy to use and gets you running pretty fast. This is also the default for the `latest` tag and version tags that are not further specified.

The second option is a `fpm` container. It is based on the [php-fpm](https://hub.docker.com/_/php/) image and runs a fastCGI-Process that serves your Wordpress page. To use this image it must be combined with any webserver that can proxy the http requests to the FastCGI-port of the container.

## Using the apache image
The apache image contains a webserver and exposes port 80. To start the container type:

```console
$ docker run -d -p 8080:80 monogramm/docker-wordpress
```

Now you can access Wordpress at http://localhost:8080/ from your host system.


## Using the fpm image
To use the fpm image you need an additional web server that can proxy http-request to the fpm-port of the container. For fpm connection this container exposes port 9000. In most cases you might want use another container or your host as proxy.
If you use your host you can address your Wordpress container directly on port 9000. If you use another container, make sure that you add them to the same docker network (via `docker run --network <NAME> ...` or a `docker-compose` file).
In both cases you don't want to map the fpm port to you host. 

```console
$ docker run -d monogramm/docker-wordpress:fpm
```

As the fastCGI-Process is not capable of serving static files (style sheets, images, ...) the webserver needs access to these files. This can be achieved with the `volumes-from` option. You can find more information in the docker-compose section.

## Using an external database
By default this container does not contain the database for Wordpress. You need to use either an existing database or a database container.

The Wordpress setup wizard (should appear on first run) allows connecting to an existing MySQL/MariaDB. You can also link a database container, e. g. `--link my-mysql:mysql`, and then use `mysql` as the database host on setup. More info is in the docker-compose section.

## Persistent data
The Wordpress installation and all data beyond what lives in the database (file uploads, etc) are stored in the [unnamed docker volume](https://docs.docker.com/engine/tutorials/dockervolumes/#adding-a-data-volume) volume `/var/www/html`. The docker daemon will store that data within the docker directory `/var/lib/docker/volumes/...`. That means your data is saved even if the container crashes, is stopped or deleted.

To make your data persistent to upgrading and get access for backups is using named docker volume or mount a host folder. To achieve this you need one volume for your database container and Wordpress.

Wordpress:
- `/var/www/html/` folder where all Wordpress data lives
```console
$ docker run -d \
    -v wordpress_html:/var/www/html \
    monogramm/docker-wordpress
```

Database:
- `/var/lib/mysql` MySQL / MariaDB Data
```console
$ docker run -d \
    -v db:/var/lib/mysql \
    mariadb
```

## Auto configuration via environment variables

The following environment variables are also honored for configuring your WordPress instance:

-	`-e WORDPRESS_DB_HOST=...` (defaults to the IP and port of the linked `mysql` container)
-	`-e WORDPRESS_DB_USER=...` (defaults to "root")
-	`-e WORDPRESS_DB_PASSWORD=...` (defaults to the value of the `MYSQL_ROOT_PASSWORD` environment variable from the linked `mysql` container)
-	`-e WORDPRESS_DB_NAME=...` (defaults to "wordpress")
-	`-e WORDPRESS_TABLE_PREFIX=...` (defaults to "", only set this when you need to override the default table prefix in wp-config.php)
-	`-e WORDPRESS_AUTH_KEY=...`, `-e WORDPRESS_SECURE_AUTH_KEY=...`, `-e WORDPRESS_LOGGED_IN_KEY=...`, `-e WORDPRESS_NONCE_KEY=...`, `-e WORDPRESS_AUTH_SALT=...`, `-e WORDPRESS_SECURE_AUTH_SALT=...`, `-e WORDPRESS_LOGGED_IN_SALT=...`, `-e WORDPRESS_NONCE_SALT=...` (default to unique random SHA1s)

If the `WORDPRESS_DB_NAME` specified does not already exist on the given MySQL server, it will be created automatically upon startup of the `wordpress` container, provided that the `WORDPRESS_DB_USER` specified has the necessary permissions to create it.

# Running this image with docker-compose

## Base version - apache with MariaDB/MySQL

This version will use the apache image and add a [MariaDB](https://hub.docker.com/_/mariadb/) container (you can also use [MySQL](https://hub.docker.com/_/mysql/) if you prefer). The volumes are set to keep your data persistent. This setup provides **no ssl encryption** and is intended to run behind a proxy. 

Make sure to set the variables `MYSQL_ROOT_PASSWORD`, `MYSQL_PASSWORD`, `DOLI_DB_PASSWORD` and `DOLI_DB_ROOT_PASSWORD` before you run this setup.

Create `docker-compose.yml` file as following:

```yml
version: '2'

volumes:
  wordpress_html:
  wordpress_db:

mariadb:
    image: mariadb:latest
    restart: always
    volumes:
        - wordpress_db:/var/lib/mysql
    environment:
        - "MYSQL_ROOT_PASSWORD="
        - "MYSQL_PASSWORD="
        - "MYSQL_DATABASE=wordpress"
        - "MYSQL_USER=wordpress"

wordpress:
    image: monogramm/docker-wordpress
    restart: always
    depends_on:
        - mariadb
    ports:
        - "8080:80"
    environment:
        - "WORDPRESS_DB_HOST=mariadb"
        - "WORDPRESS_DB_NAME=wordpress"
        - "WORDPRESS_DB_USER=wordpress"
        - "WORDPRESS_DB_PASSWORD="
    volumes:
        - wordpress_html:/var/www/html
```

Then run all services `docker-compose up -d`. Now, go to http://localhost:8080 to access the new Wordpress installation wizard.

## Base version - FPM with MemCached
When using the FPM image you need another container that acts as web server on port 80 and proxies the requests to the Wordpress container.
In this example a simple nginx container is combined with the `monogramm/docker-wordpress:fpm` image. The data is stored in docker volumes. The nginx container also need access to static files from your Wordpress installation. It gets access to all the volumes mounted to Wordpress via the `volumes_from` option. The configuration for nginx is stored in the configuration file `nginx.conf`, that is mounted into the container.

As this setup does **not include encryption** it should to be run behind a proxy. 

Make sure to set the variables `POSTGRES_PASSWORD` and `DOLI_DB_PASSWORD` before you run this setup.

Create `docker-compose.yml` file as following:

```yml
version: '2'

volumes:
  wordpress_html:
  wordpress_db:

memcached:
    image: memcached

mariadb:
    image: mariadb:latest
    restart: always
    volumes:
        - wordpress_db:/var/lib/mysql
    environment:
        - "MYSQL_ROOT_PASSWORD="
        - "MYSQL_PASSWORD="
        - "MYSQL_DATABASE=wordpress"
        - "MYSQL_USER=wordpress"

wordpress:
    image: monogramm/docker-wordpress:fpm
    depends_on:
        - mariadb
    ports:
        - "80:80"
    environment:
        - "WORDPRESS_DB_HOST=mariadb"
        - "WORDPRESS_DB_NAME=wordpress"
        - "WORDPRESS_DB_USER=wordpress"
        - "WORDPRESS_DB_PASSWORD="
    volumes:
        - wordpress_html:/var/www/html

web:
    image: nginx
    ports:
        - 8080:80
    links:
        - wordpress
    volumes:
        - ./nginx.conf:/etc/nginx/nginx.conf:ro
    volumes_from:
        - wordpress
    restart: always
```

In order for this work, you must provide a valid NGinx config. Take a look at [fjudith/docker-wordpress](https://github.com/fjudith/docker-wordpress) to get some sample configuration.

Then run all services `docker-compose up -d`. Now, go to http://localhost:8080 to access the new Wordpress installation wizard.


# Make your Wordpress available from the internet
Until here your Wordpress is just available from you docker host. If you want you Wordpress available from the internet adding SSL encryption is mandatory.

## HTTPS - SSL encryption
There are many different possibilities to introduce encryption depending on your setup. 

We recommend using a reverse proxy in front of our Wordpress installation. Your Wordpress will only be reachable through the proxy, which encrypts all traffic to the clients. You can mount your manually generated certificates to the proxy or use a fully automated solution, which generates and renews the certificates for you.

## Enable Object Caching

Once the initial site configuration performed, navigate to `Plugins`, activate `WP-FFPC` and click `Settings`.
Set the following minimal configuration options:

* **Cache Type/Select Backend**: PHP Memcached
* **Backend Settings/Hosts**: memcached:11211
* **Backend Settings/Authentication: username**: _Empty_
* **Backend Settings/Authentication: password**: _Empty_
* **Backend Settings/Enable memcached binary mode**: **Activated**


# Update to a newer version
Because the `docker-compose` levegare persistent volume in the Wordpress root directory, its required to open a session in a `cli` container in order to run the command `wp core update`.

### Interactive

Open a terminal session in the `cli` container.

```bash
WP_HTML=
docker run --rm -it \
  -v "$WP_HTML":/var/www/html \
  -ti wordpress:cli bash
``` 

Run the following commands to update the application engine, the plugins and themes.

```bash
wp core update
wp plugins update --all
wp theme update --all
```

### Non-interactive

Run the following commands

```bash
WP_HTML=
docker run --rm \
  -v "$WP_HTML":/tmp/docker-mailserver \
  -ti wordpress:cli bash -c 'wp core update && wp plugins update --all && wp theme update --all'
```


# Adding Features
If the image does not include the packages you need, you can easily build your own image on top of it.
Start your derived image with the `FROM` statement and add whatever you like.

```yaml
FROM monogramm/docker-wordpress:apache

RUN ...

```

You can also clone this repository and use the [update.sh](update.sh) shell script to generate a new Dockerfile based on your own needs.

For instance, you could build a container based on Wordpress develop branch by setting the `update.sh` versions like this:
```bash
versions=( "master" )
```
Then simply call [update.sh](update.sh) script.

```console
bash update.sh
```
Your Dockerfile(s) will be generated in the `images/master` folder.

If you use your own Dockerfile you need to configure your docker-compose file accordingly. Switch out the `image` option with `build`. You have to specify the path to your Dockerfile. (in the example it's in the same directory next to the docker-compose file)

```yaml
  app:
    build: .
    links:
      - db
    restart: always
```

**Updating** your own derived image is also very simple. When a new version of the Wordpress image is available run:

```console
docker build -t your-name --pull . 
docker run -d your-name
```

or for docker-compose:
```console
docker-compose build --pull
docker-compose up -d
```

The `--pull` option tells docker to look for new versions of the base image. Then the build instructions inside your `Dockerfile` are run on top of the new image.

# Questions / Issues
If you got any questions or problems using the image, please visit our [Github Repository](https://github.com/Monogramm/docker-wordpress) and write an issue.  
