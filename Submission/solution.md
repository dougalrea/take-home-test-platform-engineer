## 1. Analysis of Scenario 2

### IaC Resources Rundown

#### Always created (regardless of commission status)

| Resource | Terraform ID | Notes |
| :--- | :--- | :--- |
| **EKS Cluster** | `module.eks_cluster` → `module.eks` | Never destroyed via `account_decommissioned` |
| **EKS access entries** | `aws_eks_access_entry.terraform_admin` | Admin role association |
| **SG rules (EC2↔Fargate)** | `aws_security_group_rule.*` | 5 rules for cross-plane comms |
| **Karpenter IAM Role** | `aws_iam_role.karpenter_controller` | No count guard — survives decommission |
| **Karpenter IAM Policy** | `aws_iam_policy.karpenter_controller_iam_role` | No count guard |
| **Karpenter SQS queue** | `module.karpenter_sqs` | No count guard |
| **EC2 Spot service-linked role** | `aws_iam_service_linked_role.ec2_spot` | Shared account-wide resource |
| **GuardDuty EKS addon** | `aws_eks_addon.aws_guardduty_agent` | No count guard |
| **aws-auth ConfigMap** | `module.eks_aws_auth_configmap` | No count guard |
| **Fargate logging ConfigMap** | `kubectl_manifest.aws_logging_configmap` | No count guard |
| **aws-observability namespace** | `kubernetes_namespace.aws_observability` | No count guard |
| **VPC + subnets** | `module.vpc` (inferred) | Never shown in decommission path |
| **S3 buckets** | `share`, `catalog`, `metaflow` | Never shown in decommission path |
| **Route53 + ACM certs** | domain-related resources | Never shown in decommission path |
| **RDS (Metaflow DB)** | inferred from `metaflow_db_*` vars | Never shown in decommission path |
| **CloudWatch log groups** | `aws_cloudwatch_log_group.eks` | Never shown in decommission path |

#### Conditionally created (depending on count guard `count = 0` when `local.account_decommissioned = true`)

| Resource | Terraform ID |
| :--- | :--- |
| **EKS Fargate profiles** | `module.eks.fargate_profiles` (emptied) |
| **EKS addons (kube-proxy, vpc-cni, coredns, CW observability)** | `module.eks.cluster_addons` (emptied) |
| **Karpenter CRD Helm release** | `helm_release.karpenter_crd` |
| **Karpenter controller Helm release** | `helm_release.karpenter` |
| **Karpenter NodeClasses** | `module.karpenter_nodeclass_*` (EC2NodeClass custom resource manifest + IAM role + instance profile)|
| **NodePool manifests** | `kubectl_manifest.karpenter_nodepool_*` |
| **NodePool drain timers** | `time_sleep.wait_karpenter_nodepool_*` |
| **Fargate logging IAM policy & attachment** | `aws_iam_policy.eks_fargate_logging_iam_role`, `aws_iam_role_policy_attachment.eks_fargate_logging`  |

### account_state variable & partial decommissioning logic

The account_state variable is defined at the partner account level and must be either 'pre-commissioned', 'commissioned', 'pre-decommissioned' or 'decommissioned'. The `account_decommissioned` variable is defined dynamically in local vars depending on account_state as follows:

"pre-commissioned"  ──►  account_decommissioned = true
"commissioned"      ──►  account_decommissioned = false  (NodePool consolidateAfter = 60m / 5m)
"pre-decommissioned"──►  account_decommissioned = false  (NodePool consolidateAfter = 1m / 1m)
"decommissioned"    ──►  account_decommissioned = true

Intermediate state between commissioned and decomissioned is controlled via `pre-decommissioned` - in this state (and indeed any state besides `commissioned`) Karpenter nodes are consolidated (using consolidateAfter → 1 minute) so EC2 worker nodes drain before the Helm/CRD EKS resources are removed. The count gate that destroys resources when `account_decommissioned = true` only comes into effect when account_state is `decommissioned`.

### Gaps & bugs in decommissioning flow

## Kubernetes, Kubectl & Helm providers depend on EKS cluster

```
# main.tf — always references live cluster outputs
provider "kubernetes" {
  host                   = module.eks_cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority_data)
  exec { ... "aws" "eks" "get-token" ... }
}
```
This dependency on EKS cluster means even when an account is decommissioned, it is required to retain its EKS cluster simply for terraform initialisation. If a cluster were to be deleted, or if it's endpoint were to become unreachable for any other reason, every subsequent terraform run would crash at provider initialization, before any resource plan can be evaluated. Not only does this demand unnecessary expenditure on running "dead" clusters in decommissioned accounts - it also exposes a dangerous risk of being unable to redeploy/repair infrastructure via terraform in the event of a cluster becoming accidentally unreachable. Same issue accross Kubctl and Helm providers since these also reference the EKS cluster directly.

## Multiple resources are missing count guard
Some resources both within kubernetes (eg the guard duty agent EKS addon, the AWS auth configmap) and within the wider AWS account (eg karpenter IAM resources, SQS queue, EKS cluster itself, security groups) will persist beyond account decommissioning because they have no count field dependent on the `account_decommissioned` vairable. These lingering resources generate unnecessary costs (EKS cluster, SQS queue) and clutter (IAM resources etc).

## Resource ordering

The karpenter-crd helm chart has no explicit dependency on the kubectl_manifest resources for NodePools. When a CRD is deleted, kubernetes cascade-deletes all related custom resources, which would include the karpenter controller responsible for cleaning up underlying nodes. Without safe resource destruction ordering, this could result in dangling EC2 instances with no controller alive to clean them up. Safe ordering should be configured as follows:
- Dlete individual CRs first (not the CRDs) - so `karpenter_nodepool_default` and `karpenter_nodepool_metaflow`
- Wait for karpenter to automatically clean up (terminate) EC2 instances
- Then uninstall karpenter controller `helm_release.karpernter` 
- Finally destroy the karpenter CRD `helm_release.karpernter_crd`

Safe ordering can be achieved by addition of `depends_on` fields on node pool resources (`helm_release.karpernter` already depends on `helm_release.karpernter_crd`, and node classes already depend on `module.karpenter.helm_release_karpenter_id`).

## Hardcoded accounts in CI

The GA workflow files have hardcoded lists of account IDs which requires manual update when accounts are added or decommissioned, even if their account_status has already been updated to "decommissioned" in partnerX.tfvars. For example, `partner4` is decommissioned as seen in tfvars but its account ID is hardcoded in CI workflows, meaning terraform still runs plans and applies against that account on every PR & merge -> wasted github actions compute time & cost. Removing the ID from CI requires another manual change to decommission an account, meaning a separate PR unless dev remembers to update tfvars and remove account ID from CI in the same change, high risk of human error and unnecessary developer overhead. Single source of truth for account satus preferred.

```
        account: [
          { name: "partner1", id: "1234567890", region: "eu-west-1"},
          { name: "partner2", id: "2234567890", region: "eu-west-1"},
          { name: "partner3", id: "3234567890", region: "eu-west-1"},
          { name: "partner4", id: "4234567890", region: "eu-west-1"}
        ]
```

## Pre-decommissioned phase not properly utilised as precursor to decommissioned
The implementation of the pre-decommissioned step seems half-baked and fragile - the only thing that changes when account_state is set to pre-decommissioned is the consolidateAfter time on node pools, and the time_sleep for node pool destruction. It just means karpenter waits less time before consolidating live pods into minimum nodes, it doesn't actually kill any running services as far as I can see. The `account_decommissioned` variable remains false when account_state is pre-decommissioned, so none of the count guards are affected. 

Currently, there is also no enforcement to require progression from commissioned -> pre-decommissioned -> decommissioned; dev could feasibly go straight to decommissioned state. This would mean resources would begin getting destroyed while time_sleep is still set to 70 minutes (60 + 10), delaying the termination of nodes for over an hour.

## 2. Questions for stakeholders
- Are there any resources either within kubernetes or the AWS account as a whole which must be retained beyond account decommissioning? Eg any application/node logs, cloudtrail event histories, config maps etc... Or can the AWS account be nuked in its entirety either immediately or after a cool-down window when decommissioned?
- Metaflow DB, S3 buckets, cloudwatch log groups aren't visible in this codebase, do any of them require retention beyond decommissioning?
- partner4 tfvars features a `metaflow_db_snapshot_identifier` - was this a final snapshot of the DB before decommissioning, was it generated automatically or manually, and where is it stored? Does this prevent shut down of the account? This 

## 3. Technical Solution Proposal

### Provide safe fallback for kubernetes_provider_config
This will ensure Kubernetes, Kubectl, and Helm providers can successfully initialize even when the cluster is absent, and thereby allows terraform to load config and evaluate plan/diff without attempting a real connection. This is safe because when `account_decommissioned = true`, all kubernetes-based resources should have `count = 0` anyway.

```
# main.tf
locals {
  kubernetes_provider_config = {
    host = (
      local.account_decommissioned
      ? "https://localhost:6443"   # unreachable but valid URL; prevents provider crash
      : module.eks_cluster.cluster_endpoint
    )
    cluster_ca_certificate = (
      local.account_decommissioned
      ? base64encode("placeholder")
      : base64decode(module.eks_cluster.cluster_certificate_authority_data)
    )
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      args = local.account_decommissioned ? ["version"] : [
        "eks", "get-token",
        "--cluster-name", module.eks_cluster.cluster_name
      ]
      command = "aws"
    }
  }
}
```

### Add count guards to all kubernetes-backed resources currently missing them

using `count = local.account_decommissioned ? 0 : 1` or `count = var.account_decommissioned ? 0 : 1` where applicable in the resource definitions under the following TF IDs:
- aws_eks_addon.aws_guardduty_agent
- eks_aws_auth_configmap
- aws_iam_policy.karpenter_controller_iam_role
- aws_iam_role.karpenter_controller
- aws_iam_role_policy_attachment.karpenter_controller
- karpenter_sqs
- kubernetes_namespace.aws_observability
- kubectl_manifest.aws_logging_configmap

Example code given for aws_eks_addon.aws_guardduty_agent, the rest are very similar:
```
resource "aws_eks_addon" "aws_guardduty_agent" {
  count        = local.account_decommissioned ? 0 : 1
  cluster_name = module.eks_cluster.cluster_name
  ...
}
```

### Extend depends_on ordering to NodePool & NodeClass manifests

The NodePool manifest resource defs need to specify dependency on the CRD release in order to ensure safe ordering of resource creation & destruction. This therefore also requires the definition of a new output on the eks-karpenter module:
```
output "helm_release_karpenter_crd_id" {
  value = var.account_decommissioned ? null : helm_release.karpenter_crd[0].id
}
```
And then dependencies added to manifests:
```
resource "kubectl_manifest" "karpenter_nodepool_default" {
  count = local.account_decommissioned ? 0 : 1
  ...
  depends_on = [
    module.karpenter.helm_release_karpenter_crd_id
  ]
}
```

Full resource destruction order should be as follows (note full tear-down of kubernetes resources first, then destruction of infra in wider AWS account):

1.  [K8s] Workload Helm releases (Metaflow services, Argo Workflows)
2.  [K8s] AWS Load Balancer Controller Helm release
         → issues DeleteLoadBalancer for any owned Services/Ingresses
3.  [K8s] time_sleep drain wait fires (NodePools still exist, Karpenter drains EC2 nodes)
4.  [K8s] kubectl_manifest: NodePool (default + metaflow) CRs deleted
5.  [K8s] kubectl_manifest: EC2NodeClass (default-nc + metaflow-nc) CRs deleted
6.  [K8s] helm_release: karpenter (controller) uninstalled
7.  [K8s] helm_release: karpenter-crd uninstalled
         → CRDs removed; no remaining CR instances → safe
8.  [AWS] Karpenter IAM role, policy, SQS queue, EventBridge rules
9.  [AWS] GuardDuty EKS addon
10. [AWS] EKS Fargate profiles
11. [AWS] EKS cluster addons (kube-proxy, vpc-cni, coredns)
12. [AWS] NodeClass IAM roles + instance profiles
13. [AWS] EKS cluster itself
14. [AWS] RDS instance (after final snapshot)
15. [AWS] VPC, subnets, security groups
16. [AWS] S3 buckets (with object retention consideration)
17. [AWS] Route53 records, ACM certs, CloudWatch log groups


### Reduce manual toil in CICD

Add a job to PR & Merge workflows to dynamically compile JSON object of active accounts by reading from tfvars, ignoring any decommissioned (or pre-commissioned) accounts:

```
  discover-accounts:
    runs-on: ubuntu-latest
    outputs:
      prod_partners: ${{ steps.discover-active-accounts.outputs.prod_partners }}
    steps:
      - id: discover-active-accounts
        name: Discover active partner accounts
        run: |
          # Output JSON array of non-decommissioned partner accounts
          partners=$(
            for f in var-files/workloads.prod.partner*.tfvars; do
              name=$(basename "$f" .tfvars | sed 's/workloads\.prod\.//')
              state=$(grep '^account_state' "$f" | awk -F'"' '{print $2}')
              id=$(grep '^main_aws_account_id' "$f" | awk -F'"' '{print $2}')
              if [ "$state" != "decommissioned" ] && [ "$state" != "pre-commissioned" ]; then
                echo "{\"name\":\"$name\",\"id\":\"$id\",\"region\":\"eu-west-1\"}"
              fi
            done | jq -sc '.'
          )
          echo "prod_partners=$partners" >> "$GITHUB_OUTPUT"
```

This results in single source of truth for account status & reduces decommissioning friction (by minimising manual steps to 1). Also minimises wasted GA compute on plans / applies against decommissioned accounts.


### Automation design for 1-2x/month decommissioning

Given fairly low frequency of decommissioning, two step process (commissioned -> pre-decommissioned -> decommissioned) via 2 PRs considered acceptable. This also grants safer control over reversion to commissioned state in event of disaster (applications ervices can likely be spun back up on existing infrastructure much faster than an entire infra & application stack can be redeployed). 

However this could be further consolidated into a single PR in future, wherein "pre-decommissioned" state is skipped and a single set of GA workflows performs all steps required to tear down first application, then infrastructure from single update of account_state from commissioned to decommissioned:

#### Proposed automation flow (2 PRs)
Engineer receives decommission request
         │
         ▼
1. Open PR: change account_state to "pre-decommissioned" in .tfvars
   CI plans → shows consolidateAfter & time_sleep change only → quick review → merge
         │
         ▼
2. Merge triggers TF apply, wait for Karpenter to consolidate EC2 nodes (rapid with new 1m consolidateAfter)
   [Optional: verify_nodes_drained terraform_data resource enforces this in CI]
         │
         ▼
3. Open PR: change account_state to "decommissioned" in .tfvars
   CI plans → shows ordered destruction of all K8s, Karpenter, & AWS resources → review plan
   Merge → sequential apply wth safe resource destruction ordering, ~30 minutes, no manual steps
         │
         ▼
4. RDS snapshot: automated via Terraform lifecycle policy
         │
         ▼
5. Account removed from CI matrix automatically (discover-accounts job reads tfvars)
         │
         ▼
6. Full account teardown (if required, and only after cooldown / required artifacts eg snapshots are safely exported): potential automated use of aws-nuke to destroy everything left in account and prepare it for deletion from AWS enterprise.

## 4. Trade-offs and considerations

### Optional node-drain confirmation
pre-decommissioned phase only updates consolidateAfter and time_sleep on node pool destruction. Optionally extend this phase to kill all application pods before consolidation and subsequently check emptying of cluster via node drain confirmation script in terraform_data resource eg:
```
resource "terraform_data" "verify_nodes_drained" {
  count = var.account_state == "pre-decommissioned" ? 1 : 0

  triggers_replace = [var.account_state]

  provisioner "local-exec" {
    command = <<-EOF
      echo "Verifying EC2 nodes are drained from ${module.eks_cluster.cluster_name}..."
      aws eks update-kubeconfig --name ${module.eks_cluster.cluster_name} --region eu-west-1
      NODE_COUNT=$(kubectl get nodes -l karpenter.sh/nodepool --no-headers 2>/dev/null | wc -l | tr -d ' ')
      if [ "$NODE_COUNT" -gt "0" ]; then
        echo "WARNING: $NODE_COUNT Karpenter-managed nodes still exist. Wait for consolidation."
        exit 1
      fi
      echo "All Karpenter nodes drained. Safe to proceed to decommissioned."
    EOF
  }
}
```

### Clean-up of LBC, Argo & Metaflow resources
The helm_release.load_balancer_controller (and presumably Argo Workflows / Metaflow Helm releases) are not visible in the provided files but are depended upon by Karpenter. If they exist and lack count = local.account_decommissioned ? 0 : 1 guards, they will:

- Continue to be applied even on decommissioned accounts (wasted work, potential errors)
- Not be properly uninstalled before the cluster or CRDs are removed
- Leave behind AWS resources (ALBs, NLBs, IAM roles) that Terraform no longer tracks

The AWS Load Balancer Controller specifically must be uninstalled before cluster deletion so it can issue DeleteLoadBalancer API calls for any Kubernetes Service or Ingress objects it owns. If the cluster is deleted first, those AWS resources become orphaned and continue to incur cost.

### Repeated code in CICD

The new job to discover active partner accounts is currently repeated across both PR & Merge workflow - this is not DRY. Future work could include separating this logic out into separate invocable workflow, but given this is fairly small job, simple logic, it's repetition accross workflows is considered fine for the time being.

### Possible ordering issue on EKS module tear down

All resources in the eks-cluster module are now controlled by a count guard. This has been applied separately across all resources including on the module.eks resource itself. While the module.eks is a rather large module with a number of nested resources such as cloudwatch log groups, KMS infra, security group rules etc, it is assumed safe ordering has been configured within the 3rd party resource. Setting the count guard at the module level should instruct terraform to tear down all resources nested within it in a safe order, but there is no fine-grained control over this. The security group rule resources in eks-cluster/main.tf have an implicit dependency on the cluster so should be torn down before the cluster itself.

### Enforcement of progression through pre-decommissioned state not covered
Given time constraints of task, assuming the PR review process is enough to prevent devs updating account_state from `commissioned` directly to `decommissioned` for now. Future work could implement brief GA workflow triggered on PR open (only when changes detected in tfvars file) to check if `account_state: decommissioned` is present is set in updated file, was `account_state: pre-decommissioned` set in the original.

## 5. Assumptions
Included in brief:
- Decommissioning may happen 1-2 times a month
- We want to avoid engineers performing repetitive manual tasks
- We prioritize automation wherever possible

Own assumptions:
- The `helm_release.load_balancer_controller` resource is referenced in `depends_on` inside `eks-controller-karpenter.tf`, but its definition is not in the provided files. Similarly, Argo Workflows and Metaflow Helm releases are referenced only via domain name locals. These are assumed to exist and assumed to already be part of the decommission plan (ie controlled via count guard dependent on account_decommissioned boolean).
- Desired function of pre-decommissioning state is solely to reduce the time_sleep for rapid nodepool destruction, and consolidateAfter for rapid node consolidation. Further work may involve extending the function of the pre-decommissioned state to scale down all application pods, allow karpenter to consolidate EC2 instances to 0 nodes, and leave cluster empty of business workloads (fargate may remain for system pods). This would make sense as precurser to `decommissioned`, which fully tears down infrastructure from account (ie two step process reflects tear-down of application workloads first, followed by infrastructure & auxilliaries).
