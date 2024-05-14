terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "inner-replica-417201"
}

resource "google_compute_network" "europe_network" {
  name                    = var.config.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "europe_subnet" {
  name                     = var.config.subnet_name
  network                  = google_compute_network.europe_network.id
  ip_cidr_range            = var.config.subnet_cidr
  region                   = var.config.region
  private_ip_google_access = true
}

resource "google_compute_firewall" "europe_http" {
  name    = "europe-http"
  network = google_compute_network.europe_network.id

  allow {
    protocol = "tcp"
    ports    = var.config.allowed_ports
  }

  source_ranges = var.config.ip_cidr_ranges
  target_tags   = var.config.tags
}

resource "google_compute_instance" "europe_vm" {
  depends_on   = [google_compute_subnetwork.europe_subnet]
  name         = var.config.vm_name
  machine_type = "e2-medium"
  zone         = var.config.zone

  boot_disk {
    initialize_params {
      image = var.config.image_family
    }
  }

  network_interface {
    network    = google_compute_network.europe_network.id
    subnetwork = google_compute_subnetwork.europe_subnet.id
    access_config {
      // Not assigned a public IP
    }
  }
 
  metadata = {
    startup-script = file("${path.module}/startup-script.sh")
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  tags = var.config.tags
}

module "europe_vpn" {
  source = "../vpn"

  vpn_gateway_name        = "europe-vpn-gateway"
  network_id              = google_compute_network.europe_network.id
  region                  = var.config.region
  vpn_ip_name             = "europe-vpn-ip"
  vpn_tunnel_name         = "europe-to-asia-tunnel"
  peer_ip                 = var.peer_ip
  shared_secret           = var.vpn_shared_secret
  local_traffic_selector  = var.local_traffic_selector
  remote_traffic_selector = var.remote_traffic_selector
  vpn_route_name          = "europe-to-asia-route"
}

output "network_id" {
  value = google_compute_network.europe_network.id
}

output "europe_vpn_ip_address" {
  value = module.europe_vpn.vpn_ip_address
}

output "europe_vm_internal_ip" {
  description = "Internal IP address of the Europe VM"
  value       = google_compute_instance.europe_vm.network_interface[0].network_ip
}
