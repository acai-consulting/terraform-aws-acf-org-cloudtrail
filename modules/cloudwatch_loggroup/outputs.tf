output "iam_role_arn" {
  value = aws_iam_role.org_cloudtrail_cloudwatch_logs.arn
}

output "loggroup_arn" {
  value = aws_cloudwatch_log_group.org_cloudtrail_cloudwatch_loggroup.arn
}
