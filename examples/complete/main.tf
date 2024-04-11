# ---------------------------------------------------------------------------------------------------------------------
# ¦ VERSIONS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.3.9"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.0"
      configuration_aliases = []
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA
# ---------------------------------------------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ RANDOM_STRING
# ---------------------------------------------------------------------------------------------------------------------
resource "random_string" "suffix" {
  length  = 8     # Length of the random string, adjust as needed
  special = false # Exclude special characters for compatibility
  upper   = false # Use lowercase to ensure compatibility with AWS naming conventions
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ MODULE
# ---------------------------------------------------------------------------------------------------------------------
module "example_complete" {
  source = "../../"

  org_cloudtrail_name = "organization-cloudtrail"

  cloudwatch_loggroup = {}
  s3_bucket = {
    bucket_name        = "org-cloudtrail-${random_string.suffix.result}"
    days_to_expiration = 3
    force_destroy      = true
  }
  providers = {
    aws.org_cloudtrail_admin  = aws.org_mgmt
    aws.org_cloudtrail_bucket = aws.core_logging
  }
}
