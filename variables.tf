variable "project_id" {
  description = "GCP Project ID"
  type = string
}

variable "bucket" {
  description = "Bucket used to store k3s status data, for instance: 'gs://<project-id>-kubernetes'. You MUST include 'gs://' prefix."
  type = string
}

variable "backup_bucket" {
  description= "backup bucket"
  type= string
  default = ""
}

variable "restore_bucket" {
  description= "restore backup bucket"
  type= string
  default = ""
}

variable "restore_file" {
  description= "restore file name of backup"
  type= string
  default = ""
}

variable "registry" {
  description= "google registry"
  type= string
  default = ""
}

variable "script_install" {
  description = "startup script for k3s installation"
  type = string
  default = "files/k3s_install.sh"
}

variable "k3s_service_account" {
  type = string
  description = "SA Account associated to the instance"
  default = "k3s-installer"
}

variable "k3s_scopes" {
  type = list
  description = "Scopes to be configurated when creation the instance"
  default = ["cloud-platform"]
}

variable "network_tags" {
  type = list
  description = "Network tags to use for the instance (firewall related)"
  default = ["k3s", "default"]
}

variable "server_name" {
  description = "hostname for the server"
  type = string
  default = "k3s-server"

}

variable "server_zone" {
  description = "zone for this server"
  type = string
  default = "us-central1-a"
}

variable "label_env" {
  description = "Label environment"
  type = string
  default = "prod"
}

variable "cluster_name" {
  description = "Cluster name"
  type = string
  default = "default"
}

variable "server_machine_type" {
  description = "GCP type machine"
  type = string
  default = "e2-small"
}

variable "server_boot_image" {
  description = "Boot Disk Image"
  type = string
  default = "debian-cloud/debian-11"
}

variable "server_boot_size" {
  description = "Boot Disk Size"
  type = string
  default = "10"
}

variable "server_boot_type" {
  description = "Boot Disk Type"
  type = string
  default = "pd-standard"
}

variable "network_name" {
  description = "Network to attach"
  type = string
  default = "default"
}

variable "k3s_version" {
  description = "K3s version to install, see https://github.com/k3s-io/k3s/releases"
  type = string
  # default = "v1.24.4+k3s1"
  default = "v1.26.0+k3s1"
}

variable "k3s_csidisk_version" {
  description = "CSI driver version to install for google disk provisioning"
  type = string
  default = "stable-1-24"
}

variable "ingress_controller" {
  type = string
  description = "Choose which controller install. Options: 'traefik', 'nginx'"
  default = "nginx"

}

