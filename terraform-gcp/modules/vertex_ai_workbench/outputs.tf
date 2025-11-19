output "instance_name" {
  value = google_workbench_instance.instance.name
}

output "proxy_uri" {
  value = google_workbench_instance.instance.gce_setup[0].service_account
}
