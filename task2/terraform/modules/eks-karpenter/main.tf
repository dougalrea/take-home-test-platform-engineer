data "aws_region" "current" {}

data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

resource "helm_release" "karpenter_crd" {
  count = var.account_decommissioned ? 0 : 1

  name       = "karpenter-crd"
  repository = "oci://public.ecr.aws/karpenter"
  version    = var.karpenter_chart_version
  namespace  = var.karpenter_namespace
  chart      = "karpenter-crd"
}

resource "helm_release" "karpenter" {
  count = var.account_decommissioned ? 0 : 1

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  version    = var.karpenter_chart_version
  namespace  = var.karpenter_namespace
  chart      = "karpenter"
  skip_crds  = true

  values = [
    <<-EOT
    replicas: ${var.karpenter_replicas}
    logLevel: ${var.karpenter_log_level}
    controller:
      resources:
        requests:
          cpu: ${var.karpenter_cpu.request}
          memory: ${var.karpenter_memory.request}
        limits:
          cpu: ${var.karpenter_cpu.limit}
          memory: ${var.karpenter_memory.limit}
    settings:
      clusterName: ${var.eks_cluster_name}
      interruptionQueue: Karpenter-${var.eks_cluster_name}
      batchMaxDuration: 20s
      batchIdleDuration: 2s
    podLabels:
      eks.amazonaws.com/fargate-profile: ${var.karpenter_namespace}
    serviceAccount:
      name: karpenter
      annotations:
        eks.amazonaws.com/role-arn: ${aws_iam_role.karpenter_controller.arn}
    EOT
  ]

  depends_on = [
    helm_release.karpenter_crd[0]
  ]
}

module "karpenter_sqs" {
  # We're using this module to create the SQS queue used by the Karpenter application.
  count   = var.account_decommissioned ? 0 : 1
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.0"

  cluster_name           = var.eks_cluster_name
  irsa_oidc_provider_arn = var.eks_oidc_provider_arn

  # This module creates a role name with a datetime suffix, e.g. karpeneter-20231117144207681300000002
  # We want a consistent name for Helm Charts to use across AWS environments, so we we create this ourselves
  create_iam_role         = false
  create_node_iam_role    = false
  create_access_entry     = false
  create_instance_profile = false
}
