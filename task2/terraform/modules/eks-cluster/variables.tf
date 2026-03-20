variable "vpc_id" {
  type        = string
  description = "The ID of the VPC in which to create the EKS cluster"
}

variable "eks_cluster_name" {
  type        = string
  description = "The name of the EKS cluster"
  default     = "example-cluster"
}

variable "eks_module_tags" {
  type        = map(string)
  description = "The defalt set of tags that the EKS module will apply to all resources it creates."
  default     = {}
}

variable "eks_cluster_authentication_mode" {
  type        = string
  description = "The EKS Cluster authentication mode."
  default     = "CONFIG_MAP"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "A list of subnet IDs in which to place the EKS cluster and nodes"
}

variable "public_subnet_cidr_blocks" {
  type        = list(string)
  description = "A list of CIDR blocks for public subnets in which ALBs exposing the cluster are hosted"
}

variable "kms_key_owners" {
  type        = list(string)
  description = "ARN of the IAM Roles that can manage the EKS KMS Key"
}

variable "kms_key_administrators" {
  type        = list(string)
  description = "ARN of the IAM Roles that can administer the EKS KMS Key"
}

variable "kubernetes_admin_role_arn" {
  type        = string
  description = "The ARN of the Kubernetes Admin role in this account, e.g. arn:aws:iam::123456789012:role/terraform-infratask2Admin"
}

variable "fargate_profiles" {
  type        = any
  description = "The map of Fargate profiles that the EKS module will create."
  default = {
    kube_system = {
      name = "kube-system"
      selectors = [
        {
          namespace = "kube-system"
        }
      ]
    }
  }
}

variable "eks_cluster_version" {
  type        = string
  default     = "1.31"
  description = "The EKS Cluster version"
}

variable "eks_addon_version_kube_proxy" {
  type        = string
  default     = "v1.28.2-eksbuild.2"
  description = "EKS kube-proxy add-on version"
}

variable "eks_addon_version_vpc_cni" {
  type        = string
  default     = "v1.15.1-eksbuild.1"
  description = "EKS vpc-cni add-on version"
}

variable "eks_addon_version_coredns" {
  type        = string
  default     = "v1.10.1-eksbuild.4"
  description = "EKS coredns add-on version"
}

variable "eks_addon_version_amazon_cloudwatch_observability" {
  type        = string
  default     = "v3.7.0-eksbuild.1"
  description = "EKS amazon cloudwatch observability add-on version"
}

variable "eks_addon_observability_enabled" {
  type        = bool
  default     = false
  description = "EKS amazon cloudwatch observability add-on enabled"
}

variable "account_decommissioned" {
  type        = bool
  description = "Whether the account is decommissioned"
  default     = false
}

variable "cloudwatch_log_group_names" {
  type        = list(string)
  description = "A list of EKS CloudWatch log group names"
  default     = []
}
