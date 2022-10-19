resource "google_compute_instance" "k3s_main" {
  name        = "${var.server_name}"
  description = "K3s main node provisioning"

  tags = var.network_tags

  labels = {
    env = "${var.label_env}"
    cluster = "${var.cluster_name}"
  }

  machine_type         = "${var.server_machine_type}"
  zone = "${var.k3s_zone}"
  can_ip_forward       = true 

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  // Create a new boot disk from an image
  boot_disk {
    # source_image      = "debian-cloud/debian-11"
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
    network = "${var.k3s_network}"
    access_config { # add temporal public ip
      # Ephemeral
      # nat_ip = google_compute_address.core_external_ip.address
    }
  }

  metadata = {
    project = "${var.project}"
    clustername = "${var.cluster_name}"
    version = "${var.k3s_version}"
    csidisk = "${var.k3s_csidisk}"
    location = "${var.k3s_location}"
    dnsname = "${var.server_name}.${var.dns_name}"
  }

  metadata_startup_script =  "${file("${var.base_path}/scripts/google/k3s_install.sh")}"


  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = "${var.k3s_service_account}@${var.project}.iam.gserviceaccount.com"
    scopes = var.k3s_scopes
  }
}

resource "google_dns_record_set" "kube_api" {
  name = "${var.server_name}.${var.dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = "${var.dns_zone_name}"

  rrdatas = [google_compute_instance.k3s_main.network_interface[0].network_ip]
}
