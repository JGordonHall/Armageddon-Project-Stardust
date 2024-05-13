# Create a Google VPC 
resource "google_compute_network" "imperial-access-codes-network" {
  project                 = var.project_id
  name                    = var.network_name
  auto_create_subnetworks = false
  mtu                     = 1460
}

# add subnet to the VPC
resource "google_compute_subnetwork" "coreworld-subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.ip_cidr_range
  region        = var.region
  network       = google_compute_network.imperial-access-codes-network.id
}

# firewall rule to allow traffic on port 80
resource "google_compute_firewall" "rules" {
  name    = var.firewall_name
  network = google_compute_network.imperial-access-codes-network.id

  allow {
    protocol = "tcp"
    ports    = var.ports
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = var.source_ranges
  priority      = 1000
}

output "vpc" {
  value = google_compute_network.imperial-access-codes-network.id
  description = "value of the VPC ID"
}

output "instance_public_ip" {
  value = google_compute_instance.ds-1-obs-vm.network_interface[0].access_config[0].nat_ip
  description = "The public IP address of the instance"
}

output "vm_subnet" {
  value = google_compute_instance.ds-1-obs-vm.network_interface.0.subnetwork
  description = "The subnet of the instance"
}

output "instance_internal_ip" {
  value = google_compute_instance.ds-1-obs-vm.network_interface.0.network_ip
  description = "The internal IP address of the instance"
}
