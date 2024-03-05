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
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.org_cloudtrail_kms.json
  tags                    = var.resource_tags
}

data "aws_iam_policy_document" "org_cloudtrail_kms" {
  # enable IAM in logging account
  statement {
    sid    = "Enable IAM User Permissions"
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

/*
# ---------------------------------------------------------------------------------------------------------------------
# ¦ MONITORING FORWARDING 
# ¦ *** IAM ROLE
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "cw_logs_dest" {
  count = local.subscribe_to_monitoring == true ? 1 : 0

  name               = var.core_monitoring_inbound_role_name
  assume_role_policy = data.aws_iam_policy_document.cw_logs_dest_trust[0].json
  tags               = var.resource_tags
  provider           = aws.org_cloudtrail_admin
}

data "aws_iam_policy_document" "cw_logs_dest_trust" {
  count = local.subscribe_to_monitoring == true ? 1 : 0

  statement {
    sid    = "TrustPolicy"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = [format("logs.%s.amazonaws.com", data.aws_region.org_cloudtrail.name)]
    }
    actions = [
      "sts:AssumeRole"
    ]
  }
  provider = aws.org_cloudtrail_admin
}

resource "aws_iam_role_policy" "cw_logs_dest_permissions" {
  count = local.subscribe_to_monitoring == true ? 1 : 0

  name     = "CwLogsDestAccess"
  role     = aws_iam_role.cw_logs_dest[0].name
  policy   = data.aws_iam_policy_document.cw_logs_dest_permissions[0].json
  provider = aws.org_cloudtrail_admin
}

data "aws_iam_policy_document" "cw_logs_dest_permissions" {
  count = local.subscribe_to_monitoring == true ? 1 : 0

  statement {
    sid    = "LogToCloudWatchLogsDest"
    effect = "Allow"
    actions = [
      "logs:PutLogEvents"
    ]
    resources = compact(
      [
        format("%s:*", var.core_monitoring_cloudtrail_cw_logs_dest_arn),
        var.core_monitoring_cloudtrail_cw_logs_dest_arn
      ]
    )
  }
  provider = aws.org_cloudtrail_admin
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ *** SUBSCRIPTION FILTER
resource "aws_cloudwatch_log_subscription_filter" "cloudtrail_to_monitoring_forwarder" {
  count = local.subscribe_to_monitoring == true ? 1 : 0

  name            = "org-cloudtrail-forwarder"
  log_group_name  = aws_cloudwatch_log_group.org_cloudtrail_cloudwatch_loggroup[0].name
  filter_pattern  = ""
  destination_arn = var.core_monitoring_cloudtrail_cw_logs_dest_arn
  role_arn        = aws_iam_role.cw_logs_dest[0].arn
  distribution    = "Random"
  provider        = aws.org_cloudtrail_admin
  depends_on = [
    aws_iam_role.cw_logs_dest[0]
  ]
}
*/