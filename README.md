# terraform-aws-acf-org-cloudtrail

<!-- LOGO -->
<a href="https://acai.gmbh">    
  <img src="https://github.com/acai-consulting/acai.public/raw/main/logo/logo_github_readme.png" alt="acai logo" title="ACAI" align="right" height="75" />
</a>

<!-- SHIELDS -->
[![Maintained by acai.gmbh][acai-shield]][acai-url]
[![Terraform Version][terraform-version-shield]][terraform-version-url]
[![Latest Release][release-shield]][release-url]

<!-- DESCRIPTION -->
Deploy the AWS Organization CloudTrail

[Terraform][terraform-url] module to deploy REPLACE_ME resources on [AWS][aws-url]

<!-- ARCHITECTURE -->
## Architecture
![architecture][architecture-png]

<!-- FEATURES -->
## Features
* Creates a REPLACE_ME

<!-- USAGE -->
## Usage

### REPLACE_ME
```hcl
module "REPLACE_ME" {
  source  = "acai/REPLACE_ME/aws"
  version = "~> 1.0"

  input1 = "value1"
}
```

<!-- EXAMPLES -->
## Examples

* [`examples/complete`][example-complete-url]

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
| <a name="input_s3_bucket"></a> [s3\_bucket](#input\_s3\_bucket) | Configuration settings for core logging. | <pre>object({<br>    bucket_name           = optional(string, null)<br>    bucket_name_prefix    = optional(string, null)<br>    days_to_glacier       = optional(number, -1)<br>    days_to_expiration    = number<br>    bucket_access_s3_id   = optional(string, null)<br>    force_destroy         = optional(bool, false) # true - for testing only<br>    reader_principal_arns = optional(list(string), [])<br>    notification_to_sns = optional(object({<br>      sns_name = string<br>    }), null)<br>  })</pre> | n/a | yes |
| <a name="input_cloudwatch_loggroup"></a> [cloudwatch\_loggroup](#input\_cloudwatch\_loggroup) | Configuration settings for CloudWatch LogGroup. | <pre>object({<br>    loggroup_name     = optional(string, "org-cloudtrail-logs")<br>    iam_role_name     = optional(string, "cloudtrail-role")<br>    iam_role_path     = optional(string, "/")<br>    iam_role_pb       = optional(string, null)<br>    retention_in_days = optional(number, 3)<br>    monitoring = optional(object({<br>      inbound_iam_role_name = optional(string, null)<br>      destination_arn       = optional(string, null)<br>    }), null)<br>  })</pre> | `null` | no |
| <a name="input_core_configuration_cluster_name"></a> [core\_configuration\_cluster\_name](#input\_core\_configuration\_cluster\_name) | Cluster name for the Core Configuration map. | `string` | `"security"` | no |
| <a name="input_resource_tags"></a> [resource\_tags](#input\_resource\_tags) | A map of tags to assign to the resources in this module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_core_configuration_to_write"></a> [core\_configuration\_to\_write](#output\_core\_configuration\_to\_write) | This must be in sync with the Account Baselining |
<!-- END_TF_DOCS -->

<!-- AUTHORS -->
## Authors

This module is maintained by [ACAI GmbH][acai-url] with help from [these amazing contributors][contributors-url]

<!-- LICENSE -->
## License

This module is licensed under Apache 2.0
<br />
See [LICENSE][license-url] for full details

<!-- COPYRIGHT -->
<br />
<br />
<p align="center">Copyright &copy; 2024 ACAI GmbH</p>

<!-- MARKDOWN LINKS & IMAGES -->
[acai-shield]: https://img.shields.io/badge/maintained_by-acai.gmbh-CB224B?style=flat
[acai-url]: https://acai.gmbh
[terraform-version-shield]: https://img.shields.io/badge/tf-%3E%3D1.3.0-blue.svg?style=flat&color=blueviolet
[terraform-version-url]: https://www.terraform.io/upgrade-guides/0-15.html
[release-shield]: https://img.shields.io/github/v/release/acai-consulting/terraform-aws-acf-ou-mgmt?style=flat&color=success
[architecture-png]: https://github.com/acai-consulting/terraform-aws-acf-ou-mgmt/blob/main/docs/architecture.png?raw=true
[release-url]: https://github.com/acai-consulting/terraform-aws-acf-ou-mgmt/releases
[contributors-url]: https://github.com/acai-consulting/terraform-aws-acf-ou-mgmt/graphs/contributors
[license-url]: https://github.com/acai-consulting/terraform-aws-acf-ou-mgmt/tree/main/LICENSE
[terraform-url]: https://www.terraform.io
[aws-url]: https://aws.amazon.comterraform-aws-acf-ou-mgmt/tree/main/examples/complete
