locals {
  eks_cluster_name = var.eks_cluster_name != "" ? replace(var.eks_cluster_name, ".", "-") : replace("${var.account_name}-services", ".", "-")
}

module "eks_cluster" {
  source = "./modules/eks-cluster"

  account_decommissioned = local.account_decommissioned

  eks_cluster_name                                  = local.eks_cluster_name
  eks_cluster_version                               = var.eks_cluster_version
  eks_cluster_authentication_mode                   = "API_AND_CONFIG_MAP"
  eks_addon_version_kube_proxy                      = var.eks_addon_version_kube_proxy
  eks_addon_version_vpc_cni                         = var.eks_addon_version_vpc_cni
  eks_addon_version_coredns                         = var.eks_addon_version_coredns
  eks_addon_observability_enabled                   = var.eks_addon_observability_enabled
  eks_addon_version_amazon_cloudwatch_observability = var.eks_addon_version_amazon_cloudwatch_observability

  kms_key_owners         = [data.aws_iam_role.eks_cluster_admin.arn]
  kms_key_administrators = [tolist(data.aws_iam_roles.infrastructure_admin_sso_role.arns)[0]]

  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnets
  public_subnet_cidr_blocks = module.vpc.public_subnets_cidr_blocks

  kubernetes_admin_role_arn = data.aws_iam_role.eks_cluster_admin.arn

  fargate_profiles = {
    for namespace in var.eks_fargate_namespaces :
    replace(namespace.name, "-", "_") => {
      name                     = namespace.name
      iam_role_name            = namespace.iam_role_name != null ? namespace.iam_role_name : "${local.eks_cluster_name}-fp-${namespace.name}"
      iam_role_use_name_prefix = false
      selectors = [
        {
          namespace = namespace.name
        }
      ]
    }
  }
  cloudwatch_log_group_names = [for log_group in aws_cloudwatch_log_group.eks : log_group.name]
}

# EKS creates the terraform_admin access entry for us
# We think this is because it is the role that is used to create the cluster
# import {
#   to = module.eks_cluster.aws_eks_access_entry.terraform_admin
#   id = "${local.eks_cluster_name}:${data.aws_iam_role.eks_cluster_admin.arn}"
# }
