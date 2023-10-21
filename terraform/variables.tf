variable "region" {
  type        = string
  description = "Default AWS region."
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Current Environment"
}

variable "prefix" {
  type        = string
  description = "Prefix to prepend to resources (for easy identification)."
}



variable "assume_role_arn" {
  type        = string
  description = "AWS role to assume when provisioning resources"
  default     = ""
}

variable "assume_role_external_id" {
  type        = string
  description = "Extenal ID associated with the \"assume_role_arn\"."
  default     = ""
}

variable "route53_zone_name" {
  type        = string
  description = "Route 53 Zone name."
  default     = null
}

variable "cluster_version" {
  type        = string
  description = "EKS Cluster version"
  default     = "1.27"
}

variable "eks_admin_users" {
  description = "IAM users (username) to add to the eks admins group."
  type        = list(string)

  default = []
}