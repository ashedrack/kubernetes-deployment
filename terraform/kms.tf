#------------------------------------------------------------------------------
# KMS
#------------------------------------------------------------------------------

resource "aws_kms_key" "eks" {
  description             = "AWS KMS for ${local.name_pascal_case}"
  is_enabled              = true
  enable_key_rotation     = true
  deletion_window_in_days = 7
  policy                  = data.aws_iam_policy_document.kms_policy.json

  tags = local.tags
}

resource "aws_kms_alias" "eks" {
  target_key_id = aws_kms_key.eks.id
  name          = "alias/${local.name}"
}


## IAM
data "aws_iam_policy_document" "kms_policy" {
  # checkov:CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
  # checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  # checkov:CKV_AWS_356: "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions"
  statement {
    sid     = "KeyOwnerPolicy"
    effect  = "Allow"
    actions = ["kms:*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudTrailAccessKMS"
    effect = "Allow"

    actions = [
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
      "kms:Decrypt",
    ]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudWatchAccessKMS"
    effect = "Allow"

    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }
    resources = ["*"]
  }

  statement {
    sid    = "AllowSecretsManagerAccessKMS"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:DescribeKey"
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringEquals"
      values   = ["secretsmanager.${var.region}.amazonaws.com"]
      variable = "kms:ViaService"
    }
    resources = ["*"]
  }
}