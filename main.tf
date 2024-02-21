# ---------------------------------------------------------------------------------------------------------------------
# ¦ REQUIREMENTS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  # This module is only being tested with Terraform 0.15.x and newer.
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
      configuration_aliases = [
        aws.org_cloudtrail_admin,
        aws.core_logging
      ]
    }
  }
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA
# ---------------------------------------------------------------------------------------------------------------------
data "aws_caller_identity" "org_cloudtrail" {
  provider = aws.org_cloudtrail_admin
}



# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE LOGGING - S3 BUCKET
# ---------------------------------------------------------------------------------------------------------------------
module "log_archive_bucket" {
  source = "./modules/log_archive"

  s3_bucket            = var.s3_bucket
  org_mgmt_account_id  = data.aws_caller_identity.org_cloudtrail.account_id
  resource_tags        = var.resource_tags
  resource_name_prefix = var.resource_name_prefix
  providers = {
    aws = aws.org_cloudtrail_admin
  }
}

module "cloudwatch_loggroup" {
  source = "./modules/cloudwatch_loggroup"
  count  = var.cloudwatch_loggroup != null ? 1 : 0

  org_cloudtrail_name  = var.org_cloudtrail_name
  cloudwatch_loggroup  = var.cloudwatch_loggroup
  resource_tags        = var.resource_tags
  resource_name_prefix = var.resource_name_prefix
  providers = {
    aws = aws.org_cloudtrail_admin
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ ORG MANAGEMENT - CLOUDTRAIL
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cloudtrail" "org_cloudtrail_mgmt" {
  name                          = var.org_cloudtrail_name
  is_organization_trail         = true
  include_global_service_events = true
  is_multi_region_trail         = true
  s3_bucket_name                = module.log_archive_bucket.bucket_id
  enable_log_file_validation    = true
  kms_key_id                    = module.log_archive_bucket.kms_cmk_arn
  cloud_watch_logs_group_arn    = var.cloudwatch_loggroup != null ? module.cloudwatch_loggroup[0].loggroup_arn : null
  cloud_watch_logs_role_arn     = var.cloudwatch_loggroup != null ? module.cloudwatch_loggroup[0].iam_role_arn : null
  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }
  tags = var.resource_tags

  depends_on = [module.log_archive_bucket]

  provider = aws.org_cloudtrail_admin
}


