terraform {
  backend "s3" {
    bucket  = "ncr-infrastructure-test1"
    key     = "terraform/security.backups.backup.tfstate"
    region  = "eu-west-2"
    profile = "AWSInfrastructureTest1Access-workloads.prod.main"
  }
}

provider "aws" {
  region  = "eu-west-1"
  profile = "AWSBackupOrganizationInfrastructureTest1Access-security.backups"

  default_tags {
    tags = {
      Managed       = "terraform"
      Configuration = "backup"
    }
  }
}

provider "aws" {
  region  = "eu-west-2"
  profile = "AWSBackupOrganizationInfrastructureTest1Access-security.backups"
  alias   = "eu-west-2"

  default_tags {
    tags = {
      Managed       = "terraform"
      Configuration = "backup"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_organizations_organization" "this" {}

resource "aws_backup_global_settings" "this" {
  global_settings = {
    # Cross-account backup
    "isCrossAccountBackupEnabled" = "true"
    # https://github.com/hashicorp/terraform-provider-aws/issues/43514
    "isMpaEnabled"                    = "false"
    "isDelegatedAdministratorEnabled" = "true"
  }
}

import {
  to = aws_backup_global_settings.this
  id = data.aws_caller_identity.current.account_id
}

# Organizational Units attached to root
data "aws_organizations_organizational_unit" "root_attached" {
  for_each = { for ou in var.organizational_units_config : ou.name => ou if ou.parent_ou == null }

  name      = each.value.name
  parent_id = data.aws_organizations_organization.this.roots[0].id
}

# Organizational Units attached to another OU
# currently this configuration will only allow two levels of OU. Note that OUs attached to the same parent must have unique names
data "aws_organizations_organizational_unit" "ou_attached" {
  for_each = { for ou in var.organizational_units_config : "${ou.parent_ou}/${ou.name}" => ou if ou.parent_ou != null }

  name      = each.value.name
  parent_id = data.aws_organizations_organizational_unit.root_attached[each.value.parent_ou].id
}

