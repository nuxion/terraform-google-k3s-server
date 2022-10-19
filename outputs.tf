output "server_private_ip" {
  value = google_compute_instance.k3s_main.network_interface[0].network_ip
}

output "server_public_ip" {
  value = google_compute_instance.k3s_main.network_interface.0.access_config.0.nat_ip
}

output "server_name" {
  value = google_compute_instance.k3s_main.name
}
