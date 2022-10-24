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
  project_id = "${var.project_id}"
  bucket="${var.bucket}"
}
