#------------------------------------------------------------------------------
# VPC Module
#------------------------------------------------------------------------------
module "vpc" {
  #checkov:skip=CKV_TF_1: "Ensure Terraform module sources use a commit hash" | This is delibrate.

  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "${local.name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  private_subnet_names = []
  public_subnet_names  = []

  manage_default_network_acl = true
  default_network_acl_tags   = { Name = "${local.name}-default" }

  manage_default_route_table = true
  default_route_table_tags   = { Name = "${local.name}-default" }

  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.name}-default" }

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_vpn_gateway  = false
  enable_dhcp_options = false

  public_subnet_tags = {
    "scope"                  = "public"
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "scope"                           = "private"
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}
