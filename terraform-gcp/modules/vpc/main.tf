resource "google_compute_network" "vpc" {
  name                    = "vpc-${var.environment}-infosec-ml"
  auto_create_subnetworks = false
  project                 = var.project_id
}

resource "google_compute_subnetwork" "ml_subnet" {
  name          = "subnet-${var.environment}-ml"
  ip_cidr_range = "10.2.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.project_id

  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Cloud NAT for outbound connectivity
resource "google_compute_router" "router" {
  name    = "router-${var.environment}-ml"
  region  = var.region
  network = google_compute_network.vpc.id
  project = var.project_id
}

resource "google_compute_router_nat" "nat" {
  name                               = "nat-${var.environment}-ml"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  project                            = var.project_id

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall rules
resource "google_compute_firewall" "allow_internal" {
  name    = "fw-${var.environment}-allow-internal"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.2.0.0/24"]
}

resource "google_compute_firewall" "allow_ssh_iap" {
  name    = "fw-${var.environment}-allow-ssh-iap"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IAP source range
  source_ranges = ["35.235.240.0/20"]
}

# VPC Connector for serverless access
resource "google_vpc_access_connector" "connector" {
  name          = "vpc-connector-${var.environment}"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.2.1.0/28"
  project       = var.project_id
}
