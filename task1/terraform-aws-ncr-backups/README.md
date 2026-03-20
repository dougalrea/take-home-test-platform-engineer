<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.90.0 |
| <a name="provider_aws.eu-west-2"></a> [aws.eu-west-2](#provider\_aws.eu-west-2) | 5.90.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_backup_global_settings.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_global_settings) | resource |
| [aws_backup_logically_air_gapped_vault.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_logically_air_gapped_vault) | resource |
| [aws_backup_vault.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault) | resource |
| [aws_backup_vault_lock_configuration.rds_vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault_lock_configuration) | resource |
| [aws_backup_vault_policy.rds_vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault_policy) | resource |
| [aws_backup_vault_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault_policy) | resource |
| [aws_iam_service_linked_role.ram](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_service_linked_role) | resource |
| [aws_kms_alias.rds_vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.rds_vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_organizations_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy) | resource |
| [aws_organizations_policy_attachment.accounts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) | resource |
| [aws_organizations_policy_attachment.ou_attached](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) | resource |
| [aws_organizations_policy_attachment.root_attached](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) | resource |
| [aws_ram_principal_association.air_gapped_vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_principal_association) | resource |
| [aws_ram_resource_association.air_gapped_vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_resource_association) | resource |
| [aws_ram_resource_share.air_gapped_vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_resource_share) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.air_gapped_vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.kms_rds_vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.rds_vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_organizations_organization.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |
| [aws_organizations_organizational_unit.ou_attached](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organizational_unit) | data source |
| [aws_organizations_organizational_unit.root_attached](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organizational_unit) | data source |
| [aws_organizations_organizational_unit_child_accounts.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organizational_unit_child_accounts) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_accounts_config"></a> [aws\_accounts\_config](#input\_aws\_accounts\_config) | Configuration of AWS Account backup policies | <pre>list(object({<br/>    email_address   = string<br/>    backup_policies = optional(list(string), [])<br/>  }))</pre> | <pre>[<br/>  {<br/>    "backup_policies": [<br/>      "ncr-infratest1-rds-backup-policy-test",<br/>      "ncr-infratest1-s3-backup-policy-test"<br/>    ],<br/>    "email_address": "aws.root.sandbox@natcapresearch.com"<br/>  }<br/>]</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | Suffix for backup resource names | `string` | `"ncr"` | no |
| <a name="input_organizational_units_config"></a> [organizational\_units\_config](#input\_organizational\_units\_config) | Configuration of Organizational Unit backup policies | <pre>list(object({<br/>    name            = string<br/>    parent_ou       = optional(string)<br/>    backup_policies = optional(list(string), [])<br/>  }))</pre> | <pre>[<br/>  {<br/>    "name": "workloads"<br/>  },<br/>  {<br/>    "backup_policies": [<br/>      "ncr-infratest1-rds-backup-policy-prod",<br/>      "ncr-infratest1-s3-backup-policy-prod"<br/>    ],<br/>    "name": "prod",<br/>    "parent_ou": "workloads"<br/>  },<br/>  {<br/>    "backup_policies": [<br/>      "ncr-infratest1-rds-backup-policy-prod",<br/>      "ncr-infratest1-s3-backup-policy-prod"<br/>    ],<br/>    "name": "staging",<br/>    "parent_ou": "workloads"<br/>  },<br/>  {<br/>    "backup_policies": [<br/>      "ncr-infratest1-rds-backup-policy-test",<br/>      "ncr-infratest1-s3-backup-policy-test"<br/>    ],<br/>    "name": "test",<br/>    "parent_ou": "workloads"<br/>  },<br/>  {<br/>    "backup_policies": [<br/>      "ncr-infratest1-s3-backup-policy-prod"<br/>    ],<br/>    "name": "security"<br/>  }<br/>]</pre> | no |
| <a name="input_rds_backup_selections"></a> [rds\_backup\_selections](#input\_rds\_backup\_selections) | Specifies the tags that identify the resources to be backed up | `map(list(string))` | <pre>{<br/>  "RDSBackup": [<br/>    "true"<br/>  ]<br/>}</pre> | no |
| <a name="input_rds_backup_selections_role_name"></a> [rds\_backup\_selections\_role\_name](#input\_rds\_backup\_selections\_role\_name) | Unique name for the backup policy | `string` | `"NcrInfrastructureTest1BackupRole"` | no |
| <a name="input_rds_backup_vault_lock_changeable_for_days"></a> [rds\_backup\_vault\_lock\_changeable\_for\_days](#input\_rds\_backup\_vault\_lock\_changeable\_for\_days) | The number of days that the backup vault lock configuration can be changed. | `number` | `7` | no |
| <a name="input_rds_backup_vault_max_retention"></a> [rds\_backup\_vault\_max\_retention](#input\_rds\_backup\_vault\_max\_retention) | The maximum locked retention for our RDS secondary vault. | `number` | `2192` | no |
| <a name="input_rds_backup_vault_min_retention"></a> [rds\_backup\_vault\_min\_retention](#input\_rds\_backup\_vault\_min\_retention) | The minimum locked retention for our RDS secondary vault. | `number` | `92` | no |
| <a name="input_rds_complete_backup_window_minutes"></a> [rds\_complete\_backup\_window\_minutes](#input\_rds\_complete\_backup\_window\_minutes) | The time in minutes AWS Backup attempts an RDS backup before canceling the job and returning an error | `number` | `360` | no |
| <a name="input_rds_delete_after_days_daily"></a> [rds\_delete\_after\_days\_daily](#input\_rds\_delete\_after\_days\_daily) | The number of days after creation that a recovery point is deleted for daily backups. | `number` | `35` | no |
| <a name="input_rds_delete_after_days_monthly"></a> [rds\_delete\_after\_days\_monthly](#input\_rds\_delete\_after\_days\_monthly) | The number of days after creation that a recovery point is deleted for monthly backups. | `number` | `732` | no |
| <a name="input_rds_delete_after_days_quarterly"></a> [rds\_delete\_after\_days\_quarterly](#input\_rds\_delete\_after\_days\_quarterly) | The number of days after creation that a recovery point is deleted for quarterly backups. | `number` | `2192` | no |
| <a name="input_rds_delete_after_days_weekly"></a> [rds\_delete\_after\_days\_weekly](#input\_rds\_delete\_after\_days\_weekly) | The number of days after creation that a recovery point is deleted for weekly backups. | `number` | `183` | no |
| <a name="input_rds_enable_continuous_backup"></a> [rds\_enable\_continuous\_backup](#input\_rds\_enable\_continuous\_backup) | Enables continuous backups of RDS transaction logs | `bool` | `true` | no |
| <a name="input_rds_regions"></a> [rds\_regions](#input\_rds\_regions) | The regions in which AWS Backup will match resource selections for RDS backup | `list(string)` | <pre>[<br/>  "eu-west-1"<br/>]</pre> | no |
| <a name="input_rds_schedule_expression_daily"></a> [rds\_schedule\_expression\_daily](#input\_rds\_schedule\_expression\_daily) | Cron schedule for RDS backup - daily | `string` | `"cron(0 22 ? * MON-SAT *)"` | no |
| <a name="input_rds_schedule_expression_monthly"></a> [rds\_schedule\_expression\_monthly](#input\_rds\_schedule\_expression\_monthly) | Cron schedule for RDS backup - monthly | `string` | `"cron(0 22 1 FEB,MAR,MAY,JUN,AUG,SEP,NOV,DEC ? *)"` | no |
| <a name="input_rds_schedule_expression_quarterly"></a> [rds\_schedule\_expression\_quarterly](#input\_rds\_schedule\_expression\_quarterly) | Cron schedule for RDS backup - quarterly | `string` | `"cron(0 22 1 JAN,APR,JUL,OCT ? *)"` | no |
| <a name="input_rds_schedule_expression_weekly"></a> [rds\_schedule\_expression\_weekly](#input\_rds\_schedule\_expression\_weekly) | Cron schedule for RDS backup - weekly | `string` | `"cron(0 22 ? * SUN *)"` | no |
| <a name="input_rds_secondary_vault_region"></a> [rds\_secondary\_vault\_region](#input\_rds\_secondary\_vault\_region) | The region in which AWS Backup will copy RDS backups | `string` | `"eu-west-2"` | no |
| <a name="input_rds_start_backup_window_minutes"></a> [rds\_start\_backup\_window\_minutes](#input\_rds\_start\_backup\_window\_minutes) | The number of minutes to wait before canceling an RDS backup job that does not start successfully | `number` | `60` | no |
| <a name="input_rds_target_backup_vault_name"></a> [rds\_target\_backup\_vault\_name](#input\_rds\_target\_backup\_vault\_name) | RDS target backup vault name | `string` | `"NcrInfrastructureTest1BackupVault"` | no |
| <a name="input_s3_backup_selections"></a> [s3\_backup\_selections](#input\_s3\_backup\_selections) | Specifies the tags that identify the S3 buckets to be backed up | `map(list(string))` | <pre>{<br/>  "S3Backup": [<br/>    "true"<br/>  ]<br/>}</pre> | no |
| <a name="input_s3_backup_selections_role_name"></a> [s3\_backup\_selections\_role\_name](#input\_s3\_backup\_selections\_role\_name) | Unique name for the backup IAM Role | `string` | `"NcrInfrastructureTest1BackupRole"` | no |
| <a name="input_s3_backup_vault_max_retention"></a> [s3\_backup\_vault\_max\_retention](#input\_s3\_backup\_vault\_max\_retention) | The maximum locked retention for our S3 secondary vault. | `number` | `2192` | no |
| <a name="input_s3_backup_vault_min_retention"></a> [s3\_backup\_vault\_min\_retention](#input\_s3\_backup\_vault\_min\_retention) | The minimum locked retention for our S3 secondary vault. | `number` | `92` | no |
| <a name="input_s3_complete_backup_window_minutes"></a> [s3\_complete\_backup\_window\_minutes](#input\_s3\_complete\_backup\_window\_minutes) | The time in minutes AWS Backup attempts an S3 backup before canceling the job and returning an error | `number` | `10080` | no |
| <a name="input_s3_delete_after_days_daily"></a> [s3\_delete\_after\_days\_daily](#input\_s3\_delete\_after\_days\_daily) | The number of days after creation that a recovery point is deleted for daily backups. | `number` | `35` | no |
| <a name="input_s3_delete_after_days_monthly"></a> [s3\_delete\_after\_days\_monthly](#input\_s3\_delete\_after\_days\_monthly) | The number of days after creation that a recovery point is deleted for monthly backups. | `number` | `183` | no |
| <a name="input_s3_delete_after_days_quarterly"></a> [s3\_delete\_after\_days\_quarterly](#input\_s3\_delete\_after\_days\_quarterly) | The number of days after creation that a recovery point is deleted for quarterly backups. | `number` | `366` | no |
| <a name="input_s3_delete_after_days_weekly"></a> [s3\_delete\_after\_days\_weekly](#input\_s3\_delete\_after\_days\_weekly) | The number of days after creation that a recovery point is deleted for weekly backups. | `number` | `92` | no |
| <a name="input_s3_enable_continuous_backup"></a> [s3\_enable\_continuous\_backup](#input\_s3\_enable\_continuous\_backup) | Enables continuous backups of S3 objects | `bool` | `true` | no |
| <a name="input_s3_regions"></a> [s3\_regions](#input\_s3\_regions) | The regions in which AWS Backup will match resource selections for S3 backup | `list(string)` | <pre>[<br/>  "eu-west-1"<br/>]</pre> | no |
| <a name="input_s3_schedule_expression_daily"></a> [s3\_schedule\_expression\_daily](#input\_s3\_schedule\_expression\_daily) | Cron schedule for S3 backup - daily | `string` | `"cron(0 22 ? * MON-SAT *)"` | no |
| <a name="input_s3_schedule_expression_monthly"></a> [s3\_schedule\_expression\_monthly](#input\_s3\_schedule\_expression\_monthly) | Cron schedule for S3 backup - monthly | `string` | `"cron(0 22 1 FEB,MAR,MAY,JUN,AUG,SEP,NOV,DEC ? *)"` | no |
| <a name="input_s3_schedule_expression_quarterly"></a> [s3\_schedule\_expression\_quarterly](#input\_s3\_schedule\_expression\_quarterly) | Cron schedule for S3 backup - quarterly | `string` | `"cron(0 22 1 JAN,APR,JUL,OCT ? *)"` | no |
| <a name="input_s3_schedule_expression_weekly"></a> [s3\_schedule\_expression\_weekly](#input\_s3\_schedule\_expression\_weekly) | Cron schedule for S3 backup - weekly | `string` | `"cron(0 22 ? * SUN *)"` | no |
| <a name="input_s3_secondary_vault_region"></a> [s3\_secondary\_vault\_region](#input\_s3\_secondary\_vault\_region) | The region in which AWS Backup will copy S3 backups | `string` | `"eu-west-2"` | no |
| <a name="input_s3_start_backup_window_minutes"></a> [s3\_start\_backup\_window\_minutes](#input\_s3\_start\_backup\_window\_minutes) | The number of minutes to wait before canceling an S3 backup job that does not start successfully | `number` | `120` | no |
| <a name="input_s3_target_backup_vault_name"></a> [s3\_target\_backup\_vault\_name](#input\_s3\_target\_backup\_vault\_name) | RDS target backup vault name | `string` | `"NcrInfrastructureTest1BackupVault"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->