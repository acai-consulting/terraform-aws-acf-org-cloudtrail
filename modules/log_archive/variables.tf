variable "s3_bucket" {
  description = "Configuration settings for core logging."
  type = object({
    bucket_name         = string
    bucket_name_prefix  = string
    days_to_glacier     = number
    days_to_expiration  = number
    bucket_access_s3_id = string
    force_destroy       = bool
    policy = object({
      reader_principal_arns = list(string)
      access_to_org         = bool
    })
    notification_to_sns = optional(object({
      sns_name            = optional(string, "org-cloudtrail-bucket-notification")
      allowed_subscribers = list(string)
    }), null)
  })
}

variable "org_mgmt_account_id" {
  type = string
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ COMMON
# ---------------------------------------------------------------------------------------------------------------------
variable "resource_tags" {
  description = "A map of tags to assign to the resources in this module."
  type        = map(string)
}
