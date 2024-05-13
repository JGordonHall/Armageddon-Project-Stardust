resource "google_compute_instance" "ubisoft-americas-vm-south" {
  project      = "project-stardust-422621"
  name         = "ubisoft-americas-vm-south"
  machine_type = "n2-standard-4"
  zone         = "southamerica-east1-a"
 

  boot_disk {
    auto_delete = true
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 120
      type  = "pd-balanced"
    }
     mode = "READ_WRITE"
  }
     labels= {
        goog-ec-src = "vm_add-tf"
     }

  network_interface {
    network = google_compute_network.ubisoft-userdata-vpc.id
    subnetwork = google_compute_subnetwork.ubi-saopaulo-subnet-b.id
    access_config {
      // Ephemeral IP
    }
  }
}