# terraform-aws-acf-org-cloudtrail

<!-- LOGO -->
<a href="https://acai.gmbh">    
  <img src="https://github.com/acai-consulting/acai.public/raw/main/logo/logo.png" alt="acai logo" title="ACAI" align="right" height="100" />
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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_organizations_organizational_unit.level_1_ous](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | resource |
| [aws_organizations_organizational_unit.level_2_ous](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | resource |
| [aws_organizations_organizational_unit.level_3_ous](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | resource |
| [aws_organizations_organizational_unit.level_4_ous](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | resource |
| [aws_organizations_organizational_unit.level_5_ous](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | resource |
| [aws_organizations_organization.organization](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_organizational_units"></a> [organizational\_units](#input\_organizational\_units) | The organization with the tree of organizational units and their tags. | <pre>object({<br>    level1_units = optional(list(object({<br>      name = string,<br>      tags = optional(map(string), {}),<br>      level2_units = optional(list(object({<br>        name = string,<br>        tags = optional(map(string), {}),<br>        level3_units = optional(list(object({<br>          name = string,<br>          tags = optional(map(string), {}),<br>          level4_units = optional(list(object({<br>            name = string,<br>            tags = optional(map(string), {}),<br>            level5_units = optional(list(object({<br>              name = string,<br>              tags = optional(map(string), {}),<br>            })), [])<br>          })), [])<br>        })), [])<br>      })), [])<br>    })), [])<br>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_level_1_ous_details"></a> [level\_1\_ous\_details](#output\_level\_1\_ous\_details) | Details of Level 1 Organizational Units. |
| <a name="output_level_2_ous_details"></a> [level\_2\_ous\_details](#output\_level\_2\_ous\_details) | Details of Level 2 Organizational Units. |
| <a name="output_level_3_ous_details"></a> [level\_3\_ous\_details](#output\_level\_3\_ous\_details) | Details of Level 3 Organizational Units. |
| <a name="output_level_4_ous_details"></a> [level\_4\_ous\_details](#output\_level\_4\_ous\_details) | Details of Level 4 Organizational Units. |
| <a name="output_level_5_ous_details"></a> [level\_5\_ous\_details](#output\_level\_5\_ous\_details) | Details of Level 5 Organizational Units. |
| <a name="output_organization_id"></a> [organization\_id](#output\_organization\_id) | The ID of the AWS Organization. |
| <a name="output_ou_transformed"></a> [ou\_transformed](#output\_ou\_transformed) | List of transformed OUs. |
| <a name="output_root_ou_id"></a> [root\_ou\_id](#output\_root\_ou\_id) | The ID of the root organizational unit. |
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
