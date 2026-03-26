terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "chas-tf-state-m4k-gang"
    prefix = "lab1/mattej-petrovic"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_instance" "vm" {
  name         = "${var.student_id}-lab1-vm"
  machine_type = "e2-micro"
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
      type  = "pd-balanced"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata_startup_script = file("startup.sh")

  labels = {
    student = var.student_id
    course  = "devsecops-2026"
    lab     = "1"
  }

  tags = ["lab1", "ssh"]
}

resource "google_compute_resource_policy" "daily_backup" {
  name   = "${var.student_id}-daily-backup"
  region = var.region

  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "03:00"
      }
    }
    retention_policy {
      max_retention_days    = 7
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }
  }
}

resource "google_compute_disk_resource_policy_attachment" "backup_attachment" {
  name = google_compute_resource_policy.daily_backup.name
  disk = google_compute_instance.vm.name
  zone = "${var.region}-a"
}