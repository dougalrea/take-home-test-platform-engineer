output "backup_vault_kms_key" {
  value       = aws_kms_key.vault
  description = "KMS key for AWS Backup vault"
}

output "backup_vault" {
  value       = aws_backup_vault.this
  description = "AWS Backup vault"
}

output "backup_vault_policy" {
  value       = aws_backup_vault_policy.this
  description = "AWS Backup vault policy"
}

