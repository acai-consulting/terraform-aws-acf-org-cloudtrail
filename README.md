# terraform-aws-acf-org-cloudtrail

<!-- SHIELDS -->
[![Maintained by acai.gmbh][acai-shield]][acai-url] 
![module-version-shield]
![terraform-version-shield]
![trivy-shield]
![checkov-shield]
[![Latest Release][release-shield]][release-url]

<!-- LOGO -->
<div style="text-align: right; margin-top: -60px;">
<a href="https://acai.gmbh">
  <img src="https://github.com/acai-consulting/acai.public/raw/main/logo/logo_github_readme.png" alt="acai logo" title="ACAI"  width="250" /></a>
</div>
</br>

<!-- DESCRIPTION -->
This module will deploy the AWS Organization CloudTrail and the S3 bucket to store the logs encrypted with a KMS CMK.
Optionally the CloudTrail Logs can be stored in a CloudWatch LogGroup in the CloudTrail Admin Account.


<!-- ARCHITECTURE -->
## Architecture
![architecture](https://raw.githubusercontent.com/acai-consulting/terraform-aws-acf-org-cloudtrail/main/docs/acf_org_cloudtrail.svg)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws.org_cloudtrail_admin"></a> [aws.org\_cloudtrail\_admin](#provider\_aws.org\_cloudtrail\_admin) | >= 5.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cloudwatch_loggroup"></a> [cloudwatch\_loggroup](#module\_cloudwatch\_loggroup) | ./modules/cloudwatch_loggroup | n/a |
| <a name="module_log_archive_bucket"></a> [log\_archive\_bucket](#module\_log\_archive\_bucket) | ./modules/log_archive | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudtrail.org_cloudtrail_mgmt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail) | resource |
| [aws_caller_identity.org_cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_org_cloudtrail_name"></a> [org\_cloudtrail\_name](#input\_org\_cloudtrail\_name) | Name of the Organization CloudTrail. | `string` | n/a | yes |
| <a name="input_s3_bucket"></a> [s3\_bucket](#input\_s3\_bucket) | Configuration settings for core logging. | <pre>object({<br>    bucket_name         = string<br>    days_to_glacier     = optional(number, -1)<br>    days_to_expiration  = number<br>    bucket_access_s3_id = optional(string, null)<br>    force_destroy       = optional(bool, false) # true - for testing only<br>    policy = optional(object({<br>      reader_principal_arns = optional(list(string), [])<br>      access_to_org         = optional(bool, false)<br>      }), {<br>      reader_principal_arns = []<br>      access_to_org         = false<br>    })<br>    notification_to_sns = optional(object({<br>      sns_name            = optional(string, "org-cloudtrail-bucket-notification")<br>      allowed_subscribers = list(string)<br>    }), null)<br>  })</pre> | n/a | yes |
| <a name="input_cloudwatch_loggroup"></a> [cloudwatch\_loggroup](#input\_cloudwatch\_loggroup) | Configuration settings for CloudWatch LogGroup. | <pre>object({<br>    loggroup_name     = optional(string, "org-cloudtrail-logs")<br>    iam_role_name     = optional(string, "cloudtrail-role")<br>    iam_role_path     = optional(string, "/")<br>    iam_role_pb       = optional(string, null)<br>    retention_in_days = optional(number, 3)<br>    monitoring = optional(object({<br>      inbound_iam_role_name = optional(string, null)<br>      destination_arn       = optional(string, null)<br>    }), null)<br>  })</pre> | `null` | no |
| <a name="input_resource_tags"></a> [resource\_tags](#input\_resource\_tags) | A map of tags to assign to the resources in this module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_core_configuration_to_write"></a> [core\_configuration\_to\_write](#output\_core\_configuration\_to\_write) | This must be in sync with the Account Baselining |
<!-- END_TF_DOCS -->

<!-- AUTHORS -->
## Authors

This module is maintained by [ACAI GmbH][acai-url].

<!-- LICENSE -->
## License

See [LICENSE][license-url] for full details.

<!-- COPYRIGHT -->
<br />
<br />
<p align="center">Copyright &copy; 2024 ACAI GmbH</p>

<!-- MARKDOWN LINKS & IMAGES -->
[acai-shield]: https://img.shields.io/badge/maintained_by-acai.gmbh-CB224B?style=flat
[acai-url]: https://acai.gmbh
[module-version-shield]: https://img.shields.io/badge/module_version-1.1.4-CB224B?style=flat
[terraform-version-shield]: https://img.shields.io/badge/tf-%3E%3D1.3.9-blue.svg?style=flat&color=blueviolet
[trivy-shield]: https://img.shields.io/badge/trivy-passed-green
[checkov-shield]: https://img.shields.io/badge/checkov-passed-green
[release-shield]: https://img.shields.io/github/v/release/acai-consulting/terraform-aws-acf-org-cloudtrail?style=flat&color=success
[release-url]: https://github.com/acai-consulting/terraform-aws-acf-org-cloudtrail/releases
[license-url]: https://github.com/acai-consulting/terraform-aws-acf-org-cloudtrail/tree/main/LICENSE.md
