variable "project_id" {
  description = "GCP Project ID"
  type = string
}

variable "script_install" {
  description = "startup script for k3s installation"
  type = string
  default = "files/k3s_install.sh"
}

# variable "base_path" {
#   description = "base path of the project"
#   type = string
# }

# variable "dns_name" {
#     description = "DNS private zone"
#     type = string
# }
# 
# variable "dns_zone_name" {
#     description = "DNS private zone name"
#     type = string
# }

variable "k3s_service_account" {
  type = string
  description = "SA Account associated to the instance"
  default = "k3s-installer"
}

variable "k3s_scopes" {
  type = list
  description = "Scopes to be configurated when creation the instance"
  default = ["cloudplatform"]
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

variable "k3s_zone" {
  description = "zone for this server"
  type = string
}

variable "k3s_location" {
  description = "loc for this server"
  type = string
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
  default = "e2-medium"
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

variable "k3s_network" {
  description = "Network to attach"
  type = string
  default = "default"
}

variable "k3s_version" {
  description = "K3s version to install"
  type = string
  default = "v1.24.4+k3s1"
}

variable "k3s_csidisk" {
  description = "CSI driver version to install for google disk provisioning"
  type = string
  default = "stable-1-24"
}
