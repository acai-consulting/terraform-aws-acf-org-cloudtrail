variable "cloudwatch_loggroup" {
  description = "Configuration settings for CloudWatch LogGroup."
  type = object({
    loggroup_name     = string
    iam_role_name     = string
    iam_role_path     = string
  })
}
