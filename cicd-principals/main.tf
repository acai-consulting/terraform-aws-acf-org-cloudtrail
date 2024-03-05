data "template_file" "org_cloudtrail_admin" {
  template = file("${path.module}/org_cloudtrail_admin.yaml.tftpl")
  vars = {
    cloudwatch_loggroup_name       = var.cloudwatch_loggroup.loggroup_name
    cloudwatch_role_name_with_path = replace("/${var.cloudwatch_loggroup.iam_role_path}/${var.cloudwatch_loggroup.iam_role_name}", "////", "/")
  }
}

data "template_file" "org_cloudtrail_bucket" {
  template = file("${path.module}/org_cloudtrail_bucket.yaml.tftpl")
  vars = {
    bucket_prefix                   = var.s3_bucket.bucket_name == null ? var.s3_bucket.bucket_prefix : var.s3_bucket.bucket_name
    bucket_notification_to_sns_name = var.s3_bucket.notification_to_sns == null ? "" : var.s3_bucket.notification_to_sns.sns_name
  }
}


output "cf_template_map" {
  value = {
    "org_cloudtrail_admin.yaml.tftpl"  = replace(data.template_file.org_cloudtrail_admin.rendered, "$$$", "$$")
    "org_cloudtrail_bucket.yaml.tftpl" = replace(data.template_file.org_cloudtrail_bucket.rendered, "$$$", "$$")
  }
}
