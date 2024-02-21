
variable "s3_bucket" {
  description = "Configuration settings for core logging."
  type = object({
    enabled     = optional(string, "foundation-cloudtrail-role") // without prefix
    iam_role_name     = optional(string, "foundation-cloudtrail-role") // without prefix
    retention_in_days = optional(number, 3)
    monitoring = optional(object({
      inbound_iam_role_name = optional(string, null)
      destination_arn   = optional(string, null)
    }), null)
  })
  default = null



  # Add any additional validations as needed
}

output "result" {
  value = var.s3_bucket
}
