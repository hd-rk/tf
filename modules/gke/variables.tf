variable "deployment_name" {}
variable "project" {}
variable "region" {}
variable "zone" {}

variable "network" {}
variable "subnet" {}

variable "deployment_config_id" {}

variable "enable_monitoring" {
  type = bool
  default = true
}

variable "regional" {
  type = bool
  default = false
}

variable "max_pods_per_node" {
  type = number
  default = 110
}

variable "pod_secondary_range_name" {
  type = string
  default = ""
}

variable "svc_secondary_range_name" {
  type = string
  default = ""
}

variable "master_auth_networks" {
  type = string
  default = "all:0.0.0.0/0"
}

variable "oauth_scopes" {
  type = set(string)
  default = [
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/devstorage.read_write",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring",
    "https://www.googleapis.com/auth/pubsub",
    "https://www.googleapis.com/auth/cloud-platform"
  ]
}

variable "private" {
  type = object({
    enabled = bool
    master_private_endpoint = bool
    master_range_cidr = string
  })
  default = {
    enabled = false
    master_private_endpoint = false
    master_range_cidr = ""
  }
}

variable "node_pools" {
  type = list(object({
    name = string
    node_count = number
    machine_type = string
    labels = map(string)
    tags = list(string)
  }))
  default = []
}

variable "node_management" {
  type = object({
    auto_repair = bool
    auto_upgrade = bool
  })
  default = {
    auto_repair = false
    auto_upgrade = false
  }
}
