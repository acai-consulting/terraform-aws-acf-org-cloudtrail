variable "cloudwatch_loggroup" {
  description = "Configuration settings for CloudWatch LogGroup."
  type = object({
    loggroup_name = optional(string, "org-cloudtrail-logs")
    iam_role_name = optional(string, "cloudtrail-role")
    iam_role_path = optional(string, "/")
  })
  default = null
}

variable "s3_bucket" {
  description = "Configuration settings for core logging."
  type = object({
    bucket_name        = optional(string, null)
    bucket_name_prefix = optional(string, null)
    notification_to_sns = optional(object({
      sns_name = optional(string, "org-cloudtrail-bucket-notification")
    }), null)
  })

  validation {
    condition     = (var.s3_bucket.bucket_name == null ? var.s3_bucket.bucket_name_prefix != null : var.s3_bucket.bucket_name_prefix == null)
    error_message = "Either bucket_name or bucket_name_prefix must be provided, but not both."
  }

  validation {
    condition = alltrue([
      var.s3_bucket.bucket_name == null ? true : length(regexall("^[a-zA-Z0-9-]+$", var.s3_bucket.bucket_name)) > 0,
      var.s3_bucket.bucket_name_prefix == null ? true : length(regexall("^[a-zA-Z0-9-]+$", var.s3_bucket.bucket_name_prefix)) > 0
    ])
    error_message = "Both bucket_name and bucket_name_prefix must only contain alphanumeric characters and hyphens, if provided."
  }
}
