locals {
  nodepool_default_consolidate_after_minutes  = var.account_state == "commissioned" ? "60" : "1"
  nodepool_metaflow_consolidate_after_minutes = var.account_state == "commissioned" ? "5" : "1"
}

module "karpenter" {
  source = "./modules/eks-karpenter"

  account_decommissioned  = local.account_decommissioned
  eks_cluster_name        = module.eks_cluster.cluster_name
  eks_oidc_provider_arn   = module.eks_cluster.eks_oidc_provider_arn
  eks_oidc_issuer_url     = module.eks_cluster.eks_cluster_oidc_issuer_url
  karpenter_chart_version = var.karpenter_chart_version
  karpenter_namespace     = var.karpenter_namespace
  karpenter_replicas      = var.karpenter_replicas
  karpenter_log_level     = var.karpenter_log_level
  karpenter_cpu           = var.karpenter_cpu
  karpenter_memory        = var.karpenter_memory
  karpenter_additional_node_iam_role_arns = concat(
    [for nodeclass_default in module.karpenter_nodeclass_default : nodeclass_default.role_arn],
    [for nodeclass_metaflow in module.karpenter_nodeclass_metaflow : nodeclass_metaflow.role_arn]
  )

  depends_on = [
    helm_release.load_balancer_controller,
    # this prevents us from removing the karpenter chart before it's fargate profile is removed
    module.eks_cluster.fargate_profiles,
    module.eks_cluster.cluster_addons
  ]
}

# SPOT instances can be configured for Karpenter EC2 node classes
resource "aws_iam_service_linked_role" "ec2_spot" {
  description      = "SPOT access service role"
  aws_service_name = "spot.amazonaws.com"
}

module "karpenter_nodeclass_default" {
  count = local.account_decommissioned ? 0 : 1

  source = "./modules/eks-karpenter-nodeclass"

  nodeclass_name   = "default-nc"
  eks_cluster_name = module.eks_cluster.cluster_name

  depends_on = [
    module.karpenter.helm_release_karpenter_id
  ]
}

module "karpenter_nodeclass_metaflow" {
  count = local.account_decommissioned ? 0 : 1

  source = "./modules/eks-karpenter-nodeclass"

  nodeclass_name               = "metaflow-nc"
  eks_cluster_name             = module.eks_cluster.cluster_name
  enable_instance_store_policy = true

  depends_on = [
    module.karpenter.helm_release_karpenter_id
  ]
}

# https://github.com/aws/karpenter-provider-aws/tree/main/examples/v1
resource "kubectl_manifest" "karpenter_nodepool_default" {
  count = local.account_decommissioned ? 0 : 1

  yaml_body = <<-YAML
    ---
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: default
    spec:
      template:
        spec:
          requirements:
            - key: "kubernetes.io/arch"
              operator: In
              values: ["arm64"]
            - key: "kubernetes.io/os"
              operator: In
              values: ["linux"]
            - key: "karpenter.sh/capacity-type"
              operator: In
              values: ["on-demand"]
            - key: "karpenter.k8s.aws/instance-category"
              operator: In
              values: ["c", "m", "r"]
            - key: "karpenter.k8s.aws/instance-generation"
              operator: Gt
              values: ["4"]
            - key: "topology.kubernetes.io/zone"
              operator: In
              values: [${join(", ", [for zone in sort(data.aws_availability_zones.available.names) : format("%q", zone)])}]
          nodeClassRef:
            group: karpenter.k8s.aws
            kind: EC2NodeClass
            name: ${module.karpenter_nodeclass_default[0].name}
          expireAfter: 168h # expire nodes after 7 days
          # https://github.com/aws/karpenter-provider-aws/issues/7521
          terminationGracePeriod: 30m
      limits:
        cpu: ${var.karpenter_nodepool_limits_default.cpu}
        memory: ${var.karpenter_nodepool_limits_default.memory}
      disruption:
        consolidationPolicy: WhenEmptyOrUnderutilized
        consolidateAfter: "${local.nodepool_default_consolidate_after_minutes}m"
  YAML
}

resource "kubectl_manifest" "karpenter_nodepool_metaflow" {
  count = local.account_decommissioned ? 0 : 1

  yaml_body = <<-YAML
    ---
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: metaflow
    spec:
      template:
        spec:
          requirements:
            - key: "kubernetes.io/arch"
              operator: In
              values: ["arm64"]
            - key: "kubernetes.io/os"
              operator: In
              values: ["linux"]
            - key: "karpenter.sh/capacity-type"
              operator: In
              values: ["on-demand"]
            - key: "karpenter.k8s.aws/instance-category"
              operator: In
              values: ["c", "m", "r"]
            - key: "karpenter.k8s.aws/instance-generation"
              operator: Gt
              values: ["4"]
            - key: "topology.kubernetes.io/zone"
              operator: In
              values: [${join(", ", [for zone in sort(data.aws_availability_zones.available.names) : format("%q", zone)])}]
          taints:
            - key: "nodepool"
              value: "metaflow"
              effect: "NoExecute"
          nodeClassRef:
            group: karpenter.k8s.aws
            kind: EC2NodeClass
            name: ${module.karpenter_nodeclass_metaflow[0].name}
          expireAfter: 72h # expire nodes after 3 days
          # https://github.com/aws/karpenter-provider-aws/issues/7521
          terminationGracePeriod: 2m
      limits:
        cpu: ${var.karpenter_nodepool_limits_metaflow.cpu}
        memory: ${var.karpenter_nodepool_limits_metaflow.memory}
      disruption:
        consolidationPolicy: WhenEmpty
        consolidateAfter: "${local.nodepool_metaflow_consolidate_after_minutes}m"
  YAML
}

resource "time_sleep" "wait_karpenter_nodepool_default" {
  count = local.account_decommissioned ? 0 : 1

  destroy_duration = "${local.nodepool_default_consolidate_after_minutes + 10}m"

  depends_on = [
    kubectl_manifest.karpenter_nodepool_default
  ]
}

resource "time_sleep" "wait_karpenter_nodepool_metaflow" {
  count = local.account_decommissioned ? 0 : 1

  destroy_duration = "${local.nodepool_metaflow_consolidate_after_minutes + 10}m"

  depends_on = [
    kubectl_manifest.karpenter_nodepool_metaflow
  ]
}

#
# GuardDuty EKS Addon, supports EC2 only
#

data "aws_eks_addon_version" "aws_guardduty_agent_default" {
  addon_name         = "aws-guardduty-agent"
  kubernetes_version = var.eks_cluster_version
}

resource "aws_eks_addon" "aws_guardduty_agent" {
  cluster_name                = module.eks_cluster.cluster_name
  addon_name                  = "aws-guardduty-agent"
  addon_version               = data.aws_eks_addon_version.aws_guardduty_agent_default.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    module.karpenter
  ]
}
