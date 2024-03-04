data "template_file" "org_cloudtrail_admin" {
  template = file("${path.module}/org_cloudtrail_admin.yaml.tftpl")
  vars = {
    cloudwatch_loggroup_name = var.cloudwatch_loggroup.loggroup_name
    cloudwatch_role_name_with_path = replace("/${var.cloudwatch_loggroup.iam_role_path}/${var.cloudwatch_loggroup.iam_role_name}", "////", "/")
  }
}

data "template_file" "org_cloudtrail_bucket" {
  template = file("${path.module}/org_cloudtrail_bucket.yaml.tftpl")
  vars = {
    target_principal_role_name = "var.target_principal_settings.target_principal_name"
    target_principal_role_path = "var.target_principal_settings.role_path"
    trustee_role_arn           = "var.target_principal_settings.pipeline_principal_arn"
    resource_tags_block        = "local.resource_tags_rendered"
  }
}

data "template_file" "bucket_notification_sns" {
  template = file("${path.module}/bucket_notification_sns.yaml.tftpl")
  vars = {
    target_principal_role_name = "var.target_principal_settings.target_principal_name"
    target_principal_role_path = "var.target_principal_settings.role_path"
    trustee_role_arn           = "var.target_principal_settings.pipeline_principal_arn"
    resource_tags_block        = "local.resource_tags_rendered"
  }
}

output "cf_template_map" {
  value = {
    "org_cloudtrail_admin.yaml.tftpl" = replace(data.template_file.org_cloudtrail_admin.rendered, "$$$", "$$")
    "org_cloudtrail_bucket.yaml.tftpl" = replace(data.template_file.org_cloudtrail_bucket.rendered, "$$$", "$$")
    "bucket_notification_sns.yaml.tftpl" = replace(data.template_file.bucket_notification_sns.rendered, "$$$", "$$")
  }
}
