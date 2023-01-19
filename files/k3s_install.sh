#!/bin/bash
set -o nounset
# set -o errexit
export DEBIAN_FRONTEND=noninteractive
CHECK_EVERY=8
CS_VERSION=0.7.0
LOG_FILE=/var/log/startup.log

exec 3>&1 1>>${LOG_FILE} 2>&1

_log() {
   echo "$(date): $@" | tee /dev/fd/3
}

command_exists() {
	command -v "$@" > /dev/null 2>&1
}


check_disk_formated() {
    lsblk -f ${1} | grep ext4
}

format_disk() {
    mkfs.ext4 ${1}
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
    curl -Ls https://raw.githubusercontent.com/nuxion/cloudscripts/${CS_VERSION}/install.sh | bash
fi

if ! command_exists "jq" &> /dev/null
then
    apt-get install -y jq
fi

if ! command_exists "git" &> /dev/null
then
    apt-get install -y git
fi

if ! command_exists "sqlite3" &> /dev/null
then
    apt-get install -y sqlite3
fi

if ! command_exists "helm" &> /dev/null
then
    cscli -i helm
fi

META=`curl -s "http://metadata.google.internal/computeMetadata/v1/instance/?recursive=true" -H "Metadata-Flavor: Google"`
PROJECT=`echo $META | jq .attributes.project | tr -d '"'`
K3S_VERSION=`echo $META | jq .attributes.version | tr -d '"'`
K3S_NAME=`echo $META | jq .attributes.clustername | tr -d '"'`
# MZONE=`curl -s "http://metadata.google.internal/computeMetadata/v1/instance/zone" -H "Metadata-Flavor: Google"`
# ZONE=`echo ${META} | jq ".zone" | tr "/" "\n" | tail -n 1`
DNS_NAME=`echo $META | jq .attributes.dnsname | tr -d '"'`
REGISTRY=`echo $META | jq .attributes.registry | tr -d '"'`
RESTORE_BUCKET=`echo $META | jq .attributes.restore_bucket | tr -d '"'`
RESTORE_TARGZ=`echo $META | jq .attributes.restore_file | tr -d '"'`
BACKUP_BUCKET=`echo $META | jq .attributes.backup_bucket | tr -d '"'`
BUCKET=`echo $META | jq .attributes.bucket | tr -d '"'`
INGRESS=`echo $META | jq .attributes.ingress | tr -d '"'`
IPV4=`echo ${META} | jq ".networkInterfaces[0].ip" | tr -d '"'`
# Ex: stable-1-24
CSI_DISK=`echo $META | jq .attributes.csidisk | tr -d '"'`

wait_kube(){
    running=`kubectl get pods -n kube-system | grep Running | wc -l`
    while [ $running -lt 3 ]
    do
        _log "Waiting for kubernetes to be readdy..."
        running=`kubectl get pods -n kube-system | grep Running | wc -l`
        sleep $CHECK_EVERY
    done
    
}

git clone --depth 1 https://github.com/nuxion/terraform-google-k3s-server /opt/terraform-google-k3s-server

if [ "$INGRESS" == "nginx" ];
then
    INSTALL_K3S_EXEC="server --secrets-encryption --disable traefik"
else
    INSTALL_K3S_EXEC="server --secrets-encryption"
fi

if [ ! -z "$REGISTRY" ];
then
    # https://github.com/k3s-io/k3s/issues/2367
    # https://github.com/k3s-io/k3s/issues/1610
    export INSTALL_K3S_EXEC="
    ${INSTALL_K3S_EXEC} \
    --kubelet-arg feature-gates=KubeletCredentialProviders=true \
    --kubelet-arg image-credential-provider-config=/etc/rancher/k3s/credential-provider-config.yaml \
    --kubelet-arg image-credential-provider-bin-dir=/usr/local/bin/
    "
    # registry_token=$(gcloud auth print-access-token)
    mkdir -p /etc/rancher/k3s
    cat <<EOT > /etc/rancher/k3s/credential-provider-config.yaml
kind: CredentialProviderConfig
apiVersion: kubelet.config.k8s.io/v1alpha1
providers:
  - name: custom-credential-provider
    matchImages:
      - "*.pkg.dev"
      - "pkg.dev"
    defaultCacheDuration: "1m"
    apiVersion: credentialprovider.kubelet.k8s.io/v1alpha1
EOT
    cp /opt/terraform-google-k3s-server/files/custom-credential-provider /usr/local/bin

fi

DEVICE=/dev/disk/by-id/google
K3S_VOL="${DEVICE}-pv-${HOSTNAME}"
_log "Configuring disk ${K3S_VOL}"
mkdir -p /var/lib/rancher/k3s
check_disk_formated ${K3S_VOL}
status=$?
if [ "${status}" -ne 0 ];
then
    format_disk ${K3S_VOL}
fi
resize2fs  ${K3S_VOL} | tee /dev/fd/3
mount ${K3S_VOL} /var/lib/rancher/k3s | tee /dev/fd/3

# gsutil cp gs://infra/${K3S_NAME}/config.yaml /etc/rancher/
if ! command_exists "kubectl" &> /dev/null
then

    if [ ! -d /etc/rancher/k3s ] ; then
	    mkdir -p /etc/rancher/k3s 
    fi
    _log "Creating config file for k3s"
    cat <<EOT > /etc/rancher/k3s/config.yaml
write-kubeconfig-mode: "0640"
tls-san:
    - "${DNS_NAME}"
node-label:
    - "pool=control-plane"
EOT

    if [ -z "${RESTORE_TARGZ}" ];
    then
        
        _log "Downloading K3s and installing"
        curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${K3S_VERSION} sh -

        _log "Putting node-token into ${BUCKET}/k3s/${K3S_NAME}"
        gsutil cp /var/lib/rancher/k3s/server/node-token ${BUCKET}/k3s/${K3S_NAME}/node-token | tee /dev/fd/3

        cat /etc/rancher/k3s/k3s.yaml | sed "s/127.0.0.1/${DNS_NAME}/g" > /root/k3s.yaml
        gsutil cp /root/k3s.yaml ${BUCKET}/k3s/${K3S_NAME}/k3s.yaml | tee /dev/fd/3
        rm /root/k3s.yaml

        wait_kube
        _log "Starting CSI Disk driver installation"
        mkdir -p /root/.gce
        gsutil cp ${BUCKET}/k3s/cloud-sa.json /root/.gce/cloud-sa.json | tee /dev/fd/3
        git clone --branch no-gopath --depth 1 https://github.com/nuxion/gcp-compute-persistent-disk-csi-driver /root/gcp-compute-persistent-disk-csi-driver
        cd /root/gcp-compute-persistent-disk-csi-driver
        DEPLOY_VERSION=$CSI_DISK GCE_PD_SA_DIR=/root/.gce ./deploy/kubernetes/deploy-driver.sh --skip-sa-check | tee /dev/fd/3
    else
        echo "Restoring ${RESTORE_TARGZ}"
        git clone --depth 1 https://github.com/nuxion/terraform-google-k3s-server /opt/terraform-google-k3s-server
	chmod +x /opt/terraform-google-k3s-server/files/restore.sh
        curl -sfL https://get.k3s.io |  INSTALL_K3S_SKIP_START=true INSTALL_K3S_VERSION=${K3S_VERSION}  sh -
	/opt/terraform-google-k3s-server/files/restore.sh ${RESTORE_BUCKET} ${RESTORE_TARGZ}
    fi
    
    if [ ! -z "${BACKUP_BUCKET}" ];
    then
	    chmod +x /opt/terraform-google-k3s-server/files/backup.sh 
        (crontab -l ; echo "00 09 * * 1-5 /opt/terraform-google-k3s-server/files/backup.sh ${BACKUP_BUCKET}") | crontab -
    fi
    
fi
if [ "$INGRESS" == "nginx" ];
then
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    helm upgrade --install ingress-nginx ingress-nginx \
         --repo https://kubernetes.github.io/ingress-nginx \
         --namespace ingress-nginx --create-namespace
fi
_log "Showing final state of kubernetes"
kubectl get pods -A -o wide | tee /dev/fd/3
