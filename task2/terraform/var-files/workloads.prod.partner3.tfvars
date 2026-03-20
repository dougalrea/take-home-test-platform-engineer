environment         = "prod"
account_name        = "partner3"
account_type        = "partner"
partner_id          = "natcap-partner3"
domain_name         = "partner3.infratask2natcap.com"
main_aws_account_id = "3234567890"
main_aws_account_state_config = {
  bucket = "ncr-tfstate-3234567890"
  key    = "infrastructure.tfstate"
  region = "eu-west-1"
}
enable_vpc_cidr_automation                  = false
vpc_endpoints_services                      = []
share_bucket_name                           = "ncr-share-partner3"
share_bucket_allow_ssl_requests_only        = false
share_bucket_allow_encrypted_uploads_only   = false
share_bucket_enforce_tls_version            = false
catalog_bucket_name                         = "ncr-catalog-partner3"
catalog_bucket_encryption_scheme            = "SSE-S3"
create_catalog_bucket_kms_key               = false
catalog_bucket_allow_ssl_requests_only      = false
catalog_bucket_allow_encrypted_uploads_only = false
catalog_bucket_enforce_tls_version          = false
create_helm_reloader                        = true
create_metaflow_datastore_kms_key_policy    = false
metaflow_bucket_name                        = "metaflow-s3-cb290b5c61f8a086"
metaflow_resource_prefix                    = "metaflow"
metaflow_resource_suffix                    = "cb290b5c61f8a086"
metaflow_role_secrets_arns_additional = [
  "arn:aws:secretsmanager:eu-west-1:xxx:secret:gcp/service-accounts/customer-xxx"
]
metaflow_nice_load_balancer_names                       = false
metaflow_config_bucket_allow_ssl_requests_only          = false
metaflow_config_bucket_allow_encrypted_uploads_only     = false
metaflow_config_bucket_enforce_tls_version              = false
metaflow_old_config_bucket_allow_ssl_requests_only      = false
metaflow_old_config_bucket_allow_encrypted_uploads_only = false
metaflow_old_config_bucket_enforce_tls_version          = false
eks_cluster_name                                        = "partner3-services"
eks_fargate_namespaces = [
  {
    name          = "kube-system"
    iam_role_name = "kube-system-2024090615472947280000000d"
  }
]
cloudwatch_data_protection_findings_bucket_allow_ssl_requests_only      = false
cloudwatch_data_protection_findings_bucket_allow_encrypted_uploads_only = false
cloudwatch_data_protection_findings_bucket_enforce_tls_version          = false
