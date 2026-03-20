locals {
  fargate_profile_pod_execution_role_arns = [for group in module.eks_cluster.fargate_profiles : group.fargate_profile_pod_execution_role_arn]

  # EKS requires the /aws-reserved/sso.amazonaws.com/<region> path to be stripped
  # https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html
  eks_metaflow_sso_role_arns = [
    for parts in [for arn in data.aws_iam_roles.metaflow_sso_role.arns : split("/", arn)] :
    format("%s/%s", parts[0], element(parts, length(parts) - 1))
  ]
  eks_engineering_admin_sso_role_arns = [
    for parts in [for arn in data.aws_iam_roles.engineering_admin_sso_role.arns : split("/", arn)] :
    format("%s/%s", parts[0], element(parts, length(parts) - 1))
  ]
  eks_infrastructure_admin_sso_role_arns = [
    for parts in [for arn in data.aws_iam_roles.infrastructure_admin_sso_role.arns : split("/", arn)] :
    format("%s/%s", parts[0], element(parts, length(parts) - 1))
  ]

  eks_metaflow_user_aws_auth_configmap = length(local.eks_metaflow_sso_role_arns) > 0 ? [{
    rolearn  = local.eks_metaflow_sso_role_arns[0]
    username = "InfraTask2MetaflowUser:{{SessionName}}"
    groups   = ["ncr-infratask2-metaflow-user"]
  }] : []

  eks_engineering_admin_aws_auth_configmap = length(local.eks_engineering_admin_sso_role_arns) > 0 ? [{
    rolearn  = local.eks_engineering_admin_sso_role_arns[0]
    username = "InfraTask2EngineeringAdminAccess:{{SessionName}}"
    groups   = ["ncr-infratask2-engineering"]
  }] : []

  eks_infrastructure_admin_aws_auth_configmap = length(local.eks_infrastructure_admin_sso_role_arns) > 0 ? [{
    rolearn  = local.eks_infrastructure_admin_sso_role_arns[0]
    username = "InfraTask2InfrastructureAdminAccess:{{SessionName}}"
    groups   = ["ncr-infratask2-infrastructure"]
  }] : []

  eks_metaflow_role_aws_auth_configmap = [{
    rolearn  = aws_iam_role.metaflow.arn
    username = "${aws_iam_role.metaflow.name}:{{SessionName}}"
    groups   = ["${local.metaflow_name_prefix}-group"]
  }]
}

module "eks_aws_auth_configmap" {
  source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
  version = "~> 20.0"

  manage_aws_auth_configmap = true

  aws_auth_roles = concat(
    [for role_arn in local.fargate_profile_pod_execution_role_arns :
      {
        rolearn  = role_arn
        username = "system:node:{{SessionName}}"
        groups = [
          "system:bootstrappers",
          "system:nodes",
          "system:node-proxier",
        ]
      }
    ],
    [{
      rolearn  = data.aws_iam_role.eks_cluster_admin.arn
      username = "kubernetes-admin-role"
      groups = [
        "system:masters"
      ]
    }],
    local.eks_metaflow_user_aws_auth_configmap,
    local.eks_engineering_admin_aws_auth_configmap,
    local.eks_infrastructure_admin_aws_auth_configmap,
    local.eks_metaflow_role_aws_auth_configmap
  )
}

