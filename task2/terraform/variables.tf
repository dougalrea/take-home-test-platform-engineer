variable "environment" {
  type        = string
  description = "Environment name"
}

variable "account_type" {
  type        = string
  description = "Type of the AWS account"

  validation {
    condition     = var.account_type == "main" || var.account_type == "partner"
    error_message = "The account_type value must be either 'main' or 'partner'"
  }
}

variable "main_aws_account_id" {
  type        = string
  description = "For partner accounts, what is the AWS Account ID of the main account"
  default     = ""
}

variable "main_aws_account_state_config" {
  type = object({
    bucket = string
    key    = string
    region = string
  })
  description = "Specify to override state config derived from the account id"
  default     = null
}

variable "domain_name" {
  type        = string
  description = "Domain name for the account"
}

variable "partner_id" {
  type        = string
  description = "Partner ID to be used for Route53 and ACM"
}

variable "customer_name_prefixes" {
  type        = list(string)
  description = "Prefix of the customer domain names"
  default     = []
}

variable "account_name" {
  type        = string
  description = "Name of the AWS account"
}

variable "metaflow_db_identifier_prefix" {
  type        = string
  description = "Identifier prefix for the RDS instance"
  default     = ""
}

variable "metaflow_resource_prefix" {
  type        = string
  description = "The prefix to use for all Metaflow resources"
  default     = ""
}

variable "metaflow_resource_suffix" {
  type        = string
  description = "The suffix to use for all Metaflow resources"
  default     = ""
}

variable "metaflow_nice_load_balancer_names" {
  type        = bool
  description = "Whether to use a readable name for the Metaflow load balancers"
  default     = true
}

variable "metaflow_old_config_bucket_allow_ssl_requests_only" {
  type        = bool
  description = "If true, only SSL requests will be allowed for the old Metaflow config bucket"
  default     = true
}

variable "metaflow_old_config_bucket_allow_encrypted_uploads_only" {
  type        = bool
  description = "If true, only encrypted uploads will be allowed for the old Metaflow config bucket"
  default     = true
}

variable "metaflow_old_config_bucket_enforce_tls_version" {
  type        = bool
  description = "If true, TLS version enforcement will be applied for the old Metaflow config bucket"
  default     = true
}

variable "metaflow_bucket_name" {
  type        = string
  description = "Name of the Metaflow S3 bucket"
}

variable "metaflow_db_snapshot_identifier" {
  type        = string
  description = "The snapshot identifier to restore the Metaflow Metadata RDS instance from, or leave blank to create a new instance"
  default     = null
}

variable "metaflow_db_multi_az" {
  type        = bool
  description = "Enable Multi-AZ for the Metaflow Metadata RDS instance"
  default     = true
}

variable "metaflow_role_secrets_arns_additional" {
  type        = list(string)
  description = "Additional Secrets ARNs with Read access for the Metaflow role"
  default     = []
}

variable "metaflow_config_bucket_allow_ssl_requests_only" {
  type        = bool
  description = "If true, only SSL requests will be allowed for the metaflow config bucket"
  default     = true
}

variable "metaflow_config_bucket_allow_encrypted_uploads_only" {
  type        = bool
  description = "If true, only encrypted uploads will be allowed for the metaflow config bucket"
  default     = true
}

variable "metaflow_config_bucket_enforce_tls_version" {
  type        = bool
  description = "If true, TLS version enforcement will be applied for the metaflow config bucket"
  default     = true
}

variable "vpc_endpoints_services" {
  type        = list(string)
  description = "List of AWS services we will create Interface type VPC Endpoints for"
  # https://docs.aws.amazon.com/vpc/latest/privatelink/aws-services-privatelink-support.html
  # https://docs.aws.amazon.com/eks/latest/userguide/private-clusters.html
  # https://aws.github.io/aws-eks-best-practices/karpenter/#amazon-eks-private-cluster-without-outbound-internet-access
  # karpenter requires SSM, external-dns requires Route53 (not currently supported by VPCE), RDS clients use secretsmanager
  #default = ["ec2", "ecr.api", "ecr.dkr", "elasticloadbalancing", "logs", "sts", "ssm", "secretsmanager", "email-smtp"]
  default = ["ssm", "ssmmessages", "sqs", "kms"]
}

variable "eks_cluster_version" {
  type        = string
  default     = "1.34"
  description = "The EKS Cluster version"
}

variable "eks_cluster_admin_iam_role_name" {
  type        = string
  description = "The IAM Role used to administer the EKS Cluster and it's KMS Key."
  default     = "terraform-admin"
}

variable "eks_cluster_name" {
  type        = string
  description = "The name of the EKS Cluster rather than using the default generated name"
  default     = ""
}

variable "eks_fargate_namespaces" {
  type = list(object({
    name          = string
    iam_role_name = optional(string)
  }))
  description = "The list of namespaces that will be run on Fargate, with optional IAM role name."
  default = [
    {
      name = "kube-system"
    }
  ]
}

variable "eks_addon_version_kube_proxy" {
  type        = string
  default     = "v1.34.0-eksbuild.4"
  description = "EKS kube-proxy add-on version"
}

variable "eks_addon_version_vpc_cni" {
  type        = string
  default     = "v1.20.4-eksbuild.1"
  description = "EKS vpc-cni add-on version"
}

variable "eks_addon_version_coredns" {
  type        = string
  default     = "v1.12.4-eksbuild.1"
  description = "EKS coredns add-on version"
}

variable "eks_addon_version_amazon_cloudwatch_observability" {
  type        = string
  default     = "v4.6.0-eksbuild.1"
  description = "EKS amazon cloudwatch observability add-on version"
}

variable "eks_addon_observability_enabled" {
  type        = bool
  default     = true
  description = "EKS amazon cloudwatch observability add-on enabled"
}

variable "karpenter_chart_version" {
  type        = string
  description = "Chart version for Karpenter"
  default     = "1.8.2"
}

variable "karpenter_namespace" {
  type        = string
  description = "Namespace for Karpenter"
  default     = "kube-system"
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

variable "karpenter_nodepool_limits_default" {
  type = object({
    cpu    = string
    memory = string
  })

  description = "Overall limits for Karpenter default NodePool"
  default = {
    cpu    = "48"
    memory = "2000Gi"
  }
}

variable "karpenter_nodepool_limits_metaflow" {
  type = object({
    cpu    = string
    memory = string
  })

  description = "Overall limits for Karpenter metaflow NodePool"
  default = {
    cpu    = "450"
    memory = "3500Gi"
  }
}

variable "share_bucket_name" {
  type        = string
  description = "Name of the share bucket"
}

variable "share_bucket_allow_ssl_requests_only" {
  type        = bool
  description = "If true, only SSL requests will be allowed for the share bucket"
  default     = true
}

variable "share_bucket_allow_encrypted_uploads_only" {
  type        = bool
  description = "If true, only encrypted uploads will be allowed for the share bucket"
  default     = true
}

variable "share_bucket_enforce_tls_version" {
  type        = bool
  description = "If true, TLS version enforcement will be applied for the share bucket"
  default     = true
}

variable "catalog_bucket_encryption_scheme" {
  type        = string
  default     = "SSE-KMS"
  description = "Whether we are using SSE-S3 or SSE-KMS encryption scheme."
}

variable "create_catalog_bucket_kms_key" {
  type        = bool
  description = "Create a KMS Key for the catalog bucket"
  default     = true
}

variable "catalog_bucket_name" {
  type        = string
  description = "Name of the catalog bucket"
}

variable "catalog_bucket_allow_ssl_requests_only" {
  type        = bool
  description = "If true, only SSL requests will be allowed for the catalog bucket"
  default     = true
}

variable "catalog_bucket_allow_encrypted_uploads_only" {
  type        = bool
  description = "If true, only encrypted uploads will be allowed for the catalog bucket"
  default     = true
}

variable "catalog_bucket_enforce_tls_version" {
  type        = bool
  description = "If true, TLS version enforcement will be applied for the catalog bucket"
  default     = true
}

variable "account_state" {
  type        = string
  description = "Is this account 'pre-commissioned', 'commissioned', 'pre-decommissioned' or 'decommissioned'."
  default     = "commissioned"

  validation {
    condition     = contains(["pre-commissioned", "commissioned", "pre-decommissioned", "decommissioned"], var.account_state)
    error_message = "Value must be one of 'pre-commissioned', 'commissioned', 'pre-decommissioned' or 'decommissioned'."
  }
}

variable "create_helm_reloader" {
  type        = bool
  description = "Whether to deploy the reloader helm chart"
  default     = false
}

variable "create_wildcard_certificates" {
  type        = bool
  description = "Whether to create wildcard certificates for the domain"
  default     = false
}

variable "enable_auth0" {
  type        = bool
  description = "Whether to enable Auth0 module"
  default     = false
}

variable "enable_auth0_staging" {
  type        = bool
  description = "Whether to enable Auth0 module for the staging tenant"
  default     = false
}

variable "auth0_secret_id" {
  type        = string
  description = "Secret ID for Auth0 credentials stored in AWS Secrets Manager"
  default     = ""
}

variable "create_metaflow_datastore_kms_key_policy" {
  type        = bool
  description = "Whether to create catalog S3 bucket KMS Key policy"
  default     = true
}

variable "cloudwatch_data_protection_findings_bucket_allow_ssl_requests_only" {
  type        = bool
  description = "If true, only SSL requests will be allowed for the CloudWatch Data Protection findings bucket"
  default     = true
}

variable "cloudwatch_data_protection_findings_bucket_allow_encrypted_uploads_only" {
  type        = bool
  description = "If true, only encrypted uploads will be allowed for the CloudWatch Data Protection findings bucket"
  default     = true
}

variable "cloudwatch_data_protection_findings_bucket_enforce_tls_version" {
  type        = bool
  description = "If true, TLS version enforcement will be applied for the CloudWatch Data Protection findings bucket"
  default     = true
}

variable "enable_vpc_cidr_automation" {
  description = "Enable or disable the automatic VPC CIDR and subnet calculation"
  type        = bool
  default     = true
}
