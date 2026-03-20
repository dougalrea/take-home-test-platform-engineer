data "aws_organizations_organization" "org" {}

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "vault" {
  description         = "AWS Backup vault key"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.vault_key.json
}

resource "aws_kms_alias" "vault" {
  name          = "alias/${var.vault_name}"
  target_key_id = aws_kms_key.vault.key_id
}

data "aws_iam_policy_document" "vault_key" {
  statement {
    # https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-root-enable-iam
    # https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-administrators
    # allow key admin policies to be assiged
    sid = "AllowAdmin"

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
      identifiers = [var.backup_service_role_arn]
      type        = "AWS"
    }
  }
}

resource "aws_backup_vault" "this" {
  name        = var.vault_name
  kms_key_arn = aws_kms_key.vault.arn
  #force_destroy = var.force_destroy
}

data "aws_iam_policy_document" "vault" {
  statement {
    sid = "allowBackupIntoVault"

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions = [
      "backup:DescribeBackupVault",
      "backup:DeleteBackupVault",
      "backup:PutBackupVaultAccessPolicy",
      "backup:DeleteBackupVaultAccessPolicy",
      "backup:GetBackupVaultAccessPolicy",
      "backup:StartBackupJob",
      "backup:GetBackupVaultNotifications",
      "backup:PutBackupVaultNotifications",
    ]

    resources = [
      aws_backup_vault.this.arn,
    ]
  }

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
      aws_backup_vault.this.arn,
    ]

    # allow only principals from my organization
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [data.aws_organizations_organization.org.id]
    }
  }
}

resource "aws_backup_vault_policy" "this" {
  backup_vault_name = aws_backup_vault.this.name
  policy            = data.aws_iam_policy_document.vault.json
}

