#!/bin/bash

# Make sure we run latest version of SRAM Token service...
(cd /opt/SRAM-Token-Service && git pull && make && make install)

# Check postgres at startup
until PGPASSWORD=$IRODS_DB_PASS psql -h $IRODS_DB_HOST -U $IRODS_DB_USER $IRODS_DB_NAME -c "\d" 1> /dev/null 2> /dev/null;
do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

# setup SSL keys...
mkdir /etc/irods/ssl 2>/dev/null
cd /etc/irods/ssl

if [ ! -f irods.key ]; then
  openssl genrsa -out irods.key
fi

if [ ! -f irods.crt ]; then
  openssl req -new -key irods.key -out irods.csr \
    -subj "/C=NL/ST=Science Park/L=Amsterdam/O=SURFsara/OU=IT Department/CN=$IRODS_HOST"
  openssl x509 -req -days 365 -in irods.csr -signkey irods.key -out /var/lib/ssl/irods.crt
  rm irods.csr
fi

if [ ! -f dhparams.pem ]; then
  openssl dhparam -dsaparam -out dhparams.pem 2048
fi

# Is it init time?
checkirods=$(ls /etc/irods/core.re)
if [ "$checkirods" == "" ]; then

    # Install irods...

    MYDATA="/tmp/answers"
    sudo -E /usr/local/bin/genresp.sh > $MYDATA

    # Launch the installation
    sudo /var/lib/irods/scripts/setup_irods.py < $MYDATA

    # Verify how it went
    if [ "$?" == "0" ]; then
        echo ""
        echo "iRODS INSTALLED!"
    else
        echo "Failed to install irods..."
        exit 1
    fi

    # Adjust default environment.json to make use of SSL cert...
    sed -i '2i    "irods_ssl_certificate_chain_file": "/var/lib/ssl/irods.crt", ' /var/lib/irods/.irods/irods_environment.json
    sed -i '3i    "irods_ssl_certificate_key_file": "/etc/irods/ssl/irods.key", '   /var/lib/irods/.irods/irods_environment.json
    sed -i '4i    "irods_ssl_ca_certificate_file": "/var/lib/ssl/irods.crt", '    /var/lib/irods/.irods/irods_environment.json
    sed -i '5i    "irods_ssl_dh_params_file": "/etc/irods/ssl/dhparams.pem", '      /var/lib/irods/.irods/irods_environment.json

    # make PAM config for iRODS
    echo "auth required /usr/local/bin/pam_sram_validate.so debug url=$SRAM_URL token=$SRAM_API" > /etc/pam.d/irods

    # make System Account for iRODS Admin
    pass=`echo $IRODS_PASS | openssl passwd -crypt -noverify -stdin`
    useradd --password $pass --shell /bin/false --no-create-home $IRODS_USER
fi

service irods start

echo "iRODS is ready"

sleep infinity
