# infratask2_services_eks

This module creates resources required for running our internal services on EKS. Mostly, this means:

- An EKS cluster and Fargate profile
- Assumable IAM roles for Kubernetes Service Accounts

The docs are created, in part, using [terraform-docs](https://terraform-docs.io/). To update the docs, run:

```bash
terraform-docs markdown table . \
  --show requirements,inputs,outputs \
  --output-file README.md
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | ~> 2.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 2.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | ~> 20.0 |

## Resources

| Name | Type |
|------|------|
| [aws_eks_access_entry.terraform_admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_entry) | resource |
| [aws_eks_access_policy_association.terraform_admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_policy_association) | resource |
| [aws_iam_policy.cloudwatch_observability_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.eks_fargate_logging_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.cloudwatch_observability](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.cloudwatch_observability](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.eks_fargate_logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_security_group_rule.ec2_node_all_ingress_from_self](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ec2_node_egress_fargate_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ec2_node_ingress_fargate_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.fargate_node_egress_ec2_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.fargate_node_ingress_ec2_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [kubectl_manifest.aws_logging_configmap](https://registry.terraform.io/providers/alekc/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace.aws_observability](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [terraform_data.cloudwatch_log_group_names](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [aws_iam_policy_document.cloudwatch_observability_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cloudwatch_observability_trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_decommissioned"></a> [account\_decommissioned](#input\_account\_decommissioned) | Whether the account is decommissioned | `bool` | `false` | no |
| <a name="input_cloudwatch_log_group_names"></a> [cloudwatch\_log\_group\_names](#input\_cloudwatch\_log\_group\_names) | A list of EKS CloudWatch log group names | `list(string)` | `[]` | no |
| <a name="input_eks_addon_observability_enabled"></a> [eks\_addon\_observability\_enabled](#input\_eks\_addon\_observability\_enabled) | EKS amazon cloudwatch observability add-on enabled | `bool` | `false` | no |
| <a name="input_eks_addon_version_amazon_cloudwatch_observability"></a> [eks\_addon\_version\_amazon\_cloudwatch\_observability](#input\_eks\_addon\_version\_amazon\_cloudwatch\_observability) | EKS amazon cloudwatch observability add-on version | `string` | `"v3.7.0-eksbuild.1"` | no |
| <a name="input_eks_addon_version_coredns"></a> [eks\_addon\_version\_coredns](#input\_eks\_addon\_version\_coredns) | EKS coredns add-on version | `string` | `"v1.10.1-eksbuild.4"` | no |
| <a name="input_eks_addon_version_kube_proxy"></a> [eks\_addon\_version\_kube\_proxy](#input\_eks\_addon\_version\_kube\_proxy) | EKS kube-proxy add-on version | `string` | `"v1.28.2-eksbuild.2"` | no |
| <a name="input_eks_addon_version_vpc_cni"></a> [eks\_addon\_version\_vpc\_cni](#input\_eks\_addon\_version\_vpc\_cni) | EKS vpc-cni add-on version | `string` | `"v1.15.1-eksbuild.1"` | no |
| <a name="input_eks_cluster_authentication_mode"></a> [eks\_cluster\_authentication\_mode](#input\_eks\_cluster\_authentication\_mode) | The EKS Cluster authentication mode. | `string` | `"CONFIG_MAP"` | no |
| <a name="input_eks_cluster_name"></a> [eks\_cluster\_name](#input\_eks\_cluster\_name) | The name of the EKS cluster | `string` | `"example-cluster"` | no |
| <a name="input_eks_cluster_version"></a> [eks\_cluster\_version](#input\_eks\_cluster\_version) | The EKS Cluster version | `string` | `"1.31"` | no |
| <a name="input_eks_module_tags"></a> [eks\_module\_tags](#input\_eks\_module\_tags) | The defalt set of tags that the EKS module will apply to all resources it creates. | `map(string)` | `{}` | no |
| <a name="input_fargate_profiles"></a> [fargate\_profiles](#input\_fargate\_profiles) | The map of Fargate profiles that the EKS module will create. | `any` | <pre>{<br/>  "kube_system": {<br/>    "name": "kube-system",<br/>    "selectors": [<br/>      {<br/>        "namespace": "kube-system"<br/>      }<br/>    ]<br/>  }<br/>}</pre> | no |
| <a name="input_kms_key_administrators"></a> [kms\_key\_administrators](#input\_kms\_key\_administrators) | ARN of the IAM Roles that can administer the EKS KMS Key | `list(string)` | n/a | yes |
| <a name="input_kms_key_owners"></a> [kms\_key\_owners](#input\_kms\_key\_owners) | ARN of the IAM Roles that can manage the EKS KMS Key | `list(string)` | n/a | yes |
| <a name="input_kubernetes_admin_role_arn"></a> [kubernetes\_admin\_role\_arn](#input\_kubernetes\_admin\_role\_arn) | The ARN of the Kubernetes Admin role in this account, e.g. arn:aws:iam::123456789012:role/terraform-admin | `string` | n/a | yes |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | A list of subnet IDs in which to place the EKS cluster and nodes | `list(string)` | n/a | yes |
| <a name="input_public_subnet_cidr_blocks"></a> [public\_subnet\_cidr\_blocks](#input\_public\_subnet\_cidr\_blocks) | A list of CIDR blocks for public subnets in which ALBs exposing the cluster are hosted | `list(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC in which to create the EKS cluster | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_addons"></a> [cluster\_addons](#output\_cluster\_addons) | Map of EKS Addons created |
| <a name="output_cluster_certificate_authority_data"></a> [cluster\_certificate\_authority\_data](#output\_cluster\_certificate\_authority\_data) | n/a |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | n/a |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | n/a |
| <a name="output_cluster_security_group_id"></a> [cluster\_security\_group\_id](#output\_cluster\_security\_group\_id) | n/a |
| <a name="output_eks_cluster_oidc_issuer_url"></a> [eks\_cluster\_oidc\_issuer\_url](#output\_eks\_cluster\_oidc\_issuer\_url) | n/a |
| <a name="output_eks_node_security_group_id"></a> [eks\_node\_security\_group\_id](#output\_eks\_node\_security\_group\_id) | n/a |
| <a name="output_eks_oidc_provider_arn"></a> [eks\_oidc\_provider\_arn](#output\_eks\_oidc\_provider\_arn) | n/a |
| <a name="output_fargate_profiles"></a> [fargate\_profiles](#output\_fargate\_profiles) | Map of attribute maps for all EKS Fargate Profiles created |
<!-- END_TF_DOCS -->
