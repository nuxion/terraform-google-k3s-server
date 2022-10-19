#!/bin/bash
set -o nounset
set -o errexit
export DEBIAN_FRONTEND=noninteractive
CHECK_EVERY=8
LOG_FILE=/var/log/k3s_startup.log

exec 3>&1 1>>${LOG_FILE} 2>&1

_log() {
   echo "$(date): $@" | tee /dev/fd/3
}

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

# https://bugs.launchpad.net/ubuntu/+source/man-db/+bug/1858777
if [ ! -f "/opt/apt-update.lock" ];
then
    _log "Starting apt-update"
    touch /var/lib/man-db/auto-update
    apt-get update -y | tee /dev/fd/3
    touch /opt/apt-update.lock
    _log "apt-update Finished"
fi

if ! command_exists "cscli" &> /dev/null
then
    curl -Ls https://raw.githubusercontent.com/nuxion/cloudscripts/main/install.sh | sh
fi

if ! command_exists "jq" &> /dev/null
then
    apt-get install -y jq
fi

if ! command_exists "git" &> /dev/null
then
    apt-get install -y git
fi

META=`curl -s "http://metadata.google.internal/computeMetadata/v1/instance/?recursive=true" -H "Metadata-Flavor: Google"`
PROJECT=`echo $META | jq .attributes.project | tr -d '"'`
LOCATION=`echo $META | jq .attributes.location | tr -d '"'`
K3S_VERSION=`echo $META | jq .attributes.version | tr -d '"'`
K3S_NAME=`echo $META | jq .attributes.clustername | tr -d '"'`
# MZONE=`curl -s "http://metadata.google.internal/computeMetadata/v1/instance/zone" -H "Metadata-Flavor: Google"`
# ZONE=`echo ${META} | jq ".zone" | tr "/" "\n" | tail -n 1`
DNS_NAME=`echo $META | jq .attributes.dnsname | tr -d '"'`
IPV4=`echo ${META} | jq ".networkInterfaces[0].ip" | tr -d '"'`


# Ex: stable-1-24
CSI_DISK=`echo $META | jq attributes.csidisk | tr -d '"'`

wait_kube(){
    running=`kubectl get pods -n kube-system | grep Running | wc -l`
    while [ $running -lt 3 ]
    do
        _log "Waiting for kubernetes to be readdy..."
        running=`kubectl get pods -n kube-system | grep Running | wc -l`
        sleep $CHECK_EVERY
    done
    
}

# gsutil cp gs://infra/${K3S_NAME}/config.yaml /etc/rancher/
if ! command_exists "kubectl" &> /dev/null
then

    if [ ! -d /etc/rancher/k3s ] ; then
	    mkdir -p /etc/rancher/k3s 
    fi
    _log "Creating config file for k3s"
    cat <<EOT > /etc/rancher/k3s/k3s.yaml
write-kubeconfig-mode: "0640"
tls-san:
    - "${DNS_NAME}"
    - "${IPV4}"
node-label:
    - "pool=no"
EOT

    
    _log "Downloading K3s and installing"
    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${K3S_VERSION} sh -

    _log "Putting node-token into gs://${PROJECT}-infra/k3s/${LOCATION}/${K3S_NAME}"
    gsutil cp /var/lib/rancher/k3s/server/node-token gs://${PROJECT}-infra/k3s/${LOCATION}/${K3S_NAME}/node-token | tee /dev/fd/3

    cat /etc/rancher/k3s/k3s.yaml | sed "s/127.0.0.1/${DNS_NAME}/g" > /root/k3s.yaml
    gsutil cp /root/k3s.yaml gs://${PROJECT}-infra/k3s/${LOCATION}/${K3S_NAME}/k3s.yaml | tee /dev/fd/3
    rm /root/k3s.yaml

    wait_kube
    _log "Starting CSI Disk driver installation"
    mkdir -p /root/.gce
    gsutil cp gs://${PROJECT}-infra/k3s/cloud-sa.json /root/.gce/cloud-sa.json | tee /dev/fd/3
    git clone --branch no-gopath --depth 1 https://github.com/nuxion/gcp-compute-persistent-disk-csi-driver /root/gcp-compute-persistent-disk-csi-driver
    cd /root/gcp-compute-persistent-disk-csi-driver
    DEPLOY_VERSION=$CSI_DISK GCE_PD_SA_DIR=/root/.gce ./deploy/kubernetes/deploy-driver.sh --skip-sa-check | tee /dev/fd/3
fi
_log "Showing final state of kubernetes"
kubectl get pods -A -o wide | tee /dev/fd/3
