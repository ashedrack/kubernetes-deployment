region = "us-east-1"

# set with TF_VAR_assume_role_arn
# assume_role_arn         = "arn:aws:iam::123456789012:role/ci-runner"
assume_role_external_id = "ci-runner"

prefix            = "graylog"
route53_zone_name = "joeyomi.69ideas.com"

eks_admin_users = [
  "joseph.oyomi",
  "terraform-runner",
]
