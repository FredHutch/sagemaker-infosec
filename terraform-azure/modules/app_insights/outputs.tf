output "app_insights_id" {
  value = azurerm_application_insights.app_insights.id
}

output "instrumentation_key" {
  value     = azurerm_application_insights.app_insights.instrumentation_key
  sensitive = true
}
