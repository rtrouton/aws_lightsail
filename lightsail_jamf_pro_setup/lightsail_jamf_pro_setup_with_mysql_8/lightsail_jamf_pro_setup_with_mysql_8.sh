#!/bin/bash

# This script is designed to set up a new Jamf Pro server on Ubuntu.
# 
# Script has been tested and verified to work on Ubuntu 22.04.3 LTS
#
# As part of its run, it performs the following actions:
#
# 1. Installs the following software:
#
#  OpenJDK 11
#  nano
#  wget
#  zip
#  unzip
#  xmlstarlet
#  MySQL 8.x
#
# 2. Configures MySQL 8.x with a specified root password.
#
# 3. Sets up a new MySQL database for Jamf Pro with a specified
#    database name, username and password.
#
# 4. Downloads the Jamf Pro installer for Linux as a .zip file from a specified URL.
#
# 5. Unzips the Jamf Pro installer.
#
# 6. Installs Jamf Pro.
#
# 7. Stops Jamf Pro
# 
# 8. Configures Jamf Pro to work with the newly-created MySQL database.
#
# 9. Restarts Jamf Pro

# User-chosen variables

# The password for the MySQL root user
		
mysqlpassword="ChangeThis1Password!"

# The database name for the Jamf Pro database 

jamfpro_database_dbname="jamfsoftware"

# The username for the Jamf Pro database

jamfpro_database_username="jamfsoftware"

# The password for the Jamf Pro database user account

jamfpro_database_password="Change-This-2-Please"

# The download URL for the Jamf Pro installer for Linux

jamfpro_download_url="https://download.server.address.here"

# The filename of the Jamf Pro installer for Linux
# Note: This must be a .zip file.

jamfpro_download_filename="latest_jamfpro_installer.zip"

# The variables below this line should not need to be changed:

mysqlserveraddress="localhost"
mysqlserverport=3306
mysqluser="root"

# Remove the trailing slash from the Jamf Pro download URL if needed.

jamfpro_download_url=${jamfpro_download_url%%/}

# Run all updates

apt-get update -y

# Install OpenJDK and other needed utilities

apt-get install -y openjdk-11-jdk nano wget zip unzip xmlstarlet

# Add the appropriate apt repo for MySQL 8.x

echo "Adding MySQL apt repo to system"
wget https://dev.mysql.com/get/mysql-apt-config_0.8.28-1_all.deb
DEBIAN_FRONTEND=noninteractive dpkg -i mysql-apt-config_0.8.28-1_all.deb
apt-get update -q
rm mysql-apt-config_0.8.28-1_all.deb

# Install and configure MySQL

echo "Installing MySQL Server 8.x"

echo "mysql-community-server mysql-community-server/root-pass password $mysqlpassword" | debconf-set-selections
echo "mysql-community-server mysql-community-server/re-root-pass password $mysqlpassword" | debconf-set-selections
echo "mysql-community-server mysql-server/default-auth-override select Use Legacy Authentication Method (Retain MySQL 5.x Compatibility)" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server

echo "Enabling MySQL to start on system restart"
systemctl enable mysql

echo "Starting MySQL 8.x"
systemctl start mysql

# Create Jamf Pro database

echo "Creating new database for instance: $jamfpro_database_dbname "
mysql -h$mysqlserveraddress -u$mysqluser -p$mysqlpassword -e "CREATE DATABASE $jamfpro_database_dbname;" 2>/dev/null
mysql -h$mysqlserveraddress -u$mysqluser -p$mysqlpassword -e "CREATE USER '$jamfpro_database_username'@'$mysqlserveraddress' IDENTIFIED WITH 'mysql_native_password' BY '$jamfpro_database_password';" 2>/dev/null
mysql -h$mysqlserveraddress -u$mysqluser -p$mysqlpassword -e "GRANT ALL ON $jamfpro_database_dbname.* TO '$jamfpro_database_username'@'$mysqlserveraddress';" 2>/dev/null

# Create directory to download latest Jamf Pro installer

jamfpro_download_directory=/tmp/jamfpro-download

mkdir -p "$jamfpro_download_directory"

# Copy the Jamf Pro installer from the appropriate S3 bucket to the download directory

echo "Downloading $jamfpro_download_filename from $jamfpro_download_url"

wget -O "$jamfpro_download_directory"/latest_jamfpro_installer.zip "$jamfpro_download_url"/"$jamfpro_download_filename"

# Unzip the Jamf Pro installer

unzip "$jamfpro_download_directory/latest_jamfpro_installer.zip" -d "$jamfpro_download_directory"

# Install Jamf Pro

echo "Installing Jamf Pro"

yes | "$jamfpro_download_directory/jamfproinstaller.run"

# After installation, stop Tomcat

echo "Stopping Jamf Pro"

systemctl stop jamf.tomcat8

echo "Configuring Jamf Pro to use its MySQL database"

# Back up the existing /usr/local/jss/tomcat/webapps/ROOT/WEB-INF/xml/DataBase.xml file

database_xml_file="/usr/local/jss/tomcat/webapps/ROOT/WEB-INF/xml/DataBase.xml"

if [[ -f /usr/local/jss/tomcat/webapps/ROOT/WEB-INF/xml/DataBase.xml ]]; then
    sudo -u jamftomcat cp /usr/local/jss/tomcat/webapps/ROOT/WEB-INF/xml/DataBase.xml /usr/local/jss/tomcat/webapps/ROOT/WEB-INF/xml/DataBase.bak
fi

# Use xmlstarlet to populate the correct values for the following attributes in /usr/local/jss/tomcat/webapps/ROOT/WEB-INF/xml/DataBase.xml
#
# ServerName
# ServerPort
# DataBaseName
# DataBaseUser
# DataBasePassword

sudo -u jamftomcat /usr/bin/xmlstarlet edit --inplace --update "DataBase/ServerName" --value "$mysqlserveraddress" "$database_xml_file"
sudo -u jamftomcat /usr/bin/xmlstarlet edit --inplace --update "DataBase/ServerPort" --value "$mysqlserverport" "$database_xml_file"
sudo -u jamftomcat /usr/bin/xmlstarlet edit --inplace --update "DataBase/DataBaseName" --value "$jamfpro_database_dbname" "$database_xml_file"
sudo -u jamftomcat /usr/bin/xmlstarlet edit --inplace --update "DataBase/DataBaseUser" --value "$jamfpro_database_username" "$database_xml_file"
sudo -u jamftomcat /usr/bin/xmlstarlet edit --inplace --update "DataBase/DataBasePassword" --value "$jamfpro_database_password" "$database_xml_file"

# Fix permissions on /usr/local/jss/tomcat/webapps/ROOT/WEB-INF/xml/DataBase.xml

chown jamftomcat:jamftomcat "$database_xml_file"

# Start Tomcat

echo "Starting Jamf Pro"

systemctl start jamf.tomcat8

# Remove the download directory

rm -rf "$jamfpro_download_directory"