output "name" {
  value = var.nodeclass_name
}

output "role_arn" {
  value = aws_iam_role.this.arn
}

output "access_entry_arn" {
  value = var.create_eks_access_entry ? aws_eks_access_entry.this[0].access_entry_arn : null
}
