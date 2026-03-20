variable "nodeclass_name" {
  type        = string
  description = "Name of the Karpenter node class"
}

variable "eks_cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "ami_alias" {
  type        = string
  description = "AMI alias to use for the Karpenter node class"
  default     = "al2023@latest"
}

variable "detailed_monitoring" {
  type        = bool
  description = "Enable detailed monitoring for the Karpenter node class"
  default     = true
}

variable "create_eks_access_entry" {
  type        = bool
  description = "Create an EKS access entry for the Karpenter node class"
  default     = true
}

variable "enable_instance_store_policy" {
  type        = bool
  description = "Enable instance store policy for the Karpenter node class"
  default     = false
}
