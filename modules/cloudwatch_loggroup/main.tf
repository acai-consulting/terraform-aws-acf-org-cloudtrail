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
data "aws_caller_identity" "org_cloudtrail" {}
data "aws_region" "org_cloudtrail" {}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ ORG MANAGEMENT - CLOUDWATCH LOGGROUP
# ---------------------------------------------------------------------------------------------------------------------
#https://github.com/cloudposse/terraform-aws-cloudtrail-cloudwatch-alarms/issues/2
resource "aws_cloudwatch_log_group" "org_cloudtrail_cloudwatch_loggroup" {
  name              = var.cloudwatch_loggroup.loggroup_name
  retention_in_days = var.cloudwatch_loggroup.retention_in_days == -1 ? null : var.cloudwatch_loggroup.retention_in_days
  kms_key_id        = aws_kms_key.org_cloudtrail_kms.arn
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ ORG MANAGEMENT - CLOUDWATCH LOGGROUP KMS KEY
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_kms_key" "org_cloudtrail_kms" {
  description             = "Encryption key for CloudTrail CloudWatch LogGroup"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.org_cloudtrail_kms.json
  tags                    = var.resource_tags
}

data "aws_iam_policy_document" "org_cloudtrail_kms" {
  #checkov:skip=CKV_AWS_109 : Resource policy
  #checkov:skip=CKV_AWS_111 : Resource policy
  #checkov:skip=CKV_AWS_356 : Resource policy  
  # enable IAM in logging account
  override_policy_documents = var.cloudwatch_loggroup.kms_principal_permissions
  statement {
    sid    = "PrincipalPermissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.org_cloudtrail.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  # allow org master account to encrypt in the cloudtrail encryption context
  statement {
    sid    = "Allow CloudWatch to encrypt logs"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncryptFrom",
      "kms:ReEncrpytTo",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyPair",
      "kms:GenerateDataKeyPairWithoutPlaintext",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:DescribeKey",
    ]
    resources = ["*"]
    principals {
      type = "Service"
      identifiers = [
        format("logs.%s.amazonaws.com", data.aws_region.org_cloudtrail.name)
      ]
    }
    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values = [
        format(
          "arn:aws:logs:%s:%s:log-group:%s",
          data.aws_region.org_cloudtrail.name,
          data.aws_caller_identity.org_cloudtrail.account_id,
          var.cloudwatch_loggroup.loggroup_name
        )
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

resource "aws_kms_alias" "org_cloudtrail_kms" {
  name          = "alias/${aws_cloudwatch_log_group.org_cloudtrail_cloudwatch_loggroup.name}-key"
  target_key_id = aws_kms_key.org_cloudtrail_kms.key_id
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ ORG MANAGEMENT - CLOUDWATCH LOGS IAM
# ---------------------------------------------------------------------------------------------------------------------
## https://docs.aws.amazon.com/awscloudtrail/latest/userguide/send-cloudtrail-events-to-cloudwatch-logs.html#send-cloudtrail-events-to-cloudwatch-logs-console-create-role
resource "aws_iam_role" "org_cloudtrail_cloudwatch_logs" {
  name                 = var.cloudwatch_loggroup.iam_role_name
  path                 = var.cloudwatch_loggroup.iam_role_path
  permissions_boundary = var.cloudwatch_loggroup.iam_role_pb
  assume_role_policy   = data.aws_iam_policy_document.org_cloudtrail_cloudwatch_logs_trust.json
}

data "aws_iam_policy_document" "org_cloudtrail_cloudwatch_logs_trust" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "org_cloudtrail_cloudwatch_logs" {
  name   = "AllowCloudWatchogGroup"
  role   = aws_iam_role.org_cloudtrail_cloudwatch_logs.name
  policy = data.aws_iam_policy_document.org_cloudtrail_cloudwatch_logs.json
}

## https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-required-policy-for-cloudwatch-logs.html?icmpid=docs_cloudtrail_console
#tfsec:ignore:avd-aws-0057
data "aws_iam_policy_document" "org_cloudtrail_cloudwatch_logs" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      format("%s:log-stream:*", aws_cloudwatch_log_group.org_cloudtrail_cloudwatch_loggroup.arn)
    ]
  }
}
