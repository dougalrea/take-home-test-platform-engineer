# AWS Backup Cost Optimization Assessment

## Context
1. We have ~N AWS accounts across prod, staging, test environments
2. Each account has: 1 Metaflow RDS instance, 2-3 S3 buckets tagged for backup
3. Some accounts are decommissioned but may still have backup resources

The business is concerned about the ongoing AWS bill. After superficial investigation, 
it was discovered that **backups drive a significant proportion of the spending**.

## Your Task
1. **Investigate** the provided backup cost data and Terraform configuration
2. **Identify** the root causes of the high backup costs
3. **Propose solutions** to lower the cost
4. **Consider tradeoffs** — what are the risks of each change?
5. **Document your recommendations** with estimated savings

## Provided Materials
- `/data/` — Backup cost spreadsheets across 2-3 AWS accounts
- `/terraform-*` — Terraform module(s) describing the existing backup policy
- Architecture context.md - 

## Deliverables
- A written analysis document (markdown or PDF) - 1 page maximum
- Proposed Terraform changes (as a diff or modified files)
- A summary of tradeoffs and business decisions required

## Time
You have 2 hours to complete this assessment. 

# Architecture Context

## AWS Organization Structure
```
Root
├── workloads/
│   ├── prod/          ← RDS + S3 backup policy (PROD tier)
│   │   ├── prod.main
│   │   ├── prod.partner-a
│   │   └── prod.partner-b
│   ├── staging/       ← RDS + S3 backup policy (PROD tier!)
│   │   └── staging.main
│   └── test/          ← RDS + S3 backup policy (TEST tier)
│       └── test.main
├── security/          ← S3 backup policy (PROD tier)
│   ├── security.backups  (← backup delegated admin)
│   ├── security.audit
│   └── security.logs
└── sandbox            ← RDS + S3 backup policy (TEST tier, account-level)
```

## Per Account Resources
Each workload account typically contains:
- 1x Metaflow RDS PostgreSQL instance (tagged RDSBackup=true)
- 1x Metaflow S3 datastore bucket (tagged S3Backup=true)
- 1x Share S3 bucket (tagged S3Backup=true)
- 1x Catalog S3 bucket (tagged S3Backup=true)
- 1x Config S3 bucket (tagged S3Backup=true)

## Key Notes
- Some accounts have been decommissioned but resources may still exist
- The staging OU uses the **prod** backup policy tier
- Continuous backup is enabled for both RDS (PITR) and S3
