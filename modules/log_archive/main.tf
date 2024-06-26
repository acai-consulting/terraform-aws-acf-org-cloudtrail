# ---------------------------------------------------------------------------------------------------------------------
# ¦ REQUIREMENTS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  # This module is only being tested with Terraform 1.3.9 and newer.
  required_version = ">= 1.3.9"

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
data "aws_caller_identity" "org_cloudtrail_bucket_target" {}
data "aws_organizations_organization" "org_cloudtrail_bucket_target" {}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ KMS KEY
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_kms_key" "core_logging_cloudtrail_mgmt_kms" {
  description             = "encryption key for object uploads to ${aws_s3_bucket.cloudtrail_logs.id}"
  deletion_window_in_days = 30
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
  #checkov:skip=CKV_AWS_109 : Resource policy
  #checkov:skip=CKV_AWS_111 : Resource policy
  #checkov:skip=CKV_AWS_356 : Resource policy  
  # enable IAM in logging account
  override_policy_documents = var.s3_bucket.kms_principal_permissions
  statement {
    sid    = "PrincipalPermissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.org_cloudtrail_bucket_target.account_id}:root"]
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

  dynamic "statement" {
    for_each = length(var.s3_bucket.policy.reader_principal_arns) > 0 ? [1] : []
    content {
      sid    = "ReaderPrincipals"
      effect = "Allow"
      actions = [
        "kms:Decrypt"
      ]
      principals {
        type        = "AWS"
        identifiers = var.s3_bucket.policy.reader_principal_arns
      }
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.s3_bucket.policy.access_to_org == true ? [1] : []
    content {
      sid    = "AwsOrgMemberObjectAccess"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = ["*"]
      }
      actions = [
        "kms:Decrypt"
      ]
      resources = ["*"]
      condition {
        test     = "StringEquals"
        variable = "aws:PrincipalOrgID"
        values = [
          data.aws_organizations_organization.org_cloudtrail_bucket_target.id
        ]
      }
    }
  }
}

resource "aws_kms_alias" "core_logging_cloudtrail_mgmt_kms" {
  name          = "alias/${replace(aws_s3_bucket.cloudtrail_logs.id, ".", "-")}-key"
  target_key_id = aws_kms_key.core_logging_cloudtrail_mgmt_kms.key_id
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ S3 BUCKET
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket" "cloudtrail_logs" {
  #checkov:skip=CKV_AWS_144 : Cross-region replication is not a requirement yet - # TODO check for later versions of the module
  bucket        = var.s3_bucket.bucket_name
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
  count      = var.s3_bucket.force_destroy == false ? 1 : 0
  depends_on = [aws_s3_bucket_versioning.cloudtrail_logs]
  bucket     = aws_s3_bucket.cloudtrail_logs.bucket
  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = var.s3_bucket.days_to_expiration
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.core_logging_cloudtrail_mgmt_kms.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail_logs" {
  #checkov:skip=CKV_AWS_300 : currently not source for an issue 
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

#tfsec:ignore:avd-aws-0089
#tfsec:ignore:avd-aws-0090
resource "aws_s3_bucket" "log_access_bucket" {
  #checkov:skip=CKV_AWS_144 : Cross-region replication is not a requirement yet - # TODO check for later versions of the module
  #checkov:skip=CKV2_AWS_62
  count         = var.s3_bucket.bucket_access_s3_id == null ? 1 : 0
  force_destroy = var.s3_bucket.force_destroy

  bucket = "${aws_s3_bucket.cloudtrail_logs.id}-access-logs"
}

resource "aws_s3_bucket_public_access_block" "log_access_bucket" {
  count = var.s3_bucket.bucket_access_s3_id == null ? 1 : 0

  bucket                  = aws_s3_bucket.log_access_bucket[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "cloudtrail_logs_access" {
  count = var.s3_bucket.bucket_access_s3_id != "" ? 1 : 0

  bucket        = aws_s3_bucket.cloudtrail_logs.id
  target_bucket = var.s3_bucket.bucket_access_s3_id == null ? aws_s3_bucket.log_access_bucket[0].id : var.s3_bucket.bucket_access_s3_id
  target_prefix = "logs/${aws_s3_bucket.cloudtrail_logs.id}/"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_access_bucket" {
  count = var.s3_bucket.bucket_access_s3_id == null ? 1 : 0

  bucket = aws_s3_bucket.log_access_bucket[0].id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.core_logging_cloudtrail_mgmt_kms.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs_access" {
  count = var.s3_bucket.bucket_access_s3_id == null ? 1 : 0

  bucket = aws_s3_bucket.log_access_bucket[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail_logs_access" {
  #checkov:skip=CKV_AWS_300 : currently not source for an issue 
  count = var.s3_bucket.bucket_access_s3_id == null ? 1 : 0

  bucket = aws_s3_bucket.log_access_bucket[0].id

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

# ---------------------------------------------------------------------------------------------------------------------
# ¦ S3 BUCKET POLICY
# ---------------------------------------------------------------------------------------------------------------------
## https://docs.aws.amazon.com/awscloudtrail/latest/userguide/create-s3-bucket-policy-for-cloudtrail.html
## https://aws.amazon.com/blogs/security/how-to-prevent-uploads-of-unencrypted-objects-to-amazon-s3/
## https://aws.amazon.com/premiumsupport/knowledge-center/s3-bucket-store-kms-encrypted-objects/
resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  policy = data.aws_iam_policy_document.cloudtrail_logs.json
}

data "aws_iam_policy_document" "cloudtrail_logs" {
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

  dynamic "statement" {
    for_each = length(var.s3_bucket.policy.reader_principal_arns) > 0 ? [1] : []

    content {
      sid    = "ReaderPrincipals"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:GetObjectVersion" # required for Splunk AWS Add-on >= 6.0.0      
      ]
      principals {
        type        = "AWS"
        identifiers = var.s3_bucket.policy.reader_principal_arns
      }
      resources = [
        aws_s3_bucket.cloudtrail_logs.arn,
        "${aws_s3_bucket.cloudtrail_logs.arn}/*"
      ]
    }
  }

  # See: https://aws.amazon.com/de/blogs/mt/restrict-access-by-member-account-to-a-centralized-cloudtrail-logging-bucket/
  dynamic "statement" {
    for_each = var.s3_bucket.policy.access_to_org == true ? [1] : []
    content {
      sid    = "SpokeAccountAccessBucketLevel"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = ["*"]
      }
      actions = [
        "s3:ListBucket"
      ]
      resources = [
        aws_s3_bucket.cloudtrail_logs.arn
      ]
      condition {
        test     = "StringEquals"
        variable = "aws:PrincipalOrgID"
        values = [
          data.aws_organizations_organization.org_cloudtrail_bucket_target.id
        ]
      }
      condition {
        test     = "StringLike"
        variable = "s3:prefix"
        values   = ["AWSLogs/${data.aws_organizations_organization.org_cloudtrail_bucket_target.id}/$${aws:PrincipalAccount}/*"]
      }
    }
  }

  dynamic "statement" {
    for_each = var.s3_bucket.policy.access_to_org == true ? [1] : []
    content {
      sid    = "SpokeAccountAccessObjectLevel"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = ["*"]
      }
      actions = [
        "s3:GetObject"
      ]
      resources = [
        format(
          "arn:aws:s3:::%s/AWSLogs/%s/$${aws:PrincipalAccount}/*",
          aws_s3_bucket.cloudtrail_logs.id,
          data.aws_organizations_organization.org_cloudtrail_bucket_target.id
        )
      ]
      condition {
        test     = "StringEquals"
        variable = "aws:PrincipalOrgID"
        values = [
          data.aws_organizations_organization.org_cloudtrail_bucket_target.id
        ]
      }
    }
  }

}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ S3 BUCKET NOTIFICATION
# ---------------------------------------------------------------------------------------------------------------------
#tfsec:ignore:avd-aws-0095  # only meta-data
resource "aws_sns_topic" "s3_notification_sns" {
  #checkov:skip=CKV_AWS_26 : only metadata
  count = var.s3_bucket.notification_to_sns != null ? 1 : 0

  name = var.s3_bucket.notification_to_sns.sns_name
  tags = var.resource_tags
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  count = var.s3_bucket.notification_to_sns != null ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail_logs.id

  topic {
    id        = "notification_to_sns"
    topic_arn = aws_sns_topic.s3_notification_sns[0].arn
    events    = ["s3:ObjectCreated:*"]
  }
}

resource "aws_sns_topic_policy" "s3_notification_sns" {
  count = var.s3_bucket.notification_to_sns != null ? 1 : 0

  arn    = aws_sns_topic.s3_notification_sns[0].arn
  policy = data.aws_iam_policy_document.s3_notification_sns[0].json
}

data "aws_iam_policy_document" "s3_notification_sns" {
  count = var.s3_bucket.notification_to_sns != null ? 1 : 0

  statement {
    sid     = "AllowedPublishers"
    actions = ["sns:Publish"]
    effect  = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "s3.amazonaws.com"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.org_cloudtrail_bucket_target.account_id]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        aws_s3_bucket.cloudtrail_logs.arn
      ]
    }
    resources = [aws_sns_topic.s3_notification_sns[0].arn]
  }

  statement {
    sid     = "AllowedSubscribers"
    actions = ["sns:Subscribe"]
    effect  = "Allow"
    principals {
      type        = "AWS"
      identifiers = var.s3_bucket.notification_to_sns.allowed_subscribers
    }
    resources = [aws_sns_topic.s3_notification_sns[0].arn]
  }
}
