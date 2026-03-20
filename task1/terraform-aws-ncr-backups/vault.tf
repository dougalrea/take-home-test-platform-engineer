locals {
  rds_vault_name = "NcrInfrastructureTest1RDSVault"

  vault_share_ou_list = merge(
    { for ou in var.organizational_units_config : ou.name =>
      {
        name      = ou.name
        parent_ou = null
        id        = data.aws_organizations_organizational_unit.root_attached[ou.name].id
      }
      if length(ou.backup_policies) > 0 && ou.parent_ou == null
    },
    { for ou in var.organizational_units_config : "${ou.parent_ou}/${ou.name}" =>
      {
        name      = ou.name
        parent_ou = ou.parent_ou
        id        = data.aws_organizations_organizational_unit.ou_attached["${ou.parent_ou}/${ou.name}"].id
      }
      if length(ou.backup_policies) > 0 && ou.parent_ou != null
    }
  )

  vault_share_org_paths = [
    for ou in local.vault_share_ou_list :
    "${data.aws_organizations_organization.this.id}/*/${ou.id}/*"
  ]

  vault_share_account_ids = setsubtract(
    flatten([
      for ou, value in local.vault_share_ou_list :
      data.aws_organizations_organizational_unit_child_accounts.this[ou].accounts[*].id
    ]),
    [data.aws_caller_identity.current.account_id] # Vaults cannot be shared with the owning account
  )
}

data "aws_organizations_organizational_unit_child_accounts" "this" {
  for_each = local.vault_share_ou_list

  parent_id = each.value.id
}

# this allows us to share the logically air-gapped vault
resource "aws_iam_service_linked_role" "ram" {
  aws_service_name = "ram.amazonaws.com"
  description      = "Allows RAM to access Organizations on your behalf."
}

resource "aws_backup_logically_air_gapped_vault" "this" {
  provider           = aws.eu-west-2
  name               = "NcrInfrastructureTest1AirGappedVault"
  min_retention_days = var.s3_backup_vault_min_retention
  max_retention_days = var.s3_backup_vault_max_retention
}

resource "aws_ram_resource_share" "air_gapped_vault" {
  provider                  = aws.eu-west-2
  name                      = "NcrInfrastructureTest1AirGappedVaultShare"
  allow_external_principals = false
}

data "aws_iam_policy_document" "air_gapped_vault" {
  provider = aws.eu-west-2

  statement {
    sid = "allowBackupCopyIntoVault"

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = local.vault_share_account_ids
    }

    actions = [
      "backup:CopyIntoBackupVault"
    ]

    resources = [
      aws_backup_logically_air_gapped_vault.this.arn
    ]

    # allow only principals from OUs with backup policies
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "aws:PrincipalOrgPaths"
      values   = local.vault_share_org_paths
    }
  }
}

resource "aws_backup_vault_policy" "this" {
  provider          = aws.eu-west-2
  backup_vault_name = aws_backup_logically_air_gapped_vault.this.name
  policy            = data.aws_iam_policy_document.air_gapped_vault.json
}

resource "aws_ram_resource_association" "air_gapped_vault" {
  provider           = aws.eu-west-2
  resource_arn       = aws_backup_logically_air_gapped_vault.this.arn
  resource_share_arn = aws_ram_resource_share.air_gapped_vault.arn
}

resource "aws_ram_principal_association" "air_gapped_vault" {
  provider           = aws.eu-west-2
  for_each           = toset(local.vault_share_account_ids)
  principal          = each.value
  resource_share_arn = aws_ram_resource_share.air_gapped_vault.arn
}

resource "aws_kms_key" "rds_vault" {
  description         = "AWS Backup RDS vault key"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms_rds_vault.json
}

resource "aws_kms_alias" "rds_vault" {
  name          = "alias/${local.rds_vault_name}"
  target_key_id = aws_kms_key.rds_vault.key_id
}

data "aws_iam_policy_document" "kms_rds_vault" {
  statement {
    # https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-root-enable-iam
    sid = "AllowRoot"

    effect = "Allow"

    not_actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*"
    ]

    resources = ["*"]

    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      type        = "AWS"
    }
  }

  statement {
    sid = "AWS Backup cross-account copy for restoring to the source accounts"

    effect = "Allow"

    actions = [
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:CreateGrant",
      "kms:Decrypt"
    ]

    resources = ["*"]

    principals {
      identifiers = [for account in local.vault_share_account_ids :
        "arn:aws:iam::${account}:role/aws-service-role/backup.amazonaws.com/AWSServiceRoleForBackup"
      ]
      type = "AWS"
    }
  }

  statement {
    # https://aws.amazon.com/blogs/storage/how-encryption-works-in-aws-backup/
    # allow key use by backup service role
    sid = "AllowBackupService"

    effect = "Allow"

    actions = [
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:Decrypt",
      "kms:ReEncrypt*"
    ]

    resources = ["*"]

    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.rds_backup_selections_role_name}"]
      type        = "AWS"
    }
  }
}

resource "aws_backup_vault" "rds" {
  name        = local.rds_vault_name
  kms_key_arn = aws_kms_key.rds_vault.arn
}

data "aws_iam_policy_document" "rds_vault" {

  statement {
    sid = "allowBackupCopyIntoVault"

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "backup:CopyIntoBackupVault",
    ]

    resources = [
      aws_backup_vault.rds.arn,
    ]

    # allow only principals from OUs with backup policies
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "aws:PrincipalOrgPaths"
      values   = local.vault_share_org_paths
    }
  }
}

resource "aws_backup_vault_policy" "rds_vault" {
  backup_vault_name = aws_backup_vault.rds.name
  policy            = data.aws_iam_policy_document.rds_vault.json
}

resource "aws_backup_vault_lock_configuration" "rds_vault" {
  backup_vault_name   = aws_backup_vault.rds.name
  changeable_for_days = var.rds_backup_vault_lock_changeable_for_days
  min_retention_days  = var.rds_backup_vault_min_retention
  max_retention_days  = var.rds_backup_vault_max_retention
}
