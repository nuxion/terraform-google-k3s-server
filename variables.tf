variable "project" {
  description = "gce project id"
  type = string
}

variable "base_path" {
  description = "base path of the project"
  type = string
}

variable "dns_name" {
    description = "DNS private zone"
    type = string
}

variable "dns_zone_name" {
    description = "DNS private zone name"
    type = string
}

variable "k3s_service_account" {
  type = string
  default = "k3s-installer"
}

variable "k3s_scopes" {
  type = list
  default = ["compute-ro", "storage-full"]
}

variable "network_tags" {
  type = list
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
  description = "gce type machine"
  type = string
  default = "e2-medium"
}

variable "server_boot_image" {
  description = "gce type machine"
  type = string
  default = "debian-cloud/debian-11"
}

variable "server_boot_size" {
  description = "gce size machine"
  type = string
  default = "10"
}

variable "server_boot_type" {
  description = "gce type machine"
  type = string
  default = "pd-standard"
}

variable "k3s_network" {
  type = string
  default = "default"
}

variable "k3s_version" {
  type = string
  default = "v1.24.4+k3s1"
}

variable "k3s_csidisk" {
  type = string
  default = "stable-1-24"
}

variable "operator_user" {
    description = "Operator user"
    type = string
    default = "op"
}

variable "private_key_path" {
  description = "Priv key of op user"
  type = string
  default = ""
}

variable "public_key_path" {
  description = "Pub key of op user"
  type = string
  default = ""
}

