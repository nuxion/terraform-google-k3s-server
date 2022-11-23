#!/bin/bash
set -o nounset
set -o errexit
export DEBIAN_FRONTEND=noninteractive
CHECK_EVERY=8
CS_VERSION=0.6.0
LOG_FILE=/var/log/startup.log

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

META=`curl -s "http://metadata.google.internal/computeMetadata/v1/instance/?recursive=true" -H "Metadata-Flavor: Google"`
PROJECT=`echo $META | jq .attributes.project | tr -d '"'`
SERVER=`echo $META | jq .attributes.server | tr -d '"'`
K3S_VERSION=`echo $META | jq .attributes.version | tr -d '"'`
K3S_NAME=`echo $META | jq .attributes.clustername | tr -d '"'`
POOL=`echo $META | jq .attributes.pool | tr -d '"'`
BUCKET=`echo $META | jq .attributes.bucket | tr -d '"'`
REGISTRY=`echo $META | jq .attributes.registry | tr -d '"'`
# MZONE=`curl -s "http://metadata.google.internal/computeMetadata/v1/instance/zone" -H "Metadata-Flavor: Google"`
# ZONE=`echo ${META} | jq ".zone" | tr "/" "\n" | tail -n 1`
# IPV4=`echo ${META} | jq ".networkInterfaces[0].ip" | tr -d '"'`
#cho $c |  perl -lane 'print join " ", map {"--node-label " . $_} @F'
wait_kube(){
    running=`systemctl status k3s-agent | grep running`
    while [ $running -lt 1 ]
    do
        _log "Waiting for node $HOSTNAME to be readdy..."
    	# ready=`kubectl describe node $HOSTNAME | grep NodeReady | wc -l`
        running=`systemctl status k3s-agent | grep running`
        sleep $CHECK_EVERY
    done
    
}


git clone --depth 1 https://github.com/nuxion/terraform-google-k3s-server /opt/terraform-google-k3s-server

export INSTALL_K3S_EXEC="agent --node-label pool=${POOL}"

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

# gsutil cp gs://infra/${K3S_NAME}/config.yaml /etc/rancher/
if ! command_exists "kubectl" &> /dev/null
then
    _log "Wait kubernetes main to be ready"
    res=`curl -sk ${SERVER}/cacerts | sha256sum`
    _log "${res}"
    _log "Downloading and installing K3s"
    gsutil cp ${BUCKET}/k3s/${K3S_NAME}/node-token /root/token | tee /dev/fd/3
    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${K3S_VERSION} K3S_URL=$SERVER K3S_TOKEN=`cat /root/token` sh -
    wait_kube
    rm /root/token

fi
# _log "Showing final state of kubernetes"
# kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml get pods -A -o wide | tee /dev/fd/3
