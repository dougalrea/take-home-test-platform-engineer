# EKS Cluster Decommissioning — Design & Automation Task

## Context
Our EKS clusters are provisioned by the attached Terraform module. Each AWS account
gets one EKS cluster. Some of those clusters are no longer needed and should be
decommissioned — we do not want to pay for empty infrastructure.

Assume decommissioning may happen **1-2 times per month**, and (if possible) we want
to avoid our engineers performing repetitive manual tasks. **We prioritise automation
wherever possible.**

## Your Task
1. **Investigate** the Terraform configuration and understand how EKS clusters are provisioned
2. **Identify** what infrastructure exists per account (EKS, Karpenter, Helm, RDS, etc.)
3. **Examine** the existing `account_state` variable and partial decommissioning logic
4. **Identify gaps** — what currently breaks or is missing if you try to fully decommission
5. **Propose a decommissioning plan**, covering:
   - Terraform code changes needed to safely tear down an account's EKS infrastructure
   - Destroy ordering for Kubernetes resources (Helm, CRDs, NodePools, etc.)
   - How the Kubernetes provider should handle a cluster that may be destroyed
   - CI/CD pipeline changes to reduce manual toil
6. **Design automation** — given this happens 1-2x/month, propose how to minimise repetitive work

## Provided Materials
- `terraform/modules/eks-cluster/` — EKS cluster Terraform module
- `terraform/modules/eks-karpenter/` — Karpenter controller module
- `terraform/modules/eks-karpenter-nodeclass/` — Karpenter EC2 node class module
- `terraform/eks-cluster.tf` — Root-level EKS cluster instantiation
- `terraform/eks-controller-karpenter.tf` — Root-level Karpenter wiring (NodePools, NodeClasses)
- `terraform/eks-auth.tf` — Kubernetes RBAC / aws-auth configmap setup
- `terraform/main.tf` — Provider config and decommissioning locals
- `terraform/variables.tf` — Root variable definitions
- `terraform/versions.tf` — Provider requirements
- `var-files/` — Per-account .tfvars files (mix of active and decommissioned)
- `.github/workflows/` — CI/CD pipeline (3 workflow files)

## Architecture Overview
- Multi-account AWS Organization (~17 prod accounts + test + staging)
- 1 EKS cluster per account (Fargate for system pods + Karpenter for EC2 workloads)
- Karpenter with 2 node pools: `default` (general compute) and `metaflow` (ML workloads)
- AWS Load Balancer Controller, Argo Workflows, Metaflow services on each cluster
- Per-account configuration via `.tfvars` files
- GitHub Actions CI/CD: PR → plan all accounts; merge → sequential apply
- Partial decommissioning mechanism via `account_state` variable

## Hints
- Look carefully at what happens to the Kubernetes provider when the cluster goes away
- Consider the destroy ordering of Helm releases that depend on each other's webhooks
- Think about what resources are always created vs conditionally created
- The CI/CD workflow matrices are hardcoded — what happens as accounts come and go?