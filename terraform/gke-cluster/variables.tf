variable "project_id" {
  description = "Your GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the cluster"
  type        = string
  default     = "europe-west2"
}

variable "master_auth_cidr" {
  description = "Your public IP address in CIDR notation (e.g., 80.1.2.3/32)."
  type        = string
}