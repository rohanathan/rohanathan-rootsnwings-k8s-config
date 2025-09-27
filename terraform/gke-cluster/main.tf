
# --------- ENABLE REQUIRED APIs ----------
resource "google_project_service" "services" {
  for_each = toset([
    "container.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "artifactregistry.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com"
  ])
  project              = var.project_id
  service              = each.key
  disable_on_destroy = false
}

# --------- NETWORK (VPC + SUBNET with secondary ranges) ----------
resource "google_compute_network" "vpc" {
  name                    = "rnw-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "rnw-subnet-ew2"
  ip_cidr_range = "10.10.0.0/16"
  region        = var.region
  network       = google_compute_network.vpc.id

  secondary_ip_range {
    range_name    = "pods-range"
    ip_cidr_range = "10.20.0.0/14"
  }
  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "10.30.0.0/20"
  }
}

# --------- (RECOMMENDED) CUSTOM NODE SERVICE ACCOUNT ----------
resource "google_service_account" "gke_nodes" {
  account_id   = "gke-nodes-sa"
  display_name = "GKE Nodepool Service Account"
}

resource "google_project_iam_member" "gke_nodes_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_artifactreader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# --------- GKE CLUSTER ----------
resource "google_container_cluster" "gke" {
  name     = "rootsnwings-cluster"
  location = var.region
  deletion_protection      = false
  remove_default_node_pool = true
  initial_node_count       = 1
  network                  = google_compute_network.vpc.id
  subnetwork               = google_compute_subnetwork.subnet.id

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods-range"
    services_secondary_range_name = "services-range"
  }

  release_channel {
    channel = "REGULAR"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }
  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    managed_prometheus {
      enabled = true
    }
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.master_auth_cidr
      display_name = "admin-access"
    }
  }
  

  depends_on = [google_project_service.services]
}

# --------- SEPARATE NODE POOL ----------
resource "google_container_node_pool" "app_pool" {
  name     = "app-node-pool"
  location = var.region
  cluster  = google_container_cluster.gke.name

  autoscaling {
    min_node_count = 2
    max_node_count = 5
  }

  node_config {
    machine_type    = "e2-standard-4"
    disk_size_gb    = 100
    service_account = google_service_account.gke_nodes.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# Grant the GKE Node Service Account permission to pull images from Artifact Registry
resource "google_project_iam_member" "gke_nodes_artifact_puller" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}
# --------- OUTPUTS ----------
output "cluster_name" { value = google_container_cluster.gke.name }
output "cluster_region" { value = google_container_cluster.gke.location }