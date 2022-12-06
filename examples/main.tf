provider "google" {
  project     = "${var.project_id}"
  region  = "us-central1"
  zone    = "us-central1-c"
}

variable "project_id" {
  description = "GCP Project ID"
  type = string
}

variable "zone" {
  description = "Zone is the complete name as 'us-central1-a'"
  type = string
  default = "us-central1-a"
}

variable "agt_zone" {
  description = "Zone for the agent"
  type = string
  default = "us-central1-a"
}


variable "region" {
  type = string
  description = "region is more general area like 'us-central1'"
  default = "us-central1"
}

variable "bucket" {
  type = string
  description = "bucket for postgresql state"
}

module "k3s" {
  source = "../"
  server_name = "k3s-main"
  server_zone="${var.zone}"
  network_name="prod"
  network_tags = ["prod"]
  project_id = "${var.project_id}"
  bucket="${var.bucket}"
  registry="${var.region}-docker.pkg.dev"
}

module "k3s_tpl" {
  source = "../modules/node-template"
  tpl_name= "k3s-tpl"
  network_name="prod"
  network_tags = ["prod"]
  k3s_url = "${module.k3s.k3s_url}"
  project_id = "${var.project_id}"
  bucket="${var.bucket}"
  spot_instance=true
  registry="${var.region}-docker.pkg.dev"
}

resource "google_compute_instance_group_manager" "agent" {
  name = "agent"

  base_instance_name = "agt"
  zone               = "${var.agt_zone}"

  version {
    instance_template  = module.k3s_tpl.id
  }

  # all_instances_config {
  #   metadata = {
  #     pool = "general"
  #   }
  #   labels = {
  #     env = "prod"
  #     pool = "general"
  #   }
  # }
  target_size  = 1

}
