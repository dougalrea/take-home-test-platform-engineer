variable "backup_service_role_name" {
  type        = string
  description = "Unique name for the backup service IAM Role, leave blank for no IAM Role"
  default     = "NcrInfrastructureTest1BackupRole"
}

