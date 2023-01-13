resource "google_compute_instance_template" "agent_cpu_tpl" {
  name        = "${var.tpl_name}"
  description = "${var.tpl_description}"

  tags = var.network_tags

  labels = {
    env = "${var.label_env}"
    cluster = "${var.cluster_name}"
    spot = "${var.spot_instance}"
  }

  instance_description = "k3s cpu agent"
  machine_type         = "${var.cpu_machine_type}"
  can_ip_forward       = true

  scheduling {
    preemptible = var.spot_instance
    automatic_restart   = var.spot_instance ? false : true
    on_host_maintenance = var.spot_instance ? "TERMINATE" : "MIGRATE"
  }

  // Create a new boot disk from an image
  disk {
    source_image      = "${var.cpu_boot_image}"
    auto_delete       = true
    boot              = true
    disk_type = "${var.cpu_boot_type}"
    disk_size_gb =  "${var.cpu_boot_size}"

    // backup the disk every day
    // resource_policies = [google_compute_resource_policy.daily_backup.id]
  }


  # This prevent disk attachment loop when disk are provisioned using the CSI driver
  # https://github.com/hashicorp/terraform-provider-google/issues/2098
  lifecycle {
  	 ignore_changes = ["attached_disk"]
  }
  network_interface {
    network = "${var.network_name}"
    access_config {
    }
  }

  metadata = {
    project = "${var.project_id}"
    pool = "${var.label_pool_name}"
    clustername = "${var.cluster_name}"
    version = "${var.k3s_version}"
    server = "${var.k3s_url}"
    bucket = "${var.bucket}"
    registry = "${var.registry}"
    # ssh-keys = "${var.operator_user}:${file(var.public_key_path)}"
  }

  metadata_startup_script =  "${file("${path.module}/${var.script_install}")}"

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = "${var.k3s_service_account}@${var.project_id}.iam.gserviceaccount.com"
    scopes = var.k3s_scopes
  }
}
