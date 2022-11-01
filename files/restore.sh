#!/bin/bash
BUCKET=$1
TARGZ=$2
SERVER_DIR=/var/lib/rancher/k3s/server
RANCHER_CONF=/etc/rancher
BACKUP_DIR=$(mktemp -d)

mkdir -p ${SERVER_DIR}
mkdir -p ${RANCHER_CONF}
gsutil cp ${BUCKET}/${TARGZ} ${BACKUP_DIR}/${TARGZ}
tar xvfz ${BACKUP_DIR}/${TARGZ} -C /
mv ${SERVER_DIR}/db/backup.db $SERVER_DIR/db/state.db
rm -Rf $BACKUP_DIR
