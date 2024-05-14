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

resource "google_compute_network" "asia_network" {
  name                    = var.asia_network_config.network_name
  auto_create_subnetworks = var.asia_network_config.auto_create_subnetworks
}

resource "google_compute_subnetwork" "asia_subnet" {
  name                     = var.asia_network_config.subnet_name
  network                  = google_compute_network.asia_network.id
  ip_cidr_range            = var.asia_network_config.subnet_cidr
  region                   = var.asia_network_config.region
  private_ip_google_access = var.asia_network_config.private_ip_google_access
}

resource "google_compute_firewall" "asia_allow_rdp" {
  name    = var.asia_network_config.firewall.name
  network = google_compute_network.asia_network.id

  allow {
    protocol = "tcp"
    ports    = var.asia_network_config.firewall.ports
  }

  source_ranges = var.asia_network_config.firewall.source_ranges
  target_tags   = var.asia_network_config.firewall.target_tags
}

resource "google_compute_instance" "asia_vm1" {
  depends_on   = [google_compute_subnetwork.asia_subnet]
  name         = var.asia_vm_config.name
  machine_type = var.asia_vm_config.machine_type
  zone         = var.asia_vm_config.zone

  boot_disk {
    initialize_params {
      image = var.asia_vm_config.image_family
    }
  }

  network_interface {
    network    = google_compute_network.asia_network.id
    subnetwork = google_compute_subnetwork.asia_subnet.id

    access_config {
      // Not assigned a public IP
    }
  }

  tags = var.asia_vm_config.tags
}

module "asia_vpn" {
  source = "../vpn"

  vpn_gateway_name        = "asia-vpn-gateway"
  network_id              = google_compute_network.asia_network.id
  region                  = var.asia_network_config.region
  vpn_ip_name             = "asia-vpn-ip"
  vpn_tunnel_name         = "asia-to-europe-tunnel"
  peer_ip                 = var.peer_ip
  shared_secret           = var.vpn_shared_secret
  local_traffic_selector  = var.local_traffic_selector
  remote_traffic_selector = var.remote_traffic_selector
  vpn_route_name          = "asia-to-europe-route"
}

output "network_id" {
  value = google_compute_network.asia_network.id
}

output "asia_vpn_ip_address" {
  value = module.asia_vpn.vpn_ip_address
}


