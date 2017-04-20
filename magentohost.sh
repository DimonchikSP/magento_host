#!/bin/bash
#this script create virtual host and
#install magento with samplae data
read -p "Enter your domain name , example magento.dev: `echo $'\n> '`" domain

#create dir tree for site
mkdir /var/www/$domain
mkdir /var/www/$domain/logs
mkdir /var/www/$domain/public_html

# Create the file with VirtualHost configuration in /etc/apache2/site-available/
echo "<VirtualHost *:80>
          ServerAdmin admin@beprogrammer.com
          DocumentRoot  /var/www/$domain/public_html
          ServerName $domain
          DirectoryIndex index.php
          ServerAlias www.$domain
          ErrorLog  /var/www/$domain/logs/error_log
          CustomLog  /var/www/$domain/logs/access_log common
        <Directory  /var/www/$domain/public_html>
            Options Indexes FollowSymLinks
            AllowOverride All
            Order allow,deny
            Allow from all
        </Directory>
</VirtualHost>" > /etc/apache2/sites-available/$domain.conf

#add host to file hosts
echo 127.0.0.1 $domain >> /etc/hosts

#enable site
a2ensite $domain

#restart apache2
service apache2 restart

#get user name & group name
userName="$USER"
userGroup="$(id -u -n)"

#set owner to new site dir
chown -R $userName:$userGroup /var/www/$domain

#get magento install & sample-data archives
magentoInstall=$(find magento-1*.*)
magentoSample=$(find magento-sample*.*)

#install dtrx for unpack any archive
if ! type dtrx > /dev/null; then
  echo "Install dtrx for unpack all archives"
  apt-get install dtrx -y
else
  echo "dtrx  is already installed"
fi

dirmagento=$(find . -maxdepth 1 -type d  -name "magento")
dirsample=$(find . -maxdepth 1 -type d  -name "magento-sample-data*")

isdirectory() {
  if [ -d "$1" ]
  then
    # 0 = true
    return 0
  else
    # 1 = false
    return 1
  fi
}
#unpack archives
if isdirectory $dirmagento;
then
  echo "Folder with magento install already exist"
else
  dtrx -f $magentoInstall
fi

if isdirectory $dirsample;
then
  echo "Folder with magento sample data already exist"
else
  dtrx -f $magentoSample
fi


#set owner to magento install & sample-data
chown -R $userName:$userGroup ./magento*

#copy magento to site dir
shopt -s dotglob
cp -r magento/* /var/www/$domain/public_html
cp -r magento-sample-data*/* /var/www/$domain/public_html

#set permissions to site dir tree
echo "Changing permissions for directories to 755";
find /var/www/$domain/public_html -type d -exec chmod 755 {} \;
echo "Changing permissions for files to 644";
find /var/www/$domain/public_html -type f -exec chmod 644 {} \;
echo "Changing permissions for media to 777";
chmod 777 -R /var/www/$domain/public_html/media/;
echo "Changing permissions for var to 777";
chmod 777 -R /var/www/$domain/public_html/var/;
echo "Changing permissions for app/etc to 777";
chmod 777 -R /var/www/$domain/public_html/app/etc/;
echo "Changing permissions for downloader to 777";
chmod 777 -R /var/www/$domain/public_html/downloader/;
echo "Changing permissions for mage to 777";
chmod 777 /var/www/$domain/public_html/mage;

#create DB and add sample-data
read -p "Enter name for new DB: `echo $'\n> '`" dbname
echo "Enter password to rcreate DB: $dbname `echo $'\n> '`"
mysql -h localhost -u root -p -e"create database $dbname"
echo "Enter password to insert sample-data to DB: $dbname"
mysql -h localhost -u root -p $dbname < /var/www/$domain/public_html/magento_sample_data*.sql

#enter all info for install magento
read -p "Enter DB host (default value - localhost): `echo $'\n> '`" -i "localhost" dbhost
read -p "Enter user name from DB $dbname (default - root): `echo $'\n> '`" -i "root" dbuser
read -s -p "Enter password from DB user $dbuser: `echo $'\n> '`" dbpass
read -p "Enter Magento admin first name: `echo $'\n> '`" adminfname
read -p "Enter Magento admin last name: `echo $'\n> '`" adminlname
read -p "Enter Magento admin email: `echo $'\n> '`" adminemail
read -p "Enter Magento admin username: `echo $'\n> '`" adminuser
read -s -p "Enter Magento admin password: `echo $'\n> '`" adminpass


#install magento
php -f /var/www/$domain/public_html/install.php -- \
--license_agreement_accepted "yes" \
--locale "en_US" \
--timezone "America/Los_Angeles" \
--default_currency "USD" \
--db_host "$dbhost" \
--db_name "$dbname" \
--db_user "$dbuser" \
--db_pass "$dbpass" \
--url "http://$domain" \
--use_rewrites "yes" \
--use_secure "no" \
--secure_base_url "" \
--use_secure_admin "no" \
--admin_firstname "$adminfname" \
--admin_lastname "$adminlname" \
--admin_email "$adminemail" \
--admin_username "$adminuser" \
--admin_password "$adminpass"
