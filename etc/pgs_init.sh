#!/bin/bash

conf='/var/lib/postgresql/data/pg_hba.conf'
net="0.0.0.0/0"

## http://www.postgresql.org/docs/9.1/static/auth-pg-hba-conf.html

echo "Changing access"
echo "" > $conf

# Enable to allow health checks
echo "hostnossl $POSTGRES_USER all $net md5" >> $conf
echo "host all all $net md5">> $conf

# Setup DB
echo "Enabling DB $IRODS_DB_NAME..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" << EOSQL
    CREATE DATABASE "$IRODS_DB_NAME";
    CREATE USER $IRODS_DB_USER WITH PASSWORD '$IRODS_DB_PASS';
    GRANT ALL PRIVILEGES ON DATABASE "$IRODS_DB_NAME" TO $IRODS_DB_USER;
EOSQL

echo "DONE"
