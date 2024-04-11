# ---------------------------------------------------------------------------------------------------------------------
# ¦ REQUIREMENTS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  # This module is only being tested with Terraform 1.3.9 and newer.
  required_version = ">= 1.3.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
      configuration_aliases = [
        aws.org_cloudtrail_admin,
        aws.org_cloudtrail_bucket
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
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  resource_tags = merge(
    var.resource_tags,
    {
      "module_provider" = "ACAI GmbH",
      "module_name"     = "terraform-aws-acf-org-cloudtrail",
      "module_source"   = "github.com/acai-consulting/terraform-aws-acf-org-cloudtrail",
      "module_version"  = /*inject_version_start*/ "1.2.2" /*inject_version_end*/
    }
  )
  core_configuration_to_write = {
    "security" = {
      "org_cloudtrail" = {
        cloudtrail_admin = {
          org_cloudtrail_name = var.org_cloudtrail_name
          cloudwatch_loggroup = var.cloudwatch_loggroup == null ? {} : module.cloudwatch_loggroup[0]
        }
        cloudtrail_bucket = module.log_archive_bucket
      }
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE LOGGING - S3 BUCKET
# ---------------------------------------------------------------------------------------------------------------------
module "log_archive_bucket" {
  source = "./modules/log_archive"

  s3_bucket           = var.s3_bucket
  org_mgmt_account_id = data.aws_caller_identity.org_cloudtrail.account_id
  resource_tags       = var.resource_tags
  providers = {
    aws = aws.org_cloudtrail_bucket
  }
}

module "cloudwatch_loggroup" {
  source = "./modules/cloudwatch_loggroup"
  count  = var.cloudwatch_loggroup != null ? 1 : 0

  cloudwatch_loggroup = var.cloudwatch_loggroup
  resource_tags       = var.resource_tags
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
  cloud_watch_logs_group_arn    = var.cloudwatch_loggroup == null ? null : "${module.cloudwatch_loggroup[0].loggroup_arn}:*" # CloudTrail requires the Log Stream wildcard 
  cloud_watch_logs_role_arn     = var.cloudwatch_loggroup == null ? null : module.cloudwatch_loggroup[0].iam_role_arn
  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }
  tags = var.resource_tags

  depends_on = [module.log_archive_bucket]

  provider = aws.org_cloudtrail_admin
}


