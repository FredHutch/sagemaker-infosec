variable "project_id" {
  type = string
}

variable "service_account_email" {
  type = string
}

variable "storage_bucket_names" {
  type = map(string)
}
