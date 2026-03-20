output "karpenter_role_arn" {
  value = aws_iam_role.karpenter_controller.arn
}

output "karpenter_role_name" {
  value = aws_iam_role.karpenter_controller.name
}

output "helm_release_karpenter_id" {
  value = var.account_decommissioned ? null : helm_release.karpenter[0].id
}

