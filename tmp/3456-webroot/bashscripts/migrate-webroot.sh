#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <domains> <settings>"
    echo "Example: $0 'clouding1.d.christian-wolf.click' '-t'"
    exit 1
fi

domains="$1"
settings="$2"

echo Installing Nextcloud snap package...
snap install --channel 14 nextcloud

echo Install instance
nextcloud.manual-install admin admin1234_

## backup working config.php ##
#cp /var/snap/nextcloud/current/nextcloud/config/config.php /var/snap/nextcloud/current/ ;

echo Set some default settings for better performance and security...
## set default phone region edit <GB, DE, IT>##
nextcloud.occ config:system:set default_phone_region --value="<GB>"
## set http compression (optional) ##
snap set nextcloud http.compression=true
## set trusted domains edit <CLOUD.MY.DOMAIN.TLD>##
nextcloud.occ config:system:set trusted_domains 0 --value="clouding1.d.christian-wolf.click"
## set overwritehostprotocol ##
nextcloud.occ config:system:set overwriteprotocol --value="https"
## disable appapi
nextcloud.occ app:disable app_api

echo "Run some maintenance commands to update the database and fix missing indices and mimetypes..."
## update database
nextcloud.occ maintenance:mimetype:update-db
## fix missing indices
nextcloud.occ db:add-missing-indices
## fix missing mimetypes
nextcloud.occ maintenance:repair --include-expensive

## set mail address in user profile for admin user ##
#nextcloud.occ occ user:setting <ADMINUSER> settings email "<ADMINUSER>@example.tld>"

echo
echo "Set up Certs"
## recommend start Lets Encrypt certification using built in service, see Wiki 
nextcloud.enable-https lets-encrypt $settings << EOF
y
foo@example.com
$domains
EOF

## recommend truncate logs and restart the snap see Wiki
#truncate -s 0 /var/snap/nextcloud/current/logs/nextcloud.log ; 
#snap restart nextcloud ;

echo
echo "OK, we should be done, you can now access your Nextcloud instance at https://clouding1.d.christian-wolf.click with username admin and password admin1234_"
echo "Next, I am going to refresh the snap to the latest (stable) channel."
read -p "Press any key to continue... " -n1 -s
echo

for version in $(seq 15 32)
do
    echo "Refreshing to version $version..."
    snap refresh --channel=$version nextcloud
    echo "Waiting for Nextcloud to be ready..."
    while ! nextcloud.occ status &> /dev/null; do
        sleep 5
    done
    echo "Nextcloud v$version is ready!"
done

echo
echo "All versions from 15 to 32 have been refreshed and are ready!"
echo

echo Renewal script
echo ==============================
cat /var/snap/nextcloud/current/certs/certbot/configs/renewal/clouding1.d.christian-wolf.click.conf
echo ==============================

echo
echo "Please check the certificate"
echo "Next, I am going to refresh the snap to the latest PR version (beta/pr-3456)."
read -p "Press any key to continue... " -n1 -s
echo

echo "Install PR version"
snap refresh --channel beta/pr-3456 nextcloud
echo "Waiting for Nextcloud to be ready..."
while ! nextcloud.occ status &> /dev/null; do
    sleep 5
done
echo "Nextcloud PR #3456 is ready!"

echo
echo Renewal script
echo ==============================
cat /var/snap/nextcloud/current/certs/certbot/configs/renewal/clouding1.d.christian-wolf.click.conf
echo ==============================
