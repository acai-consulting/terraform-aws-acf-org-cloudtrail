variable "cloudwatch_loggroup" {
  description = "Configuration settings for CloudWatch LogGroup."
  type = object({
    loggroup_name     = string
    iam_role_name     = string
    iam_role_path     = string
    iam_role_pb       = string
    retention_in_days = number
    monitoring = object({
      inbound_iam_role_name = string
      destination_arn       = string
    })
  })
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ COMMON
# ---------------------------------------------------------------------------------------------------------------------
variable "resource_tags" {
  description = "A map of tags to assign to the resources in this module."
  type        = map(string)
}
