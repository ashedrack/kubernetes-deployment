module "allow_eks_access_iam_policy" {
  #checkov:skip=CKV_TF_1: "Ensure Terraform module sources use a commit hash" | This is delibrate.

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.30.0"

  name          = "${local.name}-allow-eks-access"
  create_policy = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:DescribeCluster",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

module "eks_admins_iam_role" {
  #checkov:skip=CKV_TF_1: "Ensure Terraform module sources use a commit hash" | This is delibrate.

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.30.0"

  role_name         = "${local.name}-eks-admin"
  create_role       = true
  role_requires_mfa = false

  custom_role_policy_arns = [module.allow_eks_access_iam_policy.arn]

  trusted_role_arns = [
    "arn:aws:iam::${module.vpc.vpc_owner_id}:root"
  ]
}

module "allow_assume_eks_admins_iam_policy" {
  #checkov:skip=CKV_TF_1: "Ensure Terraform module sources use a commit hash" | This is delibrate.

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.30.0"

  name          = "${local.name}-allow-assume-eks-admin-iam-role"
  create_policy = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect   = "Allow"
        Resource = module.eks_admins_iam_role.iam_role_arn
      },
    ]
  })
}

module "eks_admins_iam_group" {
  #checkov:skip=CKV_TF_1: "Ensure Terraform module sources use a commit hash" | This is delibrate.

  source  = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"
  version = "5.30.0"

  name                              = "${local.name}-eks-admin"
  attach_iam_self_management_policy = false
  create_group                      = true
  group_users                       = var.eks_admin_users
  custom_group_policy_arns          = [module.allow_assume_eks_admins_iam_policy.arn]
}

data "aws_iam_role" "ci_runner" {
  name = "ci-runner"
}

data "aws_iam_user" "admins" {
  for_each  = toset(var.eks_admin_users)
  user_name = each.key
}
