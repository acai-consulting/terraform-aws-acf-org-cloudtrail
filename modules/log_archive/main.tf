# ---------------------------------------------------------------------------------------------------------------------
# ¦ REQUIREMENTS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  # This module is only being tested with Terraform 0.15.x and newer.
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.0"
      configuration_aliases = []
    }
  }
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA
# ---------------------------------------------------------------------------------------------------------------------
data "aws_caller_identity" "core_logging" {}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  bucket_name_prefix = "${var.resource_name_prefix}${var.s3_bucket.bucket_name_prefix}"
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE LOGGING - KMS KEY
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_kms_key" "core_logging_cloudtrail_mgmt_kms" {
  description             = "encryption key for object uploads to ${aws_s3_bucket.cloudtrail_logs.id}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.core_logging_cloudtrail_mgmt_kms.json
  tags = merge(
    var.resource_tags,
    {
      "CF:KeyDeletionProtection" = "true"
    }
  )
}

data "aws_iam_policy_document" "core_logging_cloudtrail_mgmt_kms" {
  # enable IAM in logging account
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.core_logging.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  # allow org master account to encrypt in the cloudtrail encryption context
  statement {
    sid       = "Allow CloudTrail to encrypt logs"
    effect    = "Allow"
    actions   = ["kms:GenerateDataKey"]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values = [
        "arn:aws:cloudtrail:*:${var.org_mgmt_account_id}:trail/*"
      ]
    }
  }

  # allow org master account to encrypt in the cloudtrail encryption context
  statement {
    sid       = "Allow CloudTrail to describe key"
    effect    = "Allow"
    actions   = ["kms:DescribeKey"]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_kms_alias" "core_logging_cloudtrail_mgmt_kms" {
  name          = "alias/${replace(aws_s3_bucket.cloudtrail_logs.id, ".", "-")}-key"
  target_key_id = aws_kms_key.core_logging_cloudtrail_mgmt_kms.key_id
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE LOGGING - S3 BUCKET
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket_prefix = local.bucket_name_prefix
  force_destroy = var.s3_bucket.force_destroy
  tags          = var.resource_tags
}

resource "aws_s3_bucket_ownership_controls" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_object_lock_configuration" "cloudtrail_logs" {
  depends_on = [aws_s3_bucket_versioning.cloudtrail_logs]
  bucket     = aws_s3_bucket.cloudtrail_logs.bucket
  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = var.s3_bucket.days_to_expiration
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs_custom" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.core_logging_cloudtrail_mgmt_kms.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail_logs_lifecycle" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    id     = "log"
    status = "Enabled"

    # Only add the transition rule if days_to_glacier is not -1
    dynamic "transition" {
      for_each = var.s3_bucket.days_to_glacier != -1 ? [1] : []
      content {
        days          = var.s3_bucket.days_to_glacier
        storage_class = "GLACIER"
      }
    }

    expiration {
      days = var.s3_bucket.days_to_expiration
    }
  }
}


resource "aws_s3_bucket" "log_bucket" {
  count = var.s3_bucket.bucket_access_s3_id == null ? 1 : 0

  bucket = "${aws_s3_bucket.cloudtrail_logs.id}-access-logs"
}

resource "aws_s3_bucket_acl" "log_bucket_acl" {
  count = var.s3_bucket.bucket_access_s3_id == null ? 1 : 0

  bucket = aws_s3_bucket.log_bucket[0].id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_logging" "cloudtrail_logs" {
  bucket        = aws_s3_bucket.cloudtrail_logs.id
  target_bucket = var.s3_bucket.bucket_access_s3_id == null ? aws_s3_bucket.log_bucket[0].id : var.s3_bucket.bucket_access_s3_id
  target_prefix = "logs/${aws_s3_bucket.cloudtrail_logs.id}/"
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE LOGGING - S3 BUCKET POLICY
# ---------------------------------------------------------------------------------------------------------------------
## https://docs.aws.amazon.com/awscloudtrail/latest/userguide/create-s3-bucket-policy-for-cloudtrail.html
## https://aws.amazon.com/blogs/security/how-to-prevent-uploads-of-unencrypted-objects-to-amazon-s3/
## https://aws.amazon.com/premiumsupport/knowledge-center/s3-bucket-store-kms-encrypted-objects/
resource "aws_s3_bucket_policy" "core_logging_cloudtrail_mgmt_bucket_name" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  policy = data.aws_iam_policy_document.core_logging_cloudtrail_mgmt_bucket_name.json
}

data "aws_iam_policy_document" "core_logging_cloudtrail_mgmt_bucket_name" {
  statement {
    sid    = "Require_KMS_CMK_Encryption"
    effect = "Deny"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/*/CloudTrail/*",
      "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/*/*/CloudTrail/*",
    ]
    # DenyIncorrectEncryptionHeader
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }
    # Require correct KMS CMK key
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = [aws_kms_key.core_logging_cloudtrail_mgmt_kms.arn]
    }
  }

  statement {
    sid    = "Require_KMS_Encryption_for_Digest"
    effect = "Deny"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/*/CloudTrail_Digest/*",
      "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/*/*/CloudTrail_Digest/*",
    ]
    # DenyIncorrectEncryptionHeader
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["AES256"]
    }
  }

  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail_logs.arn]
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}
