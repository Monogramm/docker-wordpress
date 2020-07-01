#!/bin/bash
set -eo pipefail

# XXX No phar asset on 2.4.1
#cliVersion="$(
#	git ls-remote --tags 'https://github.com/wp-cli/wp-cli.git' \
#		| sed -r 's!^[^\t]+\trefs/tags/v([^^]+).*!\1!g' \
#		| tail -1
#)"
cliVersion=2.4.0
cliSha512="$(curl -fsSL "https://github.com/wp-cli/wp-cli/releases/download/v${cliVersion}/wp-cli-${cliVersion}.phar.sha512")"


declare -A compose=(
	[apache]='apache'
	[fpm]='fpm'
	[fpm-alpine]='fpm'
)

declare -A cmd=(
	[apache]='apache2-foreground'
	[fpm]='php-fpm'
	[fpm-alpine]='php-fpm'
)

declare -A base=(
	[apache]='debian'
	[fpm]='debian'
	[fpm-alpine]='alpine'
)

declare -A extras=(
	[apache]='\&\& a2enmod headers remoteip ;\\\n    {\\\n      echo RemoteIPHeader X-Real-IP ;\\\n      echo RemoteIPTrustedProxy 10.0.0.0/8 ;\\\n      echo RemoteIPTrustedProxy 172.16.0.0/12 ;\\\n      echo RemoteIPTrustedProxy 192.168.0.0/16 ;\\\n    } > /etc/apache2/conf-available/remoteip.conf;\\\n    a2enconf remoteip'
	[fpm]=''
	[fpm-alpine]=''
)

# https://pecl.php.net/package/APCu
# https://pecl.php.net/package/memcached
declare -A pecl_versions=(
	[APCu]='5.1.18'
	[memcached]='3.1.5'
)

variants=(
	apache
	fpm
	fpm-alpine
)

min_version='5.0'


# version_greater_or_equal A B returns whether A >= B
function version_greater_or_equal() {
	[[ "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1" || "$1" == "$2" ]];
}

php_versions=( "7.2" "7.3" )

dockerRepo="monogramm/docker-wordpress"
echo "retrieve automatically the latest versions..."
latests=( $( curl -fsSL 'https://api.github.com/repos/WordPress/WordPress/tags' |tac|tac| \
	grep -oE '[[:digit:]]+\.[[:digit:]]+' | \
	sort -urV ) )

# Remove existing images
echo "reset docker images"
find ./images -maxdepth 1 -type d -regextype sed -regex '\./images/[[:digit:]]\+\.[[:digit:]]\+' -exec rm -r '{}' \;

echo "update docker images"
travisEnv=
for latest in "${latests[@]}"; do
	version=$(echo "$latest" | cut -d. -f1-2)

	# Only add versions >= "$min_version"
	if version_greater_or_equal "$version" "$min_version"; then

		for php_version in "${php_versions[@]}"; do

			for variant in "${variants[@]}"; do
				echo "updating $latest [$version] php$php_version-$variant"

				# Create the version+php_version+variant directory with a Dockerfile.
				dir="images/$version/php$php_version-$variant"
				if [ -d "$dir" ]; then
					continue
				fi
				mkdir -p "$dir"

				template="Dockerfile.${base[$variant]}.template"
				cp "$template" "$dir/Dockerfile"

				cp ".dockerignore" "$dir/.dockerignore"
				cp "docker-compose_${compose[$variant]}.yml" "$dir/docker-compose.yml"

				# Replace the variables.
				sed -ri -e '
					s/%%PHP_VERSION%%/'"$php_version"'/g;
					s/%%VARIANT%%/'"$variant"'/g;
					s/%%VERSION%%/'"$latest"'/g;
					s/%%CMD%%/'"${cmd[$variant]}"'/g;
					s|%%VARIANT_EXTRAS%%|'"${extras[$variant]}"'|g;
					s/%%APCU_VERSION%%/'"${pecl_versions[APCu]}"'/g;
					s/%%MEMCACHED_VERSION%%/'"${pecl_versions[memcached]}"'/g;
					s/%%WORDPRESS_CLI_VERSION%%/'"${cliVersion}"'/g;
					s/%%WORDPRESS_CLI_SHA512%%/'"${cliSha512}"'/g;
				' "$dir/Dockerfile"

				travisEnv='\n    - VERSION='"$version"' PHP_VERSION='"$php_version"' VARIANT='"$variant$travisEnv"

				if [[ $1 == 'build' ]]; then
					tag="$version-$php_version-$variant"
					echo "Build Dockerfile for ${tag}"
					docker build -t "${dockerRepo}:${tag}" "$dir"
				fi
			done

		done
	fi

done

# update .travis.yml
travis="$(awk -v 'RS=\n\n' '$1 == "env:" && $2 == "#" && $3 == "Environments" { $0 = "env: # Environments'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
