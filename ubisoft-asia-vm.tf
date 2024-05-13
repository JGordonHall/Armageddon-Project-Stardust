resource "google_compute_instance" "ubisoft-asia-vm" {
  project      = "project-stardust-422621"
  name         = "ubisoft-tokyo-vm"
  machine_type = "n2-standard-4"
  zone         = "asia-northeast1-a"
  

 boot_disk {
    auto_delete = true
    initialize_params {
      image = "projects/windows-cloud/global/images/windows-server-2022-dc-v20240415"
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
    subnetwork = google_compute_subnetwork.ubi-tokyo-subnet.id
    access_config {
      // Ephemeral IP
    }
  }
}