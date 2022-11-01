#!/bin/bash
BUCKET=$1
SERVER_DIR=/var/lib/rancher/k3s/server
BACKUP_DIR=$(mktemp -d)

sqlite3 ${SERVER_DIR}/db/state.db ".backup '${SERVER_DIR}/db/backup.db'"
tar cvfz $BACKUP_DIR/k3s-server.tgz $SERVER_DIR/agent-token $SERVER_DIR/cred $SERVER_DIR/etc $SERVER_DIR/manifests $SERVER_DIR/node-token $SERVER_DIR/static $SERVER_DIR/tls $SERVER_DIR/token /etc/rancher $SERVER_DIR/db/backup.db

dt=$(date '+%Y-%m-%d')
gsutil cp $BACKUP_DIR/k3s-server.tgz $BUCKET/k3s-server_${dt}.tgz
rm -Rf $BACKUP_DIR
