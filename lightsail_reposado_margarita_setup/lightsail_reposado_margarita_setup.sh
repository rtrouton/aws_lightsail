#!/bin/bash

# Original script by Owen Pragel
# https://github.com/opragel/reposado_margarita_apache_install

# This script is designed to set up the following software on Ubuntu:
#
# Reposado: https://github.com/wdas/reposado
# Margarita: https://github.com/jessepeterson/margarita
# 
# Script has been tested and verified to work on Ubuntu 16.04 LTS
#
# As part of its run, it performs the following actions:
#
# 1. Installs the following software:
#
#  Apache (apache2)
#  Apache utility programs (apache2-utils)
#  Python WSGI adapter module for Apache (libapache2-mod-wsgi)
#  Python3 
#  Python enhancements (python-setuptools)
#  pip (python3-pip)
#  curl
#  flask
#
# 2. Creates the directories for storing Reposado and Margarita, as well as Reposado catalogs and packages.
#
# 3. Downloads and installs Reposado and Margarita
#
# 4. Configures Reposado
#
# 5. Installs script to automatically start Margarita when Apache starts.
#
# 6. Configures Apache to work with Reposado and Margarita
#
# 7. Sets a password for the Margarita web interface.
# 
# 8. Sets the correct permissions for Apache to have access to the Reposado catalogs and packages
#
# 9. Restarts Apache
#
# 10. Runs the initial Reposado software sync

# User-chosen variables

# Change the password below. Used to access Margarita web interface.
MARGARITA_USERNAME="susadmin"
MARGARITA_PASSWORD="apple123"

# There should not be a need to change variables below this line.

# Update apt

apt update

# install Reposado and Margarita dependecies
apt-get -y install apache2-utils libapache2-mod-wsgi git python-setuptools python3 curl python3-pip apache2

# Install Python's flask

easy_install flask



# make directories for storing reposado + margarita as well as catalogs and packages

mkdir -p /usr/local/sus 
mkdir -p /usr/local/sus/www
mkdir -p /usr/local/sus/meta

# download reposado and margarita
git clone https://github.com/wdas/reposado.git /usr/local/sus/reposado
git clone https://github.com/jessepeterson/margarita.git /usr/local/sus/margarita

# Write reposado config file
echo '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
        <key>LocalCatalogURLBase</key>
        <string></string>
        <key>UpdatesMetadataDir</key>
        <string>/usr/local/sus/meta</string>
        <key>UpdatesRootDir</key>
        <string>/usr/local/sus/www</string>
</dict>
</plist>' > /usr/local/sus/reposado/code/preferences.plist

# Link reposado data so margarita can access it
ln -s /usr/local/sus/reposado/code/reposadolib /usr/local/sus/margarita/reposadolib
ln -s /usr/local/sus/reposado/code/preferences.plist /usr/local/sus/margarita/preferences.plist

# Write wsgi script for auto-starting margarita with apache
echo 'import sys
EXTRA_DIR = "/usr/local/sus/margarita"
if EXTRA_DIR not in sys.path:
    sys.path.append(EXTRA_DIR)
 
from margarita import app as application' > /usr/local/sus/margarita/margarita.wsgi

# Write apache sites configuration
echo '# /etc/apache2/sites-enabled/000-default.conf

# SUS/Reposado at 8080
Listen 8080
# Margarita at 8086
Listen 8086' > /etc/apache2/ports.conf

echo '<VirtualHost *:8080>
    ServerAdmin webmaster@localhost
    DocumentRoot /usr/local/sus/www

    Alias /content /usr/local/sus/www/content
    <Directory />
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Require all granted
    </Directory>

    # Logging
    ErrorLog ${APACHE_LOG_DIR}/sus-error.log
    LogLevel warn
    CustomLog ${APACHE_LOG_DIR}/sus-access.log combined
</VirtualHost>' > /etc/apache2/sites-enabled/reposado.conf

echo '<VirtualHost *:8086>
    ServerAdmin webmaster@localhost
    DocumentRoot /usr/local/sus/www
 
    # Base cofiguration
    <Directory />
        Options FollowSymLinks
        AllowOverride None
    </Directory>
 
    # Margarita
    Alias /static /usr/local/sus/margarita/static
    WSGIDaemonProcess margarita home=/usr/local/sus/margarita user=www-data group=www-data threads=5
    WSGIScriptAlias / /usr/local/sus/margarita/margarita.wsgi
    <Directory />
        WSGIProcessGroup margarita
        WSGIApplicationGroup %{GLOBAL}
        AuthType Basic
        AuthName "Margarita (SUS Configurator)"
        AuthUserFile /usr/local/sus/margarita/.htpasswd
        Require valid-user
    </Directory>
 
    # Logging
    ErrorLog ${APACHE_LOG_DIR}/sus-error.log
    LogLevel warn
    CustomLog ${APACHE_LOG_DIR}/sus-access.log combined
</VirtualHost>' > /etc/apache2/sites-enabled/margarita.conf

htpasswd -cb /usr/local/sus/margarita/.htpasswd "$MARGARITA_USERNAME" "$MARGARITA_PASSWORD"

# correct folder permissions
chown -R www-data:www-data /usr/local/sus
chmod -R g+r /usr/local/sus

apache2ctl graceful

# Kickoff reposado SUS sync
/usr/local/sus/reposado/code/./repo_sync
