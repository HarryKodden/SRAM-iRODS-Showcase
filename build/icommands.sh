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
crontab -l | { cat; echo "*/5 * * * * python3 /usr/local/bin/sync.py"; } | crontab -

# Start services...
service cron start
service ssh start

echo "iCommands is ready"

sleep infinity
