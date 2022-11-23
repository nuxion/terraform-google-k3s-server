variable "project_id" {
  description = "gce project id"
  type = string
}

variable "bucket" {
  description = "Bucket used to store k3s status data"
  type = string
}

variable "k3s_url" {
  description = "URLs server of the Kubernetes API server"
  type = string
}

variable "registry" {
  description= "google registry"
  type= string
  default = ""
}

variable "script_install" {
  description = "startup script for k3s installation"
  type = string
  default = "files/k3s_node_startup.sh"
}

variable "tpl_name" {
  description = "Name of the template"
  type = string
}

variable "tpl_description" {
  description = "Description of the template"
  type = string
  default = "Used to create node pools of k3s agents"
}

variable "k3s_service_account" {
  type = string
  description = "SA Account associated to the instance"
  default = "k3s-installer"
}

variable "k3s_scopes" {
  type = list
  default = ["cloud-platform"]
}

variable "network_tags" {
  type = list
  default = ["k3s", "default"]
}

variable "spot_instance" {
  description = "If the instance is preemtible or not (if true automatic_restart should be false)"
  type = bool
  default = false
}

variable  "automatic_restart" {
  description = "Specifies if the instance should be restarted if it was terminated by Compute Engine (not a user). Defaults to true."
  type = bool
  default = true
}

variable "label_env" {
  description = "Label environment"
  type = string
  default = "prod"
}

variable "label_pool_name" {
  description = "Name of this pool of nodes built from the template"
  type = string
  default = "general"
}

variable "cluster_name" {
  description = "Cluster name"
  type = string
  default = "default"
}

variable "cpu_machine_type" {
  description = "gce type machine"
  type = string
  default = "e2-small"
}

variable "cpu_boot_image" {
  description = "gce type machine"
  type = string
  default = "debian-cloud/debian-11"
}

variable "cpu_boot_size" {
  description = "gce size machine"
  type = string
  default = "10"
}

variable "cpu_boot_type" {
  description = "gce type machine"
  type = string
  default = "pd-standard"
}

variable "network_name" {
  description = "Network name to be linked"
  type = string
  default = "default"
}

variable "k3s_version" {
  description = "k3s version to install"
  type = string
  default = "v1.24.4+k3s1"
}


