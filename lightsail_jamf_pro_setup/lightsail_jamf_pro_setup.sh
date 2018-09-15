#!/bin/bash

# This script is designed to set up a new Jamf Pro server on Ubuntu.
# 
# Script has been tested and verified to work on Ubuntu 16.04 LTS
#
# As part of its run, it performs the following actions:
#
# 1. Installs the following software:
#
#  OpenJDK 8
#  nano
#  wget
#  zip
#  unzip
#  MySQL 5.7
#
# 2. Configures MySQL 5.7 with a specified root password.
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

apt-get install -y openjdk-8-jdk nano wget zip unzip

# Add the appropriate apt repo for MySQL 5.7

echo "Adding MySQL apt repo to system"
wget https://dev.mysql.com/get/mysql-apt-config_0.8.3-1_all.deb
dpkg -i mysql-apt-config_0.8.3-1_all.deb
apt-get update -q
rm mysql-apt-config_0.8.3-1_all.deb

# Install and configure MySQL

echo "Installing MySQL 5.7"

echo "mysql-server-5.7 mysql-server/root_password password $mysqlpassword" | debconf-set-selections
echo "mysql-server-5.7 mysql-server/root_password_again password $mysqlpassword" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server

echo "Enabling MySQL to start on system restart"
systemctl enable mysql

echo "Starting MySQL 5.7"
systemctl start mysql

# Create Jamf Pro database

echo "Creating new database for instance: $jamfpro_database_dbname "
mysql -h$mysqlserveraddress -u$mysqluser -p$mysqlpassword -e "CREATE DATABASE $jamfpro_database_dbname;" 2>/dev/null
mysql -h$mysqlserveraddress -u$mysqluser -p$mysqlpassword -e "GRANT ALL ON $jamfpro_database_dbname.* TO $jamfpro_database_username@$mysqlserveraddress IDENTIFIED BY '$jamfpro_database_password';" 2>/dev/null

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

mv /usr/local/jss/tomcat/webapps/ROOT/WEB-INF/xml/DataBase.xml /usr/local/jss/tomcat/webapps/ROOT/WEB-INF/xml/DataBase.bak

# Create a new DataBase.xml file

cat > /usr/local/jss/tomcat/webapps/ROOT/WEB-INF/xml/DataBase.xml << JamfProDatabase
<?xml version="1.0" encoding="UTF-8"?>
<DataBase>
	<DataBaseType>mysql</DataBaseType>
	<DataBaseDriver>org.mariadb.jdbc.Driver</DataBaseDriver>
	<ServerName>$mysqlserveraddress</ServerName>
	<ServerPort>$mysqlserverport</ServerPort>
	<DataBaseName>$jamfpro_database_dbname</DataBaseName>
	<DataBaseUser>$jamfpro_database_username</DataBaseUser>
	<DataBasePassword>$jamfpro_database_password</DataBasePassword>
	<MinPoolSize>5</MinPoolSize>
	<MaxPoolSize>45</MaxPoolSize>
	<MaxIdleTimeExcessConnectionsInMinutes>1</MaxIdleTimeExcessConnectionsInMinutes>
	<MaxConnectionAgeInMinutes>5</MaxConnectionAgeInMinutes>
	<NumHelperThreads>3</NumHelperThreads>
	<InStatementBatchSize>1000</InStatementBatchSize>
	<jdbcParameters>?characterEncoding=utf8&amp;useUnicode=true&amp;jdbcCompliantTruncation=false</jdbcParameters>
</DataBase>
JamfProDatabase


# Fix permissions on /usr/local/jss/tomcat/webapps/ROOT/WEB-INF/xml/DataBase.xml

chown jamftomcat:jamftomcat /usr/local/jss/tomcat/webapps/ROOT/WEB-INF/xml/DataBase.xml

# Start Tomcat

echo "Starting Jamf Pro"

systemctl start jamf.tomcat8

# Remove the download directory

rm -rf "$jamfpro_download_directory"