output "bucket_id" {
  value = aws_s3_bucket.data_bucket.id
}

output "bucket_arn" {
  value = aws_s3_bucket.data_bucket.arn
}

output "kms_cmk_arn" {
  value = aws_kms_key.core_logging_cloudtrail_mgmt_kms.arn
}
