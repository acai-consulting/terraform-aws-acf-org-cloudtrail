
output "core_configuration_to_write" {
  description = "This must be in sync with the Account Baselining"
  value = var.core_configuration_cluster_name == "" ? (
    local.core_configuration_to_write
    ) : (
    {
      "${var.core_configuration_cluster_name}" = local.core_configuration_to_write
    }
  )
}
