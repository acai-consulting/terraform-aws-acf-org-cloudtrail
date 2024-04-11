# ---------------------------------------------------------------------------------------------------------------------
# ¦ ORG MANAGEMENT
# ---------------------------------------------------------------------------------------------------------------------
variable "org_cloudtrail_name" {
  description = "Name of the Organization CloudTrail."
  type        = string
}

variable "cloudwatch_loggroup" {
  description = "Configuration settings for CloudWatch LogGroup."
  type = object({
    loggroup_name     = optional(string, "org-cloudtrail-logs")
    iam_role_name     = optional(string, "cloudtrail-role")
    iam_role_path     = optional(string, "/")
    iam_role_pb       = optional(string, null)
    retention_in_days = optional(number, 3)
    monitoring = optional(object({
      inbound_iam_role_name = optional(string, null)
      destination_arn       = optional(string, null)
    }), null)
  })
  default = null

  validation {
    condition = var.cloudwatch_loggroup == null ? true : (
      contains(
        [1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.cloudwatch_loggroup.retention_in_days
    ))
    error_message = "The CloudWatch Logs retention period must be a Fibonacci number and supported by AWS (1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, or 3653 days)."
  }

  validation {
    condition = var.cloudwatch_loggroup == null ? true : (
      var.cloudwatch_loggroup.monitoring == null ? true : (
        (var.cloudwatch_loggroup.monitoring.destination_arn == null ? true :
    can(regex("^arn:aws:logs:", var.cloudwatch_loggroup.monitoring.destination_arn)))))
    error_message = "If monitoring is specified, destination_arn must contain ARN, starting with 'arn:aws:logs:'."
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE LOGGING
# ---------------------------------------------------------------------------------------------------------------------
variable "s3_bucket" {
  description = "Configuration settings for core logging."
  type = object({
    bucket_name         = string
    days_to_glacier     = optional(number, -1)
    days_to_expiration  = number
    bucket_access_s3_id = optional(string, null)
    force_destroy       = optional(bool, false) # true - for testing only
    policy = optional(object({
      reader_principal_arns = optional(list(string), [])
      access_to_org         = optional(bool, false)
      }), {
      reader_principal_arns = []
      access_to_org         = false
    })
    notification_to_sns = optional(object({
      sns_name            = optional(string, "org-cloudtrail-bucket-notification")
      allowed_subscribers = list(string)
    }), null)
  })

  validation {
    condition     = length(regexall("^[a-zA-Z0-9-]+$", var.s3_bucket.bucket_name)) > 0
    error_message = "Both bucket_name and bucket_name_prefix must only contain alphanumeric characters and hyphens, if provided."
  }

  validation {
    condition     = var.s3_bucket.days_to_glacier >= -1
    error_message = "The s3_days_to_glacier must be -1 or a positive integer."
  }

  validation {
    condition     = var.s3_bucket.days_to_expiration >= -1
    error_message = "The s3_days_to_expiration must be -1 or a positive integer."
  }
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ COMMON
# ---------------------------------------------------------------------------------------------------------------------
variable "resource_tags" {
  description = "A map of tags to assign to the resources in this module."
  type        = map(string)
  default     = {}
}
