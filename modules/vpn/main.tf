resource "google_compute_vpn_gateway" "vpn_gateway" {
  name    = var.vpn_gateway_name
  network = var.network_id
  region  = var.region
}

resource "google_compute_address" "vpn_ip" {
  name   = var.vpn_ip_name
  region = var.region
}

resource "google_compute_vpn_tunnel" "vpn_tunnel" {
  name               = var.vpn_tunnel_name
  region             = var.region
  target_vpn_gateway = google_compute_vpn_gateway.vpn_gateway.id
  peer_ip            = var.peer_ip
  shared_secret      = var.shared_secret
  ike_version        = 2

  local_traffic_selector  = var.local_traffic_selector
  remote_traffic_selector = var.remote_traffic_selector

  depends_on = [
    google_compute_forwarding_rule.esp,
    google_compute_forwarding_rule.udp500,
    google_compute_forwarding_rule.udp4500
  ]
}

resource "google_compute_route" "vpn_route" {
  name                = var.vpn_route_name
  network             = var.network_id
  dest_range          = var.remote_traffic_selector[0]
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.vpn_tunnel.id
  priority            = 1000
}

resource "google_compute_forwarding_rule" "esp" {
  name        = "${var.vpn_gateway_name}-esp"
  region      = var.region
  ip_protocol = "ESP"
  ip_address  = google_compute_address.vpn_ip.address
  target      = google_compute_vpn_gateway.vpn_gateway.self_link
}

resource "google_compute_forwarding_rule" "udp500" {
  name        = "${var.vpn_gateway_name}-udp500"
  region      = var.region
  ip_protocol = "UDP"
  ip_address  = google_compute_address.vpn_ip.address
  port_range  = "500"
  target      = google_compute_vpn_gateway.vpn_gateway.self_link
}

resource "google_compute_forwarding_rule" "udp4500" {
  name        = "${var.vpn_gateway_name}-udp4500"
  region      = var.region
  ip_protocol = "UDP"
  ip_address  = google_compute_address.vpn_ip.address
  port_range  = "4500"
  target      = google_compute_vpn_gateway.vpn_gateway.self_link
}

output "vpn_ip_address" {
  value = google_compute_address.vpn_ip.address
}
