locals {

  backup_policies_map = {
    "${var.name}-rds-backup-policy-prod" = {
      "plans" = {
        "${var.name}-rds-backup-plan-prod" = local.rds_backup_plan_prod
      }
    }
    "${var.name}-rds-backup-policy-test" = {
      "plans" = {
        "${var.name}-rds-backup-plan-test" = local.rds_backup_plan_test
      }
    }
    "${var.name}-s3-backup-policy-prod" = {
      "plans" = {
        "${var.name}-s3-backup-plan-prod" = local.s3_backup_plan_prod
      }
    }
    "${var.name}-s3-backup-policy-test" = {
      "plans" = {
        "${var.name}-s3-backup-plan-test" = local.s3_backup_plan_test
      }
    }
  }

  # find every combination of AWS Account backup policy attachments
  account_policy_attachment_list = flatten([
    for account in var.aws_accounts_config : length(account.backup_policies) > 0 ? [
      for attachment in setproduct([account.email_address], account.backup_policies) : {
        email_address = attachment[0]
        backup_policy = attachment[1]
        account_id = [
          for account in data.aws_organizations_organization.this.accounts :
          account.id if account.email == attachment[0]
        ][0]
      }
    ] : []
  ])

  # create a map of AWS Account backup policy attachments to create our resource collection
  account_policy_attachment_map = { for attachment in local.account_policy_attachment_list :
    join(":", [
      attachment.email_address,
      attachment.backup_policy
    ]) => attachment
  }

  # find every combination of OU backup policy attachments
  ou_policy_attachment_list = flatten([
    for ou in var.organizational_units_config : length(ou.backup_policies) > 0 ? [
      for attachment in setproduct([ou.name], [ou.parent_ou], ou.backup_policies) : {
        name          = attachment[0]
        parent_ou     = attachment[1]
        backup_policy = attachment[2]
      }
    ] : []
  ])

  # create a map of backup policy attachments for OUs attached directly for root
  ou_policy_attachment_map_root_attached = { for attachment in local.ou_policy_attachment_list :
    "${attachment.name}:${attachment.backup_policy}" => attachment if attachment.parent_ou == null
  }

  # create a map of backup policy attachments for OUs attached to a single parent OU
  ou_policy_attachment_map_ou_attached = { for attachment in local.ou_policy_attachment_list :
    "${attachment.parent_ou}/${attachment.name}:${attachment.backup_policy}" => attachment if attachment.parent_ou != null
  }

  ou_policy_attachment_map = merge(local.ou_policy_attachment_map_root_attached, local.ou_policy_attachment_map_ou_attached)
}

resource "aws_organizations_policy" "this" {
  for_each = local.backup_policies_map

  name        = each.key
  content     = jsonencode(each.value)
  description = "AWS Backup Policy ${each.key}"
  type        = "BACKUP_POLICY"
}

# RDS Backup Policy Attachments - AWS Accounts
resource "aws_organizations_policy_attachment" "accounts" {
  for_each = local.account_policy_attachment_map

  policy_id = aws_organizations_policy.this[each.value.backup_policy].id
  target_id = each.value.account_id
}

# RDS Backup Policy Attachments - root attached Organizational Units
resource "aws_organizations_policy_attachment" "root_attached" {
  for_each = { for key, ou in local.ou_policy_attachment_map : key => ou
    if(ou.parent_ou == null)
  }

  policy_id = aws_organizations_policy.this[each.value.backup_policy].id
  target_id = data.aws_organizations_organizational_unit.root_attached[each.value.name].id
}

# RDS Backup Policy Attachments - OU attached Organizational Units
resource "aws_organizations_policy_attachment" "ou_attached" {
  for_each = { for key, ou in local.ou_policy_attachment_map : key => ou
    if(ou.parent_ou != null)
  }

  policy_id = aws_organizations_policy.this[each.value.backup_policy].id
  target_id = data.aws_organizations_organizational_unit.ou_attached["${each.value.parent_ou}/${each.value.name}"].id
}
