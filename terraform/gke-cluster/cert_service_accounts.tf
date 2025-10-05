# Service Account for cert-manager DNS-01 solver
resource "google_service_account" "cert_manager_dns01" {
  account_id   = "cert-manager-dns01"
  display_name = "Cert-Manager DNS01 Solver"
}

# Grant Cloud DNS admin on the project (needed for DNS-01 TXT records)
resource "google_project_iam_member" "cert_manager_dns_admin" {
  project = var.project_id
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.cert_manager_dns01.email}"
}
