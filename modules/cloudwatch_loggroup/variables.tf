variable "org_cloudtrail_name" {
  description = "Name of the Organization CloudTrail."
  type        = string
}

variable "cloudwatch_loggroup" {
  description = "Configuration settings for CloudWatch LogGroup."
  type = object({
    iam_role_name     = optional(string, "foundation-cloudtrail-role") # without prefix
    iam_role_path     = optional(string, "/")                          # without prefix
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
      [1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cloudwatch_loggroup.retention_in_days
    ))
    error_message = "The CloudWatch Logs retention period must be a Fibonacci number and supported by AWS (1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 120, 150, 180, 365, 400, 545, 731, 1827, or 3653 days)."
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
