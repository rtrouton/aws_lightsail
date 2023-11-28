This script is designed to set up a new Jamf Pro server on Ubuntu. Script has been tested and verified to work on Ubuntu 22.04 LTS

As part of its run, it performs the following actions:

1. Installs the following software:

*  OpenJDK 11
*  nano
*  wget
*  zip
*  unzip
*  xmlstarlet
*  MySQL 8.x

2. Configures MySQL 8.x with a specified root password.

3. Sets up a new MySQL database for Jamf Pro with a specified
   database name, username and password.

4. Downloads the Jamf Pro installer for Linux as a .zip file from a specified URL.

5. Unzips the Jamf Pro installer.

6. Installs Jamf Pro.

7. Stops Jamf Pro

8. Configures Jamf Pro to work with the newly-created MySQL database.

9. Restarts Jamf Pro
