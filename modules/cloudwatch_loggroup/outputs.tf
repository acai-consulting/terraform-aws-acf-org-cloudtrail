output "iam_role_arn" {
  description = "ARN of the IAM Role used to push CLoudTrail Logs to CloudWatch"
  value = aws_iam_role.org_cloudtrail_cloudwatch_logs.arn
}

output "loggroup_arn" {
  description = "ARN of the CloudWatch LogGroup"
  value = aws_cloudwatch_log_group.org_cloudtrail_cloudwatch_loggroup.arn
}

output "kms_cmk_arn" {
  description = "ARN of the KMS CMK used to encrypt the CloudWathc Logs"
  value = aws_kms_key.org_cloudtrail_kms.arn
}
