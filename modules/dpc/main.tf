terraform {
  required_version = "~>0.13.4"
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~>3.46.0"
    }
    random = {
      source = "hashicorp/random"
      version = "~>3.0.0"
    }
  }
}
