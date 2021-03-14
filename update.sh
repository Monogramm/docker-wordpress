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


declare -A conf=(
	[apache]=''
	[fpm]='nginx'
	[fpm-alpine]='nginx'
)

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
	[apache]='a2enmod headers remoteip ;\\\n    {\\\n      echo RemoteIPHeader X-Real-IP ;\\\n      echo RemoteIPTrustedProxy 10.0.0.0/8 ;\\\n      echo RemoteIPTrustedProxy 172.16.0.0/12 ;\\\n      echo RemoteIPTrustedProxy 192.168.0.0/16 ;\\\n    } > /etc/apache2/conf-available/remoteip.conf;\\\n    a2enconf remoteip;'
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

min_version='5.4'
dockerLatest='5.6'


# version_greater_or_equal A B returns whether A >= B
function version_greater_or_equal() {
	[[ "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1" || "$1" == "$2" ]];
}

php_versions=( "7.4" )

dockerRepo="monogramm/docker-wordpress"
echo "retrieve automatically the latest versions..."
latests=( $( curl -fsSL 'https://api.github.com/repos/WordPress/WordPress/tags' |tac|tac| \
	grep -oE '[[:digit:]]+\.[[:digit:]]+' | \
	sort -urV ) )

# Remove existing images
echo "reset docker images"
rm -rf ./images/*

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
				cp "template/$template" "$dir/Dockerfile"

				cp -r "template/hooks/" "$dir/"
				cp -r "template/test/" "$dir/"
				cp "template/.env" "$dir/.env"
				cp "template/.dockerignore" "$dir/.dockerignore"
				cp "template/docker-compose.${compose[$variant]}.test.yml" "$dir/docker-compose.test.yml"

				if [ -n "${conf[$variant]}" ] && [ -d "template/${conf[$variant]}" ]; then
					cp -r "template/${conf[$variant]}" "$dir/${conf[$variant]}"
				fi

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

				sed -ri -e '
					s|DOCKER_TAG=.*|DOCKER_TAG='"$version"'|g;
					s|DOCKER_REPO=.*|DOCKER_REPO='"$dockerRepo"'|g;
				' "$dir/hooks/run"

				# Create a list of "alias" tags for DockerHub post_push
				if [ "$latest" = "$dockerLatest" ]; then
					if [ "$variant" = 'apache' ]; then
						echo "$latest-$variant $variant $latest latest " > "$dir/.dockertags"
					else
						echo "$latest-$variant $variant " > "$dir/.dockertags"
					fi
				else
					if [ "$variant" = 'apache' ]; then
						echo "$latest-$variant $version-$variant $latest $version " > "$dir/.dockertags"
					else
						echo "$latest-$variant $version-$variant " > "$dir/.dockertags"
					fi
				fi

				# Add Travis-CI env var
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
