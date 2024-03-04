# ---------------------------------------------------------------------------------------------------------------------
# ¦ PROVIDER
# ---------------------------------------------------------------------------------------------------------------------
provider "aws" {
  region = "eu-central-1"
  alias  = "org_mgmt"
  # please use the target role you need.
  # create additional providers in case your module provisions to multiple core accounts.
  assume_role {
    role_arn = "arn:aws:iam::471112796356:role/OrganizationAccountAccessRole" // ACAI AWS Testbed Org-Mgmt Account
    #role_arn = "arn:aws:iam::590183833356:role/OrganizationAccountAccessRole" // ACAI AWS Testbed Core Logging Account
    #role_arn = "arn:aws:iam::992382728088:role/OrganizationAccountAccessRole" // ACAI AWS Testbed Core Security Account
    #role_arn = "arn:aws:iam::767398146370:role/OrganizationAccountAccessRole" // ACAI AWS Testbed Workload Account
  }
}

provider "aws" {
  region = "eu-central-1"
  alias  = "core_logging"
  # please use the target role you need.
  # create additional providers in case your module provisions to multiple core accounts.
  assume_role {
    #role_arn = "arn:aws:iam::471112796356:role/OrganizationAccountAccessRole" // ACAI AWS Testbed Org-Mgmt Account
    role_arn = "arn:aws:iam::590183833356:role/OrganizationAccountAccessRole" // ACAI AWS Testbed Core Logging Account
    #role_arn = "arn:aws:iam::992382728088:role/OrganizationAccountAccessRole" // ACAI AWS Testbed Core Security Account
    #role_arn = "arn:aws:iam::767398146370:role/OrganizationAccountAccessRole" // ACAI AWS Testbed Workload Account
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ BACKEND
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  backend "remote" {
    organization = "acai"
    hostname     = "app.terraform.io"

    workspaces {
      name = "aws-testbed"
    }
  }
}

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
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA
# ---------------------------------------------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ MODULE
# ---------------------------------------------------------------------------------------------------------------------
module "example_complete" {
  source = "../../"

  org_cloudtrail_name = "organization-cloudtrail"

  cloudwatch_loggroup = {}
  s3_bucket = {
    bucket_name_prefix = "org-cloudtrail"
    days_to_expiration = 180
    force_destroy      = true
  }
  providers = {
    aws.org_cloudtrail_admin = aws.org_mgmt
    aws.core_logging         = aws.core_logging
  }
}
