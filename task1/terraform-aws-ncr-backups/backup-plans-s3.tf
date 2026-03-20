locals {
  # https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_backup_syntax.html

  s3_backup_plan_prod = {
    regions = {
      "@@append" = var.s3_regions
    }

    rules = {
      "${var.name}-s3-backup-rule-prod-daily"     = local.s3_backup_rule_prod_daily,
      "${var.name}-s3-backup-rule-prod-weekly"    = local.s3_backup_rule_prod_weekly,
      "${var.name}-s3-backup-rule-prod-monthly"   = local.s3_backup_rule_prod_monthly,
      "${var.name}-s3-backup-rule-prod-quarterly" = local.s3_backup_rule_prod_quarterly
    }

    selections = local.s3_backup_selections
  }

  s3_backup_rule_prod_daily = {
    target_backup_vault_name       = { "@@assign" = var.s3_target_backup_vault_name }
    schedule_expression            = { "@@assign" = var.s3_schedule_expression_daily }
    start_backup_window_minutes    = { "@@assign" = var.s3_start_backup_window_minutes }
    complete_backup_window_minutes = { "@@assign" = var.s3_complete_backup_window_minutes }
    enable_continuous_backup       = { "@@assign" = var.s3_enable_continuous_backup }
    lifecycle                      = local.s3_lifecycle_prod_daily
  }

  s3_lifecycle_prod_daily = {
    delete_after_days = { "@@assign" = var.s3_delete_after_days_daily }
  }

  s3_backup_rule_prod_weekly = {
    target_backup_vault_name       = { "@@assign" = var.s3_target_backup_vault_name }
    schedule_expression            = { "@@assign" = var.s3_schedule_expression_weekly }
    start_backup_window_minutes    = { "@@assign" = var.s3_start_backup_window_minutes }
    complete_backup_window_minutes = { "@@assign" = var.s3_complete_backup_window_minutes }
    lifecycle                      = local.s3_lifecycle_prod_weekly
    copy_actions                   = local.s3_copy_actions_cross_account_prod_weekly
  }

  s3_lifecycle_prod_weekly = {
    delete_after_days = { "@@assign" = var.s3_delete_after_days_weekly }
  }

  s3_backup_rule_prod_monthly = {
    target_backup_vault_name       = { "@@assign" = var.s3_target_backup_vault_name }
    schedule_expression            = { "@@assign" = var.s3_schedule_expression_monthly }
    start_backup_window_minutes    = { "@@assign" = var.s3_start_backup_window_minutes }
    complete_backup_window_minutes = { "@@assign" = var.s3_complete_backup_window_minutes }
    lifecycle                      = local.s3_lifecycle_prod_monthly
    copy_actions                   = local.s3_copy_actions_cross_account_prod_monthly
  }

  s3_lifecycle_prod_monthly = {
    delete_after_days = { "@@assign" = var.s3_delete_after_days_monthly }
  }

  s3_backup_rule_prod_quarterly = {
    target_backup_vault_name       = { "@@assign" = var.s3_target_backup_vault_name }
    schedule_expression            = { "@@assign" = var.s3_schedule_expression_quarterly }
    start_backup_window_minutes    = { "@@assign" = var.s3_start_backup_window_minutes }
    complete_backup_window_minutes = { "@@assign" = var.s3_complete_backup_window_minutes }
    lifecycle                      = local.s3_lifecycle_prod_quarterly
    copy_actions                   = local.s3_copy_actions_cross_account_prod_quarterly
  }

  s3_lifecycle_prod_quarterly = {
    delete_after_days = { "@@assign" = var.s3_delete_after_days_quarterly }
  }

  # Backup account, cross region
  s3_copy_actions_cross_account_prod_weekly = {
    "${aws_backup_logically_air_gapped_vault.this.arn}" = {
      target_backup_vault_arn = {
        "@@assign" = "${aws_backup_logically_air_gapped_vault.this.arn}"
      }
      lifecycle = local.s3_lifecycle_prod_weekly
    }
  }

  # Backup account, cross region
  s3_copy_actions_cross_account_prod_monthly = {
    "${aws_backup_logically_air_gapped_vault.this.arn}" = {
      target_backup_vault_arn = {
        "@@assign" = "${aws_backup_logically_air_gapped_vault.this.arn}"
      }
      lifecycle = local.s3_lifecycle_prod_monthly
    }
  }

  # Backup account, cross region
  s3_copy_actions_cross_account_prod_quarterly = {
    "${aws_backup_logically_air_gapped_vault.this.arn}" = {
      target_backup_vault_arn = {
        "@@assign" = "${aws_backup_logically_air_gapped_vault.this.arn}"
      }
      lifecycle = local.s3_lifecycle_prod_quarterly
    }
  }

  s3_backup_plan_test = {
    regions = {
      "@@append" = var.s3_regions
    }

    rules = {
      "${var.name}-s3-backup-rule-test-daily"     = local.s3_backup_rule_test_daily,
      "${var.name}-s3-backup-rule-test-weekly"    = local.s3_backup_rule_test_weekly,
      "${var.name}-s3-backup-rule-test-monthly"   = local.s3_backup_rule_test_monthly,
      "${var.name}-s3-backup-rule-test-quarterly" = local.s3_backup_rule_test_quarterly
    }

    selections = local.s3_backup_selections
  }

  s3_backup_rule_test_daily = {
    target_backup_vault_name       = { "@@assign" = var.s3_target_backup_vault_name }
    schedule_expression            = { "@@assign" = var.s3_schedule_expression_daily }
    start_backup_window_minutes    = { "@@assign" = var.s3_start_backup_window_minutes }
    complete_backup_window_minutes = { "@@assign" = var.s3_complete_backup_window_minutes }
    enable_continuous_backup       = { "@@assign" = var.s3_enable_continuous_backup }
    lifecycle                      = local.s3_lifecycle_test_daily
  }

  s3_lifecycle_test_daily = {
    delete_after_days = { "@@assign" = var.s3_delete_after_days_daily }
  }

  s3_backup_rule_test_weekly = {
    target_backup_vault_name       = { "@@assign" = var.s3_target_backup_vault_name }
    schedule_expression            = { "@@assign" = var.s3_schedule_expression_weekly }
    start_backup_window_minutes    = { "@@assign" = var.s3_start_backup_window_minutes }
    complete_backup_window_minutes = { "@@assign" = var.s3_complete_backup_window_minutes }
    lifecycle                      = local.s3_lifecycle_test_weekly
    copy_actions                   = local.s3_copy_actions_cross_account_test_weekly
  }

  s3_lifecycle_test_weekly = {
    delete_after_days = { "@@assign" = var.s3_delete_after_days_weekly }
  }

  s3_backup_rule_test_monthly = {
    target_backup_vault_name       = { "@@assign" = var.s3_target_backup_vault_name }
    schedule_expression            = { "@@assign" = var.s3_schedule_expression_monthly }
    start_backup_window_minutes    = { "@@assign" = var.s3_start_backup_window_minutes }
    complete_backup_window_minutes = { "@@assign" = var.s3_complete_backup_window_minutes }
    lifecycle                      = local.s3_lifecycle_test_monthly
    copy_actions                   = local.s3_copy_actions_cross_account_test_monthly
  }

  s3_lifecycle_test_monthly = {
    delete_after_days = { "@@assign" = var.s3_delete_after_days_monthly }
  }

  s3_backup_rule_test_quarterly = {
    target_backup_vault_name       = { "@@assign" = var.s3_target_backup_vault_name }
    schedule_expression            = { "@@assign" = var.s3_schedule_expression_quarterly }
    start_backup_window_minutes    = { "@@assign" = var.s3_start_backup_window_minutes }
    complete_backup_window_minutes = { "@@assign" = var.s3_complete_backup_window_minutes }
    lifecycle                      = local.s3_lifecycle_test_quarterly
    copy_actions                   = local.s3_copy_actions_cross_account_test_quarterly
  }

  s3_lifecycle_test_quarterly = {
    delete_after_days = { "@@assign" = var.s3_delete_after_days_quarterly }
  }

  # Backup account, cross region
  s3_copy_actions_cross_account_test_weekly = {
    "${aws_backup_logically_air_gapped_vault.this.arn}" = {
      target_backup_vault_arn = {
        "@@assign" = "${aws_backup_logically_air_gapped_vault.this.arn}"
      }
      lifecycle = local.s3_lifecycle_test_weekly
    }
  }

  # Backup account, cross region
  s3_copy_actions_cross_account_test_monthly = {
    "${aws_backup_logically_air_gapped_vault.this.arn}" = {
      target_backup_vault_arn = {
        "@@assign" = "${aws_backup_logically_air_gapped_vault.this.arn}"
      }
      lifecycle = local.s3_lifecycle_test_monthly
    }
  }

  # Backup account, cross region
  s3_copy_actions_cross_account_test_quarterly = {
    "${aws_backup_logically_air_gapped_vault.this.arn}" = {
      target_backup_vault_arn = {
        "@@assign" = "${aws_backup_logically_air_gapped_vault.this.arn}"
      }
      lifecycle = local.s3_lifecycle_test_quarterly
    }
  }

  s3_backup_selections = {
    tags = {
      for key, value in var.s3_backup_selections :
      key => {
        iam_role_arn = {
          "@@assign" = "arn:aws:iam::$account:role/${var.s3_backup_selections_role_name}"
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
