resource "google_monitoring_alert_policy" "workbench_cpu" {
  display_name = "Workbench High CPU - ${var.environment}"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "CPU utilization above 80%"

    condition_threshold {
      filter          = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/cpu/utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.notification_channels

  alert_strategy {
    auto_close = "1800s"
  }
}
