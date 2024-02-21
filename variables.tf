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
    enabled           = optional(string, "foundation-cloudtrail-role") // without prefix
    iam_role_name     = optional(string, "foundation-cloudtrail-role") // without prefix
    retention_in_days = optional(number, 3)
    monitoring = optional(object({
      inbound_iam_role_name = optional(string, null)
      destination_arn       = optional(string, null)
    }), null)
  })
  default = null

  validation {
    condition = contains(
      [1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cloudwatch_loggroup.retention_in_days
    )
    error_message = "The CloudWatch Logs retention period must be a Fibonacci number and supported by AWS (1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 120, 150, 180, 365, 400, 545, 731, 1827, or 3653 days)."
  }

  validation {
    condition = var.cloudwatch_loggroup.monitoring == null ? true : (
      (var.cloudwatch_loggroup.monitoring.destination_arn == null ? true :
    can(regex("^arn:aws:logs:", var.cloudwatch_loggroup.monitoring.destination_arn))))
    error_message = "If monitoring is specified, destination_arn must contain ARN, starting with 'arn:aws:logs:'."
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE LOGGING
# ---------------------------------------------------------------------------------------------------------------------
variable "s3_bucket" {
  description = "Configuration settings for core logging."
  type = object({
    bucket_name_prefix  = string
    days_to_glacier     = optional(number, -1)
    days_to_expiration  = number
    bucket_access_s3_id = optional(string, null)
    force_destroy       = optional(bool, false) // true - for testing only
  })

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.s3_bucket.bucket_name_prefix))
    error_message = "The s3_bucket_prefix must only contain alphanumeric characters and hyphens."
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

variable "resource_name_prefix" {
  description = "Alphanumeric suffix for all the resource names in this module."
  type        = string
  default     = ""

  validation {
    condition     = var.resource_name_prefix == "" ? true : can(regex("[[:alnum:]]", var.resource_name_prefix))
    error_message = "Value must be alphanumeric."
  }
}

variable "resource_name_suffix" {
  description = "Alphanumeric suffix for all the resource names in this module."
  type        = string
  default     = ""

  validation {
    condition     = var.resource_name_suffix == "" ? true : can(regex("[[:alnum:]]", var.resource_name_suffix))
    error_message = "Value must be alphanumeric."
  }
}

variable "iam_role_path" {
  description = "Path of the IAM role."
  type        = string
  default     = null

  validation {
    condition     = var.iam_role_path == null ? true : can(regex("^\\/", var.iam_role_path))
    error_message = "Value must start with '/'."
  }
}

variable "iam_role_permissions_boundary_arn" {
  description = "ARN of the policy that is used to set the permissions boundary for all IAM roles of the module."
  type        = string
  default     = null

  validation {
    condition     = var.iam_role_permissions_boundary_arn == null ? true : can(regex("^arn:aws:iam", var.iam_role_permissions_boundary_arn))
    error_message = "Value must contain ARN, starting with 'arn:aws:iam'."
  }
}

