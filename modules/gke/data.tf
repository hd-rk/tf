data "google_container_engine_versions" "default" {
  location = local.regional ? var.region : var.zone
}
