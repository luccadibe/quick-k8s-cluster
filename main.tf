# Configure the Google Cloud provider
provider "google" {
  project = var.project_id
  region  = var.zone
}

# Variables
variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "zone" {
  description = "GCP zone"
  type        = string
}

variable "bucket_name" {
  description = "Name for the kOps state store bucket"
  type        = string
}

variable "bucket_location" {
  description = "Location for the GCS bucket"
  type        = string
}

# Create a GCS bucket for the kOps state store
resource "google_storage_bucket" "kops_state_store" {
  name          = var.bucket_name
  location      = var.bucket_location
  force_destroy = true

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 2
    }
  }
}

# Output the bucket name for reference
output "kops_state_store_bucket_name" {
  value = google_storage_bucket.kops_state_store.name
}

