variable "vault_name" {
  type        = string
  description = "Unique name for the backup vault"
  default     = "NcrBackupVault"
}

variable "backup_service_role_arn" {
  type        = string
  description = "AWS Backup service role ARN"
}

