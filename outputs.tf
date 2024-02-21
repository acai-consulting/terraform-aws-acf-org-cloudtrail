
output "core_parameter_to_write" {
  description = "This must be in sync with the Account Baselining"
  value = {
    "security.org_cloudtrail" = {
      cloudtrail_admin = {
        org_cloudtrail_name = var.org_cloudtrail_name
        cloudwatch_loggroup_name = var.org_cloudtrail_name
      }
      cloudtrail_bucket = module.log_archive_bucket
    }
  }
}
