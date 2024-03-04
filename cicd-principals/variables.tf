variable "cloudwatch_loggroup" {
  description = "Configuration settings for CloudWatch LogGroup."
  type = object({
    loggroup_name = string
    iam_role_name = string
    iam_role_path = string
  })
}

variable "s3_bucket" {
  description = "Configuration settings for core logging."
  type = object({
    bucket_name        = string
    bucket_name_prefix = string
  })
}

variable "bucket_notification_to_sns" {
  type = object({
    sns_name = string
  })
}

