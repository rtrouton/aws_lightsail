This script is designed to set up a new Jamf Pro server on Ubuntu. Script has been tested and verified to work on Ubuntu 18.04 LTS

As part of its run, it performs the following actions:

1. Installs the following software:

*  OpenJDK 11
*  nano
*  wget
*  zip
*  unzip
*  xmlstarlet
*  MySQL (the version of MySQL depends on the script used.)

2. Configures MySQL with a specified root password.

3. Sets up a new MySQL database for Jamf Pro with a specified
   database name, username and password.

4. Downloads the Jamf Pro installer for Linux as a .zip file from a specified URL.

5. Unzips the Jamf Pro installer.

6. Installs Jamf Pro.

7. Stops Jamf Pro

8. Configures Jamf Pro to work with the newly-created MySQL database.

9. Restarts Jamf Pro

**MySQL versions installed**

* MySQL 5.7: See the `lightsail_jamf_pro_setup_with_mysql_57` directory for the appropriate script.
* MySQL 8.x: See the `lightsail_jamf_pro_setup_with_mysql_8` directory for the appropriate script.