variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "eks_oidc_provider_arn" {
  description = "The ARN of the EKS cluster OIDC Provider"
  type        = string
}

variable "eks_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  type        = string
}

variable "account_decommissioned" {
  type        = bool
  description = "Is this AWS Account in a decommissioned state?"
  default     = false
}

variable "karpenter_chart_version" {
  type        = string
  description = "Chart version for Karpenter"
  default     = "1.4.0"
}

variable "karpenter_namespace" {
  type        = string
  description = "Namespace for Karpenter"
}

variable "karpenter_replicas" {
  type        = string
  description = "Replicas for Karpenter"
  default     = "2"
}

variable "karpenter_log_level" {
  type        = string
  description = "Log level for Karpenter"
  default     = "info"
}

variable "karpenter_cpu" {
  type = object({
    request = string
    limit   = string
  })

  description = "CPU for Karpenter"
  default = {
    request = "1"
    limit   = "2"
  }
}

variable "karpenter_memory" {
  type = object({
    request = string
    limit   = string
  })

  description = "Memory for Karpenter"
  default = {
    request = "2Gi"
    limit   = "4Gi"
  }
}

variable "karpenter_additional_node_iam_role_arns" {
  description = "Additional ARNs for Karpenter node roles"
  type        = list(string)
  default     = []
}

