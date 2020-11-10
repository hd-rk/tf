terraform {
  required_version = "~>0.13.4"
  required_providers {
    google = {
      source = "hashicorp/google"
      version = ">=3.46.0"
    }
  }
}

resource "google_runtimeconfig_config" "mlisa" {
  name = var.deployment_name
}
