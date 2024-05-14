variable "asia_vm_config" {
  type = object({
    name         = string
    machine_type = string
    zone         = string
    image_family = string
    tags         = list(string)
  })
}

variable "peer_ip" {
  type = string
}

variable "vpn_shared_secret" {
  type = string
}

variable "local_traffic_selector" {
  type = list(string)
}

variable "remote_traffic_selector" {
  type = list(string)
}