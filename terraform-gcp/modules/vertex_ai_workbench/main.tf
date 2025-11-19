resource "google_workbench_instance" "instance" {
  name     = "workbench-${var.environment}-infosec"
  location = var.zone
  project  = var.project_id

  gce_setup {
    machine_type = var.machine_type

    boot_disk {
      disk_size_gb = var.boot_disk_size_gb
      disk_type    = "PD_SSD"
    }

    data_disks {
      disk_size_gb = 100
      disk_type    = "PD_STANDARD"
    }

    network_interfaces {
      network = var.network_id
      subnet  = var.subnet_id
    }

    metadata = {
      notebook-disable-root = "true"
      proxy-mode            = "mail"
    }

    dynamic "accelerator_configs" {
      for_each = var.enable_gpu ? [1] : []
      content {
        type       = var.gpu_type
        core_count = var.gpu_count
      }
    }

    disable_public_ip = true
  }

  labels = {
    environment = var.environment
    purpose     = "security-ml"
  }
}

# Install startup script
resource "google_storage_bucket_object" "startup_script" {
  name    = "scripts/workbench-startup.sh"
  bucket  = "${var.project_id}-scripts"
  content = templatefile("${path.module}/scripts/startup.sh", {
    project_id  = var.project_id
    environment = var.environment
  })
}
