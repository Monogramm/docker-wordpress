#!/bin/bash
set -eo pipefail

declare -A cmd=(
	[apache]='apache2-foreground'
	[fpm]='php-fpm'
)

declare -A base=(
	[apache]='debian'
	[fpm]='debian'
)

declare -A pecl_versions=(
	[APCu]='5.1.11'
	[memcached]='3.0.4'
)

variants=(
	apache
	fpm
)

min_version='4.8'


# version_greater_or_equal A B returns whether A >= B
function version_greater_or_equal() {
	[[ "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1" || "$1" == "$2" ]];
}

php_versions=( "5.6" "7.0" "7.1" "7.2" )

dockerRepo="monogramm/docker-wordpress"
# Retrieve automatically the latest versions
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

	if [ -d "$version" ]; then
		continue
	fi

	# Only add versions >= "$min_version"
	if version_greater_or_equal "$version" "$min_version"; then

		for php_version in "${php_versions[@]}"; do

			for variant in "${variants[@]}"; do
				echo "updating $latest [$version] php$php_version-$variant"

				# Create the version+php_version+variant directory with a Dockerfile.
				dir="images/$version/php$php_version-$variant"
				mkdir -p "$dir"

				template="Dockerfile-${base[$variant]}.template"
				cp "$template" "$dir/Dockerfile"

				# Replace the variables.
				sed -ri -e '
					s/%%PHP_VERSION%%/'"$php_version"'/g;
					s/%%VARIANT%%/'"$variant"'/g;
					s/%%VERSION%%/'"$latest"'/g;
					s/%%CMD%%/'"${cmd[$variant]}"'/g;
					s/%%APCU_VERSION%%/'"${pecl_versions[APCu]}"'/g;
					s/%%MEMCACHED_VERSION%%/'"${pecl_versions[memcached]}"'/g;
				' "$dir/Dockerfile"

				travisEnv='\n    - VERSION='"$version"' PHP_VERSION='"$php_version"' VARIANT='"$variant$travisEnv"

				if [[ $1 == 'build' ]]; then
					tag="$version-$php_version-$variant"
					echo "Build Dockerfile for ${tag}"
					docker build -t ${dockerRepo}:${tag} $dir
				fi
			done

		done
	fi

done

# update .travis.yml
travis="$(awk -v 'RS=\n\n' '$1 == "env:" && $2 == "#" && $3 == "Environments" { $0 = "env: # Environments'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
