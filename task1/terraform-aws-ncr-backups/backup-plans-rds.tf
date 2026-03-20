locals {
  # https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_backup_syntax.html

  rds_backup_plan_prod = {
    regions = {
      "@@append" = var.rds_regions
    }

    rules = {
      "${var.name}-rds-backup-rule-prod-daily"   = local.rds_backup_rule_prod_daily,
      "${var.name}-rds-backup-rule-prod-weekly"  = local.rds_backup_rule_prod_weekly,
      "${var.name}-rds-backup-rule-prod-monthly" = local.rds_backup_rule_prod_monthly,
      # "${var.name}-rds-backup-rule-prod-quarterly" = local.rds_backup_rule_prod_quarterly
    }

    selections = local.rds_backup_selections
  }

  rds_backup_rule_prod_daily = {
    target_backup_vault_name       = { "@@assign" = var.rds_target_backup_vault_name }
    schedule_expression            = { "@@assign" = var.rds_schedule_expression_daily }
    start_backup_window_minutes    = { "@@assign" = var.rds_start_backup_window_minutes }
    complete_backup_window_minutes = { "@@assign" = var.rds_complete_backup_window_minutes }
    enable_continuous_backup       = { "@@assign" = var.rds_enable_continuous_backup }
    lifecycle                      = local.rds_lifecycle_prod_daily
    copy_actions                   = local.rds_copy_actions_cross_region_prod_daily
  }

  rds_lifecycle_prod_daily = {
    delete_after_days = { "@@assign" = var.rds_delete_after_days_daily }
  }

  rds_backup_rule_prod_weekly = {
    target_backup_vault_name       = { "@@assign" = var.rds_target_backup_vault_name }
    schedule_expression            = { "@@assign" = var.rds_schedule_expression_weekly }
    start_backup_window_minutes    = { "@@assign" = var.rds_start_backup_window_minutes }
    complete_backup_window_minutes = { "@@assign" = var.rds_complete_backup_window_minutes }
    lifecycle                      = local.rds_lifecycle_prod_weekly
    copy_actions                   = local.rds_copy_actions_cross_account_prod_weekly
  }

  rds_lifecycle_prod_weekly = {
    delete_after_days = { "@@assign" = var.rds_delete_after_days_weekly }
  }

  rds_backup_rule_prod_monthly = {
    target_backup_vault_name       = { "@@assign" = var.rds_target_backup_vault_name }
    schedule_expression            = { "@@assign" = var.rds_schedule_expression_monthly }
    start_backup_window_minutes    = { "@@assign" = var.rds_start_backup_window_minutes }
    complete_backup_window_minutes = { "@@assign" = var.rds_complete_backup_window_minutes }
    lifecycle                      = local.rds_lifecycle_prod_monthly
    copy_actions                   = local.rds_copy_actions_cross_account_prod_monthly
  }

  rds_lifecycle_prod_monthly = {
    delete_after_days = { "@@assign" = var.rds_delete_after_days_monthly }
  }

  rds_backup_rule_prod_quarterly = {
    target_backup_vault_name       = { "@@assign" = var.rds_target_backup_vault_name }
    schedule_expression            = { "@@assign" = var.rds_schedule_expression_quarterly }
    start_backup_window_minutes    = { "@@assign" = var.rds_start_backup_window_minutes }
    complete_backup_window_minutes = { "@@assign" = var.rds_complete_backup_window_minutes }
    lifecycle                      = local.rds_lifecycle_prod_quarterly
    copy_actions                   = local.rds_copy_actions_cross_account_prod_quarterly
  }

  rds_lifecycle_prod_quarterly = {
    delete_after_days = { "@@assign" = var.rds_delete_after_days_quarterly }
  }

  # Same account, cross region
  rds_copy_actions_cross_region_prod_daily = {
    "arn:aws:backup:${var.rds_secondary_vault_region}:$account:backup-vault:${var.rds_target_backup_vault_name}" = {
      target_backup_vault_arn = {
        "@@assign" = "arn:aws:backup:${var.rds_secondary_vault_region}:$account:backup-vault:${var.rds_target_backup_vault_name}"
      }
      lifecycle = local.rds_lifecycle_prod_daily
    }
  }

  # Backup account, same region
  rds_copy_actions_cross_account_prod_weekly = {
    "${aws_backup_vault.rds.arn}" = {
      target_backup_vault_arn = {
        "@@assign" = "${aws_backup_vault.rds.arn}"
      }
      lifecycle = local.rds_lifecycle_prod_weekly
    }
  }

  # Backup account, same region
  rds_copy_actions_cross_account_prod_monthly = {
    "${aws_backup_vault.rds.arn}" = {
      target_backup_vault_arn = {
        "@@assign" = "${aws_backup_vault.rds.arn}"
      }
      lifecycle = local.rds_lifecycle_prod_monthly
    }
  }

  # Backup account, same region
  rds_copy_actions_cross_account_prod_quarterly = {
    "${aws_backup_vault.rds.arn}" = {
      target_backup_vault_arn = {
        "@@assign" = "${aws_backup_vault.rds.arn}"
      }
      lifecycle = local.rds_lifecycle_prod_quarterly
    }
  }

  rds_backup_plan_test = {
    regions = {
      "@@append" = var.rds_regions
    }

    rules = {
      "${var.name}-rds-backup-rule-test-weekly"  = local.rds_backup_rule_test_weekly,
      "${var.name}-rds-backup-rule-test-monthly" = local.rds_backup_rule_test_monthly,
    }

    selections = local.rds_backup_selections
  }

  rds_backup_rule_test_weekly = {
    target_backup_vault_name       = { "@@assign" = var.rds_target_backup_vault_name }
    schedule_expression            = { "@@assign" = var.rds_schedule_expression_weekly }
    start_backup_window_minutes    = { "@@assign" = var.rds_start_backup_window_minutes }
    complete_backup_window_minutes = { "@@assign" = var.rds_complete_backup_window_minutes }
    lifecycle                      = local.rds_lifecycle_test_weekly
    copy_actions                   = local.rds_copy_actions_cross_account_test_weekly
  }

  rds_lifecycle_test_weekly = {
    delete_after_days = { "@@assign" = var.rds_delete_after_days_weekly }
  }

  rds_backup_rule_test_monthly = {
    target_backup_vault_name       = { "@@assign" = var.rds_target_backup_vault_name }
    schedule_expression            = { "@@assign" = var.rds_schedule_expression_monthly }
    start_backup_window_minutes    = { "@@assign" = var.rds_start_backup_window_minutes }
    complete_backup_window_minutes = { "@@assign" = var.rds_complete_backup_window_minutes }
    lifecycle                      = local.rds_lifecycle_test_monthly
    copy_actions                   = local.rds_copy_actions_cross_account_test_monthly
  }

  rds_lifecycle_test_monthly = {
    delete_after_days = { "@@assign" = var.rds_delete_after_days_monthly }
  }

  rds_backup_rule_test_quarterly = {
    target_backup_vault_name       = { "@@assign" = var.rds_target_backup_vault_name }
    schedule_expression            = { "@@assign" = var.rds_schedule_expression_quarterly }
    start_backup_window_minutes    = { "@@assign" = var.rds_start_backup_window_minutes }
    complete_backup_window_minutes = { "@@assign" = var.rds_complete_backup_window_minutes }
    lifecycle                      = local.rds_lifecycle_test_quarterly
    copy_actions                   = local.rds_copy_actions_cross_account_test_quarterly
  }

  rds_lifecycle_test_quarterly = {
    delete_after_days = { "@@assign" = var.rds_delete_after_days_quarterly }
  }

  # Backup account, same region
  rds_copy_actions_cross_account_test_weekly = {
    "${aws_backup_vault.rds.arn}" = {
      target_backup_vault_arn = {
        "@@assign" = "${aws_backup_vault.rds.arn}"
      }
      lifecycle = local.rds_lifecycle_prod_weekly
    }
  }

  # Backup account, same region
  rds_copy_actions_cross_account_test_monthly = {
    "${aws_backup_vault.rds.arn}" = {
      target_backup_vault_arn = {
        "@@assign" = "${aws_backup_vault.rds.arn}"
      }
      lifecycle = local.rds_lifecycle_prod_monthly
    }
  }

  # Backup account, same region
  rds_copy_actions_cross_account_test_quarterly = {
    "${aws_backup_vault.rds.arn}" = {
      target_backup_vault_arn = {
        "@@assign" = "${aws_backup_vault.rds.arn}"
      }
      lifecycle = local.rds_lifecycle_prod_quarterly
    }
  }

  rds_backup_selections = {
    tags = {
      for key, value in var.rds_backup_selections :
      key => {
        iam_role_arn = {
          "@@assign" = "arn:aws:iam::$account:role/${var.rds_backup_selections_role_name}"
        },
        tag_key = {
          "@@assign" = key
        },
        tag_value = {
          "@@assign" = value
        }
      }
    }
  }
}
