# You must complete the following scenerio.

# A European gaming company is moving to GCP.  It has the following requirements in it's first stage migration to the Cloud:

# A) You must choose a region in Europe to host it's prototype gaming information.  This page must only be on a RFC 1918 Private 10 net and can't be accessible from the Internet.
# B) The Americas must have 2 regions and both must be RFC 1918 172.16 based subnets.  They can peer with HQ in order to view the homepage however, they can only view the page on port 80.
# C) Asia Pacific region must be choosen and it must be a RFC 1918 192.168 based subnet.  This subnet can only VPN into HQ.  Additionally, only port 3389 is open to Asia. No 80, no 22.

# Deliverables.
# 1) Complete Terraform for the entire solution.
# 2) Git Push of the solution to your GitHub.
# 3) Screenshots showing how the HQ homepage was accessed from both the Americas and Asia Pacific. 

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "5.27.0"
    }
  }
}

provider "google" {
  project = "project-stardust-422621"
  region = "europe-west9"
  zone = "europe-west9-a"
  credentials = "project-stardust-422621-b67268d0f8ff.json"
}

resource "google_compute_network" "ubisoft-hq-vpc" {
  project                 = "project-stardust-422621"
  name                    = "ubisoft-hq-vpc"
  auto_create_subnetworks = false
  mtu                     = 1460
}
resource "google_compute_subnetwork" "ubisoft-hq-subnet" {
  project                  = "project-stardust-422621"
  name                     = "ubisoft-hq-subnet-a"
  region                   = "europe-west9"
  ip_cidr_range            = "10.88.0.0/24"
  network                  = google_compute_network.ubisoft-hq-vpc.id
}


resource "google_compute_network" "ubisoft-userdata-vpc" {
  project                 = "project-stardust-422621"
  name                    = "ubisoft-userdata-vpc"
  auto_create_subnetworks = false
  mtu                     = 1460
}

resource "google_compute_subnetwork" "ubi-montreal-subnet-a" {
  project                  = "project-stardust-422621"
  name                     = "ubi-montreal-subnet-a"
  region                   = "northamerica-northeast1"
  ip_cidr_range            = "172.20.50.0/24"
  network                  = google_compute_network.ubisoft-userdata-vpc.id
}

resource "google_compute_subnetwork" "ubi-saopaulo-subnet-b" {
  project                  = "project-stardust-422621"
  name                     = "ubi-saopaulo-subnet-b"
  region                   = "southamerica-east1"
  ip_cidr_range            = "172.31.80.0/24"  
  network                  = google_compute_network.ubisoft-userdata-vpc.id
}

resource "google_compute_subnetwork" "ubi-tokyo-subnet" {
  project                  = "project-stardust-422621"
  name                     = "ubi-tokyo-subnet"
  region                   = "asia-northeast1"
  ip_cidr_range            = "192.168.80.0/24"
  network                  = google_compute_network.ubisoft-userdata-vpc.id
}

resource "google_compute_firewall" "ubisoft-userdata-vpc_custom_rule" {
  network = google_compute_network.ubisoft-userdata-vpc.name
  name    = "ubisoft-userdata-vpc-custom"
  priority = 65534
  source_ranges = ["172.20.50.0/24", "172.31.80.0/24", "192.168.80.0/24"]
  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "ubisoft-userdata-vpc_ssh_rule" {
  network = google_compute_network.ubisoft-userdata-vpc.name
  name    = "ubisoft-userdata-vpc-ssh"
  priority = 65534
  source_ranges = ["0.0.0.0/0"]
  destination_ranges = [ "172.20.50.0/24", "172.31.80.0/24" ]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "ubisoft-userdata-vpc_icmp_rule" {
  name    = "ubisoft-userdata-vpc-icmp"
  network = google_compute_network.ubisoft-userdata-vpc.name
  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
  priority = 65534
}

resource "google_compute_firewall" "ubisoft-userdata-vpc-rdp-rule" {
  name    = "ubisoft-userdata-vpc-rdp"
  network = google_compute_network.ubisoft-userdata-vpc.name
  allow {
    protocol = "tcp"
    ports = ["3389"]
  }

  source_ranges = ["0.0.0.0/0"]
  priority = 65534
}

resource "google_compute_firewall" "ubisoft-hq-vpc-http-rule" {
  project     = "project-stardust-422621"
  name        = "ubisoft-hq-vpc-firewall-http"
  network     = google_compute_network.ubisoft-hq-vpc.id
  allow {
    protocol = "tcp"
    ports = ["80"]
  }
  source_ranges = ["172.20.50.0/24", "172.31.80.0/24", "192.168.80.0/24"]
  priority = 100
}
resource "google_compute_firewall" "ubisoft-hq-vpc-icmp-rule" {
  project     = "project-stardust-422621"
  name        = "ubisoft-hq-vpc-firewall-icmp"
  network     = google_compute_network.ubisoft-hq-vpc.id
  allow {
    protocol = "icmp"
  }
  source_ranges = ["0.0.0.0/0"]
  priority = 65534
}

resource "google_compute_network_peering" "ubi-us-2-eu" {
  name         = "ubi-us-2-eu"
  network      = google_compute_network.ubisoft-userdata-vpc.id
  peer_network = google_compute_network.ubisoft-hq-vpc.id
}

resource "google_compute_network_peering" "europe-americas" {
  name         = "ubi-eu-2-us"
  network      = google_compute_network.ubisoft-hq-vpc.id
  peer_network = google_compute_network.ubisoft-userdata-vpc.id
}



resource "google_compute_vpn_gateway" "asia-2-eu-gateway" {
  name    = "asia-2-eu-gateway"
  region  = "asia-northeast1"
  network = google_compute_network.ubisoft-userdata-vpc.id
}

resource "google_compute_address" "vpn-static-ip-to-europe" {
  name = "vpn-static-ip-2-eu"
  region = "asia-northeast1"
}

resource "google_compute_vpn_tunnel" "asia-to-europe-tunnel" {
  name          = "asia-to-europe-tunnel"
  peer_ip       =  google_compute_address.vpn-static-ip-to-asia.address
  shared_secret = "0-pin-sesame"
  local_traffic_selector = [google_compute_subnetwork.ubi-tokyo-subnet.ip_cidr_range]
  remote_traffic_selector = [google_compute_subnetwork.ubisoft-hq-subnet.ip_cidr_range]
  target_vpn_gateway = google_compute_vpn_gateway.asia-2-eu-gateway.id

  depends_on = [
    google_compute_forwarding_rule.asia-esp-fw,
    google_compute_forwarding_rule.asia-udp500-fw,
    google_compute_forwarding_rule.asia-udp4500-fw,
  ]

}


resource "google_compute_forwarding_rule" "asia-esp-fw" {
  name        = "asia-esp-fw"
  ip_protocol = "ESP"
  ip_address  = google_compute_address.vpn-static-ip-to-europe.address
  target      = google_compute_vpn_gateway.asia-2-eu-gateway.id
  region      = "asia-northeast1"
}

resource "google_compute_forwarding_rule" "asia-udp500-fw" {
  name        = "asia-udp500-fw"
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = google_compute_address.vpn-static-ip-to-europe.address
  target      = google_compute_vpn_gateway.asia-2-eu-gateway.id
  region      = "asia-northeast1"
}

resource "google_compute_forwarding_rule" "asia-udp4500-fw" {
  name        = "asia-udp4500-fw"
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = google_compute_address.vpn-static-ip-to-europe.address
  target      = google_compute_vpn_gateway.asia-2-eu-gateway.id
  region      = "asia-northeast1"
}


resource "google_compute_vpn_gateway" "eu-2-as-gateway" {
  name    = "eu-2-as-gateway"
  region  = "europe-west9"
  network = google_compute_network.ubisoft-hq-vpc.id
}

resource "google_compute_address" "vpn-static-ip-to-asia" {
  name = "vpn-static-ip-to-asia"
  region = "europe-west9"
}

resource "google_compute_vpn_tunnel" "europe-to-asia-tunnel" {
  name          = "eur-to-asia-tunnel"
  peer_ip       = google_compute_address.vpn-static-ip-to-europe.address
  shared_secret = "0-pin-sesame"
  local_traffic_selector = [google_compute_subnetwork.ubisoft-hq-subnet.ip_cidr_range]
  remote_traffic_selector = [google_compute_subnetwork.ubi-tokyo-subnet.ip_cidr_range]
  target_vpn_gateway = google_compute_vpn_gateway.eu-2-as-gateway.id

  depends_on = [
    google_compute_forwarding_rule.europe-esp-fw,
    google_compute_forwarding_rule.europe-udp500-fw,
    google_compute_forwarding_rule.europe-udp4500-fw
  ]

}


resource "google_compute_forwarding_rule" "europe-esp-fw" {
  name        = "europe-esp-fw"
  ip_protocol = "ESP"
  ip_address  = google_compute_address.vpn-static-ip-to-asia.address
  target      = google_compute_vpn_gateway.eu-2-as-gateway.id
  region      = "europe-west9"
}

resource "google_compute_forwarding_rule" "europe-udp500-fw" {
  name        = "europe-udp500-fw"
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = google_compute_address.vpn-static-ip-to-asia.address
  target      = google_compute_vpn_gateway.eu-2-as-gateway.id
  region      = "europe-west9"
}

resource "google_compute_forwarding_rule" "europe-udp4500-fw" {
  name        = "europe-udp4500-fw"
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = google_compute_address.vpn-static-ip-to-asia.address
  target      = google_compute_vpn_gateway.eu-2-as-gateway.id
  region      = "europe-west9"
}

