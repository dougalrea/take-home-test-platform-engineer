<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.9.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.17.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_karpenter_sqs"></a> [karpenter\_sqs](#module\_karpenter\_sqs) | terraform-aws-modules/eks/aws//modules/karpenter | ~> 20.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.karpenter_controller_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.karpenter_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.karpenter_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [helm_release.karpenter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.karpenter_crd](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.karpeneter_controller_iam_role_trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_decommissioned"></a> [account\_decommissioned](#input\_account\_decommissioned) | Is this AWS Account in a decommissioned state? | `bool` | `false` | no |
| <a name="input_eks_cluster_name"></a> [eks\_cluster\_name](#input\_eks\_cluster\_name) | Name of the EKS cluster | `string` | n/a | yes |
| <a name="input_eks_oidc_issuer_url"></a> [eks\_oidc\_issuer\_url](#input\_eks\_oidc\_issuer\_url) | The URL on the EKS cluster for the OpenID Connect identity provider | `string` | n/a | yes |
| <a name="input_eks_oidc_provider_arn"></a> [eks\_oidc\_provider\_arn](#input\_eks\_oidc\_provider\_arn) | The ARN of the EKS cluster OIDC Provider | `string` | n/a | yes |
| <a name="input_karpenter_additional_node_iam_role_arns"></a> [karpenter\_additional\_node\_iam\_role\_arns](#input\_karpenter\_additional\_node\_iam\_role\_arns) | Additional ARNs for Karpenter node roles | `list(string)` | `[]` | no |
| <a name="input_karpenter_chart_version"></a> [karpenter\_chart\_version](#input\_karpenter\_chart\_version) | Chart version for Karpenter | `string` | `"1.4.0"` | no |
| <a name="input_karpenter_cpu"></a> [karpenter\_cpu](#input\_karpenter\_cpu) | CPU for Karpenter | <pre>object({<br/>    request = string<br/>    limit   = string<br/>  })</pre> | <pre>{<br/>  "limit": "2",<br/>  "request": "1"<br/>}</pre> | no |
| <a name="input_karpenter_log_level"></a> [karpenter\_log\_level](#input\_karpenter\_log\_level) | Log level for Karpenter | `string` | `"info"` | no |
| <a name="input_karpenter_memory"></a> [karpenter\_memory](#input\_karpenter\_memory) | Memory for Karpenter | <pre>object({<br/>    request = string<br/>    limit   = string<br/>  })</pre> | <pre>{<br/>  "limit": "4Gi",<br/>  "request": "2Gi"<br/>}</pre> | no |
| <a name="input_karpenter_namespace"></a> [karpenter\_namespace](#input\_karpenter\_namespace) | Namespace for Karpenter | `string` | n/a | yes |
| <a name="input_karpenter_replicas"></a> [karpenter\_replicas](#input\_karpenter\_replicas) | Replicas for Karpenter | `string` | `"2"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_helm_release_karpenter_id"></a> [helm\_release\_karpenter\_id](#output\_helm\_release\_karpenter\_id) | n/a |
| <a name="output_karpenter_role_arn"></a> [karpenter\_role\_arn](#output\_karpenter\_role\_arn) | n/a |
| <a name="output_karpenter_role_name"></a> [karpenter\_role\_name](#output\_karpenter\_role\_name) | n/a |
<!-- END_TF_DOCS -->