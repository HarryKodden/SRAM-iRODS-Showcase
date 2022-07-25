#!/bin/bash

# Make sure we run latest version of ldap syncer
(cd /opt/irods-ldap-sync && git pull && pip install -r requirements.txt)

# Prepare default iRODS environment...
cat <<EOF > ${IRODS_JSON}
{
    "irods_host": "${IRODS_HOST}",
    "irods_port": ${IRODS_PORT},
    "irods_zone_name": "${IRODS_ZONE}",
    "irods_ssl_ca_certificate_file": "${IRODS_CERT}"
}
EOF

# Prepase default shell for users...
sed -i 's|SHELL=/bin/sh|SHELL=/bin/bash|g' /etc/default/useradd 

# Prepase SSH for Pubkey authentication exclusively !
sed -i 's/^PasswordAuthentication yes/#PasswordAuthentication yes/g' /etc/ssh/sshd_config 
sed -i 's/^#PubkeyAuthentication .*/PubkeyAuthentication yes/g' /etc/ssh/sshd_config 

# Prepare SSH Acces for service account (e.g. root), used only by cronjob...
mkdir -p /var/run/sshd \
    && echo "sshd: ALL" >> /etc/hosts.allow \
    && mkdir -p ~/.ssh \
    && ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N '' \
    && touch ~/.ssh/authorized_keys; chmod 600 ~/.ssh/authorized_keys \
    && cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

# Prepare CRON...
read -r -d '' CRONJOB <<- EOM
    IRODS_AUTH=${IRODS_AUTH}
    IRODS_CERT=${IRODS_CERT}
    IRODS_HOST=${IRODS_HOST}
    IRODS_JSON=${IRODS_JSON}
    IRODS_PASS=${IRODS_PASS}
    IRODS_PORT=${IRODS_PORT}
    IRODS_USER=${IRODS_USER}
    IRODS_ZONE=${IRODS_ZONE}
    LDAP_ADMIN_PASSWORD=${LDAP_ADMIN_PASSWORD}
    LDAP_BASE_DN=${LDAP_BASE_DN}
    LDAP_BIND_DN=${LDAP_BIND_DN}
    LDAP_HOST=${LDAP_HOST}
    LDAP_MODE=${LDAP_MODE}
    LOG_LEVEL=${LOG_LEVEL}
    SSH_HOST=${SSH_HOST}
    SSH_PORT=${SSH_PORT}
    python3 /usr/local/bin/sync.py >> /tmp/sync.log 2>&1
EOM
crontab -l | { cat; echo "* * * * * "$CRONJOB; } | crontab -

# Start services...
service cron start
service ssh start
service rsyslog start

echo "iCommands is ready"

sleep infinity
