locals {
  default_cluster_addons = {
    kube-proxy = {
      addon_version = var.eks_addon_version_kube_proxy
      preserve      = false
    }
    vpc-cni = {
      addon_version  = var.eks_addon_version_vpc_cni
      before_compute = true
      preserve       = false
    }
    coredns = {
      addon_version = var.eks_addon_version_coredns
      configuration_values = jsonencode({
        computeType = "Fargate"
      })
      preserve = false
    }
  }

  observability_cluster_addon = {
    amazon-cloudwatch-observability = {
      addon_version            = var.eks_addon_version_amazon_cloudwatch_observability
      service_account_role_arn = var.eks_addon_observability_enabled ? aws_iam_role.cloudwatch_observability[0].arn : null
      configuration_values = jsonencode({
        containerLogs = {
          enabled = false
        }
      })
      preserve = false
    }
  }

  cluster_addons = var.account_decommissioned ? {} : var.eks_addon_observability_enabled ? merge(local.default_cluster_addons, local.observability_cluster_addon) : local.default_cluster_addons
}

module "eks" {
  count   = var.account_decommissioned ? 0 : 1
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  authentication_mode            = var.eks_cluster_authentication_mode
  cluster_addons                 = local.cluster_addons
  cluster_endpoint_public_access = true
  cluster_name                   = var.eks_cluster_name
  cluster_version                = var.eks_cluster_version
  enable_auto_mode_custom_tags   = false
  subnet_ids                     = var.private_subnet_ids
  vpc_id                         = var.vpc_id

  # creates "/aws/eks/${var.name}/cluster" Cloudwatch Log Group
  create_cloudwatch_log_group            = true
  cloudwatch_log_group_retention_in_days = 90
  cloudwatch_log_group_kms_key_id        = null
  cloudwatch_log_group_class             = "STANDARD"

  cluster_enabled_log_types = [
    # https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html
    "audit",
    "api",
    "authenticator",
    #"controllerManager",
    #"scheduler"
  ]

  # This is used to ensure the terraform role has relevant access to the cluster's KMS key
  kms_key_enable_default_policy = true
  kms_key_owners                = var.kms_key_owners
  kms_key_administrators        = var.kms_key_administrators

  fargate_profiles = var.account_decommissioned ? {} : var.fargate_profiles

  node_security_group_additional_rules = {
    ingress_alb_traffic = {
      description = "Allow TCP inbound traffic from the VPC, so that ALBs may route to the EKS cluster nodes"
      type        = "ingress"
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      cidr_blocks = var.public_subnet_cidr_blocks
    }
  }

  node_security_group_tags = {
    "karpenter.sh/discovery" = var.eks_cluster_name
  }

  tags = var.eks_module_tags
}

resource "aws_eks_access_entry" "terraform_admin" {
  cluster_name  = module.eks.cluster_name
  principal_arn = var.kubernetes_admin_role_arn
  type          = "STANDARD"
  depends_on    = [ module.eks ]
}

resource "aws_eks_access_policy_association" "terraform_admin" {
  cluster_name  = module.eks.cluster_name
  principal_arn = var.kubernetes_admin_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
  depends_on = [ module.eks ]

}

# Would have ideally used 'aws_vpc_security_group_egress_rule' and 'aws_vpc_security_group_ingress_rule' resources.
# However the TF documentation states NOT to mix these with the 'aws_security_group_rule' resource, which the EKS module uses
resource "aws_security_group_rule" "ec2_node_egress_fargate_node" {
  count                    = var.account_decommissioned ? 0 : 1
  security_group_id        = module.eks.node_security_group_id
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "all"
  source_security_group_id = module.eks.cluster_primary_security_group_id
  description              = "Allow all egress from EKS EC2 nodes to EKS Fargate nodes"
}

resource "aws_security_group_rule" "ec2_node_ingress_fargate_node" {
  count                    = var.account_decommissioned ? 0 : 1
  security_group_id        = module.eks.node_security_group_id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "all"
  source_security_group_id = module.eks.cluster_primary_security_group_id
  description              = "Allow all ingress from EKS Fargate nodes to EKS EC2 nodes"
}

resource "aws_security_group_rule" "fargate_node_egress_ec2_node" {
  count                    = var.account_decommissioned ? 0 : 1
  security_group_id        = module.eks.cluster_primary_security_group_id
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "all"
  source_security_group_id = module.eks.node_security_group_id
  description              = "Allow all egress from EKS Fargate nodes to EKS EC2 nodes"
}

resource "aws_security_group_rule" "fargate_node_ingress_ec2_node" {
  count                    = var.account_decommissioned ? 0 : 1
  security_group_id        = module.eks.cluster_primary_security_group_id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "all"
  source_security_group_id = module.eks.node_security_group_id
  description              = "Allow all ingress from EKS EC2 nodes to EKS Fargate nodes"
}

# This is to preserve the existing behaviour where we used to have the EKS Primary Security Group
# attached to all EC2 nodes. Long term this rule should be removed as the EKS module is
# creating the necessary rules for all the inter-pod communication between EC2 nodes.
# We just don't have the time at the moment to test behaviour with this rule removed.
resource "aws_security_group_rule" "ec2_node_all_ingress_from_self" {
  count             = var.account_decommissioned ? 0 : 1
  security_group_id = module.eks.node_security_group_id
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
  self              = true
  description       = "Allow all ingress from EKS EC2 nodes to themselves"
}
