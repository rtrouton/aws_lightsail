This script is designed to set up the following software on Ubuntu:

Reposado: [https://github.com/wdas/reposado](https://github.com/wdas/reposado)
Margarita: [https://github.com/jessepeterson/margarita
](https://github.com/jessepeterson/margarita
)

Script has been tested and verified to work on Ubuntu 16.04 LTS.

As part of its run, it performs the following actions:

1. Installs the following software:

*  Apache (apache2)
*  Apache utility programs (apache2-utils)
*  Python WSGI adapter module for Apache (libapache2-mod-wsgi)
*  Python3 
*  Python enhancements (python-setuptools)
*  pip (python3-pip)
*  curl
*  flask

2. Creates the directories for storing Reposado and Margarita, as well as Reposado catalogs and packages.

3. Downloads and installs Reposado and Margarita

4. Configures Reposado

5. Installs script to automatically start Margarita when Apache starts.

6. Configures Apache to work with Reposado and Margarita

7. Sets a password for the Margarita web interface.

8. Sets the correct permissions for Apache to have access to the Reposado catalogs and packages

9. Restarts Apache

10. Runs the initial Reposado software sync

Original script by Owen Pragel: [https://github.com/opragel/reposado_margarita_apache_install](https://github.com/opragel/reposado_margarita_apache_install)