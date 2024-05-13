resource "google_compute_instance" "ubisoft-userdata-migration-vm" {
  name         = "ubisoft-userdata-migration-vm"
  machine_type = "e2-medium"
  zone         = "europe-west9-a"
   metadata = {
    startup-script = "    #!/bin/bash\n    apt-get update\n    apt-get install -y apache2\n    cat <<EOT > /var/www/html/index.html\n    <html>\n      <head>\n        <title>Welcome to My Homepage</title>\n      </head>\n      <body>\n        <h1>Welcome to My Homepage!</h1>\n        <p>This page is served by Apache on a Google Compute Engine VM instance.</p>\n      </body>\n    </html>"
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network    = google_compute_network.ubisoft-hq-vpc.id
    subnetwork = google_compute_subnetwork.ubisoft-hq-subnet.id

    access_config {
      // Ephemeral IP
    }
  }
}
