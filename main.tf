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

data "google_secret_manager_secret_version" "vpn_secret" {
  secret  = "vpn-shared-secret"
  version = "latest"
}

module "america" {
  source = "./modules/america"

  americas_network_config = {
    network_name        = "americas-network"
    auto_create_subnets = false
    subnet_configs = {
      "americas-subnet1" = {
        name              = "americas-subnet1"
        cidr              = "172.16.20.0/24"
        region            = "us-west1"
        private_ip_access = true
      },
      "americas-subnet2" = {
        name              = "americas-subnet2"
        cidr              = "172.16.21.0/24"
        region            = "us-east1"
        private_ip_access = true
      }
    }
    vm_details = [
      {
        name         = "america-vm1"
        machine_type = "e2-medium"
        zone         = "us-west1-a"
        image_family = "projects/debian-cloud/global/images/family/debian-11"
        subnet_name  = "americas-subnet1"
        tags         = ["america-http-server", "iap-ssh-allowed"]
      },
      {
        name         = "america-vm2"
        machine_type = "n2-standard-4"
        zone         = "us-east1-b"
        image_family = "projects/windows-cloud/global/images/windows-server-2022-dc-v20240415"
        subnet_name  = "americas-subnet2"
        tags         = ["america-http-server"]
      }
    ]
    firewall = {
      name            = "america-to-europe-http"
      protocols_ports = {
        tcp = ["80", "22", "3389"]
      }
      source_ranges   = ["0.0.0.0/0", "35.235.240.0/20"]
      target_tags     = ["america-http-server", "iap-ssh-allowed"]
    }
  }
}

module "europe" {
  source = "./modules/europe"

  config = {
    region         = "europe-west1"
    zone           = "europe-west1-b"
    network_name   = "europe-network"
    subnet_name    = "europe-subnet"
    subnet_cidr    = "10.150.11.0/24"
    vm_name        = "europe-vm"
    image_family   = "projects/debian-cloud/global/images/family/debian-11"
    ip_cidr_ranges = ["10.150.11.0/24", "172.16.20.0/24", "172.16.21.0/24", "192.168.11.0/24"]
    allowed_ports  = ["80"]
    tags           = ["europe-http-server"]
  }

  peer_ip                 = module.asia.asia_vpn_ip_address
  vpn_shared_secret       = data.google_secret_manager_secret_version.vpn_secret.secret_data
  local_traffic_selector  = ["10.150.11.0/24"]
  remote_traffic_selector = ["192.168.11.0/24"]
}

module "asia" {
  source = "./modules/asia"

  asia_network_config = {
    network_name             = "asia-network"
    auto_create_subnetworks  = false
    subnet_name              = "asia-subnet"
    subnet_cidr              = "192.168.11.0/24"
    region                   = "asia-northeast1"
    private_ip_google_access = true
    firewall = {
      name          = "asia-allow-rdp"
      ports         = ["3389"]
      source_ranges = ["0.0.0.0/0"]
      target_tags   = ["asia-rdp-server"]
    }
  }

  asia_vm_config = {
    name         = "asia-vm"
    machine_type = "n2-standard-4"
    zone         = "asia-northeast1-c"
    image_family = "projects/windows-cloud/global/images/windows-server-2022-dc-v20240415"
    tags         = ["asia-rdp-server"]
  }

  peer_ip                 = module.europe.europe_vpn_ip_address
  vpn_shared_secret       = data.google_secret_manager_secret_version.vpn_secret.secret_data
  local_traffic_selector  = ["192.168.11.0/24"]
  remote_traffic_selector = ["10.150.11.0/24"]
}

module "peering" {
  source = "./modules/peering"

  peering_config = {
    america_network_id = module.america.network_id
    europe_network_id  = module.europe.network_id
  }
}

output "europe_vpn_ip_address" {
  value = module.europe.europe_vpn_ip_address
}

output "asia_vpn_ip_address" {
  value = module.asia.asia_vpn_ip_address
}

output "europe_vm_internal_ip" {
  value = module.europe.europe_vm_internal_ip
}
