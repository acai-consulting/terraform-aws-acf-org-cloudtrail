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

variable "org_mgmt_account_id" {
  type = string
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
