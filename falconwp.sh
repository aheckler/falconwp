#!/bin/bash
#
# A simple shell script for creating local WordPress test sites.
#
# See requirements here: https://github.com/aheckler/falconwp

# Set site name
SITE_NAME=$(sed '/.\{10\}/d' /usr/share/dict/words | shuf -n 3 | tr '\n' '_' | tr [:upper:] [:lower:] | sed 's/.$//')

# Create hyphenated site name for use in URLs, etc.
SITE_NAME_HYPHENATED=$(echo ${SITE_NAME} | tr '_' '-')

# Set WordPress credentials
WORDPRESS_USERNAME="wordpress"
WORDPRESS_PASSWORD=$(head /dev/urandom | LC_ALL=C tr -cd a-zA-Z0-9 | cut -c1-20)

# Set database credentials
MARIADB_USERNAME=${SITE_NAME}
MARIADB_PASSWORD=$(head /dev/urandom | LC_ALL=C tr -cd a-zA-Z0-9 | cut -c1-20)

# Valet settings
VALET_DOMAIN=$(cat ~/.config/valet/config.json | jq -r '.tld')
VALET_DIRECTORY=$(cat ~/.config/valet/config.json | jq -r '.paths[0]')

# Formatting variables
BOLD_START=$(tput bold)
BOLD_STOP=$(tput sgr0)

# Output a new message, section, or error
function output_new() {
  if [[ "message" == ${1} ]]; then
    if [[ ! ${2} -ne 0 ]]; then
      echo "    ${3}"
    else
      echo "ERROR!"
      exit 1;
    fi
  elif [[ "section" == ${1} ]]; then
    if [[ ! ${2} -ne 0 ]]; then
      echo "==> ${BOLD_START}${3}${BOLD_STOP}"
    else
      echo "ERROR!"
      exit 1;
    fi
  else
    echo "ERROR!"
    exit 1;
  fi
}

# Make sure Valet has at least one directory parked
if [[ "null" == $(cat ~/.config/valet/config.json | jq -r '.paths[0]') ]]; then
  echo "ERROR: Please park at least one directory in Valet."
  exit 1;
fi

echo "##############"
echo "#  FalconWP  #"
echo "##############"
echo

sleep 1

##################################
output_new section $? "Preparing MariaDB"
##################################

output_new message $? "MariaDB is running"

mysql.server start &> /dev/null

# Ask for MariaDB root password if not already defined
if [[ -z ${MARIADB_ROOT_PW+x} ]]; then
  read -s -p "    Enter your MariaDB root password: " MARIADB_ROOT_PW
  echo
fi

output_new message $? "Verifying MariaDB credentials"

echo "SHOW DATABASES" | mysql --user=root --password=${MARIADB_ROOT_PW} -NB 2> /dev/null | grep -x "mysql" &> /dev/null

output_new message $? "Checking for existing database"

# Drop database and user if they exist
if [[ ! -z $(echo "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '${SITE_NAME}'" | mysql -N --user=root --password=${MARIADB_ROOT_PW}) ]]; then
  output_new message $? "Dropping database ${SITE_NAME}"
  echo "DROP DATABASE IF EXISTS ${SITE_NAME}" | mysql --user=root --password=${MARIADB_ROOT_PW} &> /dev/null

  output_new message $? "Deleting user ${MARIADB_USERNAME}"
  echo "DROP USER IF EXISTS '${MARIADB_USERNAME}'@'localhost';" | mysql --user=root --password=${MARIADB_ROOT_PW} &> /dev/null

  output_new message $? "Flushing privileges"
  echo "FLUSH PRIVILEGES" | mysql --user=root --password=${MARIADB_ROOT_PW} &> /dev/null
fi

output_new message $? "Creating new database"

echo "CREATE DATABASE ${SITE_NAME}" | mysql --user=root --password=${MARIADB_ROOT_PW} &> /dev/null

output_new message $? "Creating non-root user"

echo "CREATE USER '${MARIADB_USERNAME}'@'localhost' IDENTIFIED BY '${MARIADB_PASSWORD}'" | mysql --user=root --password=$MARIADB_ROOT_PW &> /dev/null

output_new message $? "Granting privileges"

echo "GRANT ALL ON ${SITE_NAME}.* TO '${MARIADB_USERNAME}'@'localhost'" | mysql --user=root --password=${MARIADB_ROOT_PW} &> /dev/null

output_new message $? "Flushing privileges"

echo "FLUSH PRIVILEGES" | mysql --user=root --password=${MARIADB_ROOT_PW} &> /dev/null

#####################################
output_new section $? "Installing WordPress"
#####################################

output_new message $? "Creating site directory"

cd "$VALET_DIRECTORY" &> /dev/null && mkdir ${SITE_NAME_HYPHENATED} &> /dev/null && cd ${SITE_NAME_HYPHENATED} &> /dev/null

output_new message $? "Downloading WordPress"

wp core download &> /dev/null

output_new message $? "Verifying checksums"

wp core verify-checksums &> /dev/null

output_new message $? "Configuring wp-config.php"

# Add constants for logging and debugging
wp core config --dbname=${SITE_NAME} --dbuser=${MARIADB_USERNAME} --dbpass=${MARIADB_PASSWORD} --extra-php &> /dev/null <<PHP
define( 'WP_DEBUG', true );
if ( WP_DEBUG ) {
	@error_reporting( E_ALL );
	@ini_set( 'log_errors', true );
	@ini_set( 'log_errors_max_len', '0' );
	define( 'WP_DEBUG_LOG', true );
	define( 'WP_DEBUG_DISPLAY', false );
	define( 'CONCATENATE_SCRIPTS', false );
	define( 'SAVEQUERIES', true );
}
PHP

output_new message $? "Installing WordPress"

wp core install --url=${SITE_NAME_HYPHENATED}.${VALET_DOMAIN} --title=${SITE_NAME_HYPHENATED} --admin_user=${WORDPRESS_USERNAME} --admin_password=${WORDPRESS_PASSWORD} --admin_email=user@example.com &> /dev/null

output_new message $? "Removing sample content"

wp site empty --yes &> /dev/null

output_new message $? "Opening the site"

# Open in default browser, in background
# Foreground for Chrome due to: https://crbug.com/854609
open -g http://${SITE_NAME_HYPHENATED}.${VALET_DOMAIN}/
open -g http://${SITE_NAME_HYPHENATED}.${VALET_DOMAIN}/wp-admin

#######################################
output_new section $? "WordPress credentials:"
#######################################

# Copy password to clipboard
echo ${WORDPRESS_PASSWORD} | pbcopy

echo
output_new message $? "Username: ${WORDPRESS_USERNAME}"
output_new message $? "Password: ${WORDPRESS_PASSWORD}"
output_new message $? "Password copied to clipboard."
echo

exit 0;
