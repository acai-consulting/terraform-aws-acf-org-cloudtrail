output "bucket_id" {
  description = "Bucket ID of the CloudTrail bucket"
  value       = aws_s3_bucket.cloudtrail_logs.id
}

output "bucket_arn" {
  description = "ARN of the CloudTrail bucket"
  value       = aws_s3_bucket.cloudtrail_logs.arn
}

output "kms_cmk_arn" {
  description = "ARN of the KMS CMK for encrypting the logs"
  value       = aws_kms_key.core_logging_cloudtrail_mgmt_kms.arn
}
