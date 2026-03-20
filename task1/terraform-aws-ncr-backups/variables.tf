variable "name" {
  type        = string
  description = "Suffix for backup resource names"
  default     = "ncr"
}

variable "aws_accounts_config" {
  type = list(object({
    email_address   = string
    backup_policies = optional(list(string), [])
  }))
  description = "Configuration of AWS Account backup policies"
  default = [
    {
      email_address = "aws.InfrastructureTest1.sandbox@test.natcapresearch.com",
      backup_policies = [
        "ncr-infratest1-rds-backup-policy-test",
        "ncr-infratest1-s3-backup-policy-test"
      ]
    }
  ]
}

variable "organizational_units_config" {
  type = list(object({
    name            = string
    parent_ou       = optional(string)
    backup_policies = optional(list(string), [])
  }))
  description = "Configuration of Organizational Unit backup policies"
  default = [
    {
      name = "workloads"
    },
    {
      name      = "prod"
      parent_ou = "workloads"
      backup_policies = [
        "ncr-infratest1-rds-backup-policy-prod",
        "ncr-infratest1-s3-backup-policy-prod"
      ]
    },
    {
      name      = "staging"
      parent_ou = "workloads"
      backup_policies = [
        "ncr-infratest1-rds-backup-policy-prod",
        "ncr-infratest1-s3-backup-policy-prod"
      ]
    },
    {
      name      = "test"
      parent_ou = "workloads"
      backup_policies = [
        "ncr-infratest1-rds-backup-policy-test",
        "ncr-infratest1-s3-backup-policy-test"
      ]
    },
    {
      name = "security"
      backup_policies = [
        "ncr-infratest1-s3-backup-policy-prod"
      ]
    },
  ]
}

variable "rds_backup_vault_min_retention" {
  type        = number
  description = "The minimum locked retention for our RDS secondary vault."
  default     = 92 # 3 months
}

variable "rds_backup_vault_max_retention" {
  type        = number
  description = "The maximum locked retention for our RDS secondary vault."
  default     = 2192 # 6 years
}

variable "rds_regions" {
  type        = list(string)
  description = "The regions in which AWS Backup will match resource selections for RDS backup"
  default = [
    "eu-west-1"
  ]
}

variable "rds_secondary_vault_region" {
  type        = string
  description = "The region in which AWS Backup will copy RDS backups"
  default     = "eu-west-2"
}

variable "rds_target_backup_vault_name" {
  type        = string
  description = "RDS target backup vault name"
  default     = "NcrInfrastructureTest1BackupVault"
}

variable "rds_backup_selections_role_name" {
  type        = string
  description = "Unique name for the backup policy"
  default     = "NcrInfrastructureTest1BackupRole"
}

variable "rds_backup_selections" {
  type        = map(list(string))
  description = "Specifies the tags that identify the resources to be backed up"
  default = {
    RDSBackup = ["true"]
  }
}

variable "rds_schedule_expression_daily" {
  type        = string
  description = "Cron schedule for RDS backup - daily"
  default     = "cron(0 22 ? * MON-SAT *)" # 10pm every day except Sunday
}

variable "rds_schedule_expression_weekly" {
  type        = string
  description = "Cron schedule for RDS backup - weekly"
  default     = "cron(0 22 ? * SUN *)" # 10pm every Sunday
}

variable "rds_schedule_expression_monthly" {
  type        = string
  description = "Cron schedule for RDS backup - monthly"
  default     = "cron(0 22 1 FEB,MAR,MAY,JUN,AUG,SEP,NOV,DEC ? *)" # 10pm on the 1st of every month except quarterly months
}

variable "rds_schedule_expression_quarterly" {
  type        = string
  description = "Cron schedule for RDS backup - quarterly"
  default     = "cron(0 22 1 JAN,APR,JUL,OCT ? *)" # 10pm on the 1st of every quarter
}

variable "rds_start_backup_window_minutes" {
  type        = number
  description = "The number of minutes to wait before canceling an RDS backup job that does not start successfully"
  default     = 60
}

variable "rds_complete_backup_window_minutes" {
  type        = number
  default     = 360
  description = "The time in minutes AWS Backup attempts an RDS backup before canceling the job and returning an error"
}

variable "rds_enable_continuous_backup" {
  type        = bool
  default     = true
  description = "Enables continuous backups of RDS transaction logs"
}

variable "rds_delete_after_days_daily" {
  type        = number
  description = "The number of days after creation that a recovery point is deleted for daily backups."
  default     = 35
}

variable "rds_delete_after_days_weekly" {
  type        = number
  description = "The number of days after creation that a recovery point is deleted for weekly backups."
  default     = 183 # 6 months
}

variable "rds_delete_after_days_monthly" {
  type        = number
  description = "The number of days after creation that a recovery point is deleted for monthly backups."
  default     = 732 # 2 years
}

variable "rds_delete_after_days_quarterly" {
  type        = number
  description = "The number of days after creation that a recovery point is deleted for quarterly backups."
  default     = 2192 # 6 years
}

variable "rds_backup_vault_lock_changeable_for_days" {
  type        = number
  description = "The number of days that the backup vault lock configuration can be changed."
  default     = 7
}

variable "s3_backup_vault_min_retention" {
  type        = number
  description = "The minimum locked retention for our S3 secondary vault."
  default     = 92 # 3 months
}

variable "s3_backup_vault_max_retention" {
  type        = number
  description = "The maximum locked retention for our S3 secondary vault."
  default     = 2192 # 6 years
}

variable "s3_regions" {
  type        = list(string)
  description = "The regions in which AWS Backup will match resource selections for S3 backup"
  default = [
    "eu-west-1"
  ]
}

variable "s3_secondary_vault_region" {
  type        = string
  description = "The region in which AWS Backup will copy S3 backups"
  default     = "eu-west-2"
}

variable "s3_target_backup_vault_name" {
  type        = string
  description = "RDS target backup vault name"
  default     = "NcrInfrastructureTest1BackupVault"
}

variable "s3_backup_selections_role_name" {
  type        = string
  description = "Unique name for the backup IAM Role"
  default     = "NcrInfrastructureTest1BackupRole"
}

variable "s3_backup_selections" {
  type        = map(list(string))
  description = "Specifies the tags that identify the S3 buckets to be backed up"
  default = {
    S3Backup = ["true"]
  }
}

variable "s3_schedule_expression_daily" {
  type        = string
  description = "Cron schedule for S3 backup - daily"
  default     = "cron(0 22 ? * MON-SAT *)" # 10pm every day except Sunday
}

variable "s3_schedule_expression_weekly" {
  type        = string
  description = "Cron schedule for S3 backup - weekly"
  default     = "cron(0 22 ? * SUN *)" # 10pm every Sunday
}

variable "s3_schedule_expression_monthly" {
  type        = string
  description = "Cron schedule for S3 backup - monthly"
  default     = "cron(0 22 1 FEB,MAR,MAY,JUN,AUG,SEP,NOV,DEC ? *)" # 10pm on the 1st of every month except quarterly months
}

variable "s3_schedule_expression_quarterly" {
  type        = string
  description = "Cron schedule for S3 backup - quarterly"
  default     = "cron(0 22 1 JAN,APR,JUL,OCT ? *)" # 10pm on the 1st of every quarter
}

variable "s3_start_backup_window_minutes" {
  type        = number
  description = "The number of minutes to wait before canceling an S3 backup job that does not start successfully"
  default     = 120
}

variable "s3_complete_backup_window_minutes" {
  type        = number
  default     = 10080
  description = "The time in minutes AWS Backup attempts an S3 backup before canceling the job and returning an error"
}

variable "s3_enable_continuous_backup" {
  type        = bool
  default     = true
  description = "Enables continuous backups of S3 objects"
}

variable "s3_delete_after_days_daily" {
  type        = number
  description = "The number of days after creation that a recovery point is deleted for daily backups."
  default     = 35
}

variable "s3_delete_after_days_weekly" {
  type        = number
  description = "The number of days after creation that a recovery point is deleted for weekly backups."
  default     = 92 # 3 months
}

variable "s3_delete_after_days_monthly" {
  type        = number
  description = "The number of days after creation that a recovery point is deleted for monthly backups."
  default     = 183 # 6 months
}

variable "s3_delete_after_days_quarterly" {
  type        = number
  description = "The number of days after creation that a recovery point is deleted for quarterly backups."
  default     = 366 # 1 year
}
