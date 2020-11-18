data "google_compute_subnetwork" "mlisa_subnet" {
  name   = var.subnet
  region = var.region
  project = var.project
}

resource "google_compute_firewall" "mlisa_dpc_allow_gke" {
  name    = "dpc-${var.deployment_name}-allow-gke-${random_string.mlisa_dpc_id.result}"
  project = var.project
  network = var.network
  description = <<EOF
Accept connections for all ports to Dataproc from k8s pods.
Nodes with 'targetTags' (i.e., all Dataproc nodes) will accept connections
for all ports from given source IPranges, which is essential to whitelist
connections made by k8s pods (e.g., Druid to Dataproc, ETL to Dataproc)
EOF
  direction = "INGRESS"
  priority = 1000
  allow {
    protocol = "tcp"
    ports    = ["1-65535"]
  }
  source_ranges = var.ingress_source_cidr_ranges
  target_tags = google_dataproc_cluster.mlisa.cluster_config[0].gce_cluster_config[0].tags
}

resource "google_compute_firewall" "mlisa_dpc_allow_vms" {
  name    = "dpc-${var.deployment_name}-allow-vms-${random_string.mlisa_dpc_id.result}"
  project = var.project
  network = var.network
  description = "Accept internal connections among Dataproc VMs"
  direction = "INGRESS"
  priority = 1000
  allow {
    protocol = "tcp"
    ports    = ["1-65535"]
  }
  source_ranges = [data.google_compute_subnetwork.mlisa_subnet.ip_cidr_range]
  target_tags = google_dataproc_cluster.mlisa.cluster_config[0].gce_cluster_config[0].tags
}
