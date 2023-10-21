#------------------------------------------------------------------------------
# Locals
#------------------------------------------------------------------------------
locals {
  region           = var.region
  environment      = var.environment
  prefix           = var.prefix
  name             = "${var.prefix}-${var.environment}"
  name_pascal_case = replace(title(replace(local.name, "-", " ")), " ", "")
  azs              = slice(data.aws_availability_zones.available.names, 0, 3)

  domain_name = "graylog.${data.aws_route53_zone.this.name}"

  tags = {
    environment = var.environment,
    ManagedBy   = "Terraform"
  }
}

#------------------------------------------------------------------------------
# Data
#------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_canonical_user_id" "current" {}
data "aws_availability_zones" "available" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

#------------------------------------------------------------------------------
# Supporting Resources
#------------------------------------------------------------------------------
#resource "random_pet" "this" {
#  length = 2
#}
