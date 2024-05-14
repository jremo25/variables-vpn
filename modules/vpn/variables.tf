variable "vpn_gateway_name" {
  type = string
}

variable "network_id" {
  type = string
}

variable "region" {
  type = string
}

variable "vpn_ip_name" {
  type = string
}

variable "vpn_tunnel_name" {
  type = string
}

variable "peer_ip" {
  type = string
}

variable "shared_secret" {
  type = string
}

variable "local_traffic_selector" {
  type = list(string)
}

variable "remote_traffic_selector" {
  type = list(string)
}

variable "vpn_route_name" {
  type = string
}
