variable "s3_bucket" {
  description = "Configuration settings for core logging."
  type = object({
    bucket_name           = string
    bucket_name_prefix    = string
    days_to_glacier       = number
    days_to_expiration    = number
    bucket_access_s3_id   = string
    force_destroy         = bool
    reader_principal_arns = list(string)
  })
}

variable "org_mgmt_account_id" {
  type = string
}

variable "bucket_notification_to_sns" {
  type = object({
    sns_name            = optional(string, "org-cloudtrail-bucket-notification")
    allowed_subscribers = list(string)
  })
  default = null
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ COMMON
# ---------------------------------------------------------------------------------------------------------------------
variable "resource_tags" {
  description = "A map of tags to assign to the resources in this module."
  type        = map(string)
}
