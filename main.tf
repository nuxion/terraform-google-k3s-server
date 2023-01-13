resource "google_compute_instance" "k3s_main" {
  name        = "${var.server_name}"
  description = "K3s control plane"

  tags = var.network_tags

  labels = {
    env = "${var.label_env}"
    cluster = "${var.cluster_name}"
  }

  machine_type         = "${var.server_machine_type}"
  zone = "${var.server_zone}"
  can_ip_forward       = true 

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  // Create a new boot disk from an image
  boot_disk {
    auto_delete       = true
    initialize_params {
      size = "${var.server_boot_size}"
      image      = "${var.server_boot_image}"
      type = "${var.server_boot_type}"
    }
    // backup the disk every day
    // resource_policies = [google_compute_resource_policy.daily_backup.id]
  }

  network_interface {
    network = "${var.network_name}"
    # for temporal public ip keeps access_config empty
    access_config { 
      # for fixed public ip address uncomment this
      # nat_ip = google_compute_address.core_external_ip.address
    }
  }

  # This prevent disk attachment loop when disk are provisioned using the CSI driver
  # https://github.com/hashicorp/terraform-provider-google/issues/2098
  lifecycle {
  	 ignore_changes = [attached_disk]
  }

  metadata = {
    project = "${var.project_id}"
    clustername = "${var.cluster_name}"
    version = "${var.k3s_version}"
    csidisk = "${var.k3s_csidisk_version}"
    bucket = "${var.bucket}"
    dnsname = "${var.server_name}.${var.server_zone}.c.${var.project_id}.internal"
    backup_bucket = "${var.backup_bucket}"
    restore_bucket = "${var.restore_bucket}"
    restore_file = "${var.restore_file}"
    registry = "${var.registry}"
    ingress = "${var.ingress_controller}"
  }

  metadata_startup_script =  "${file("${path.module}/${var.script_install}")}"


  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = "${var.k3s_service_account}@${var.project_id}.iam.gserviceaccount.com"
    scopes = var.k3s_scopes
  }
}



# resource "google_dns_record_set" "kube_api" {
#   name = "${var.server_name}.${var.dns_name}"
#   type = "A"
#   ttl  = 300
# 
#   managed_zone = "${var.dns_zone_name}"
# 
#   rrdatas = [google_compute_instance.k3s_main.network_interface[0].network_ip]
# }
