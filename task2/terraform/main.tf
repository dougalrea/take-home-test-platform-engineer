locals {
  provider_default_tags = {
    configuration = "infrastructure"
    environment   = var.environment
    managed       = "terraform"
  }

  aws_region_name_split = split("-", data.aws_region.current.name)
  aws_region_name_short = "${local.aws_region_name_split[0]}${substr(local.aws_region_name_split[1], 0, 1)}${local.aws_region_name_split[2]}"

  metaflow_ui_hostname = "metaflow.${var.domain_name}"
  argo_domain_name     = "argo.${var.domain_name}"

  natcap_infratask2_service_domain_name    = "*.${var.domain_name}"
  natcap_infratask2_service_qa_domain_name = "*.qa.${var.domain_name}"

  customer_service_domain_names    = [for name in var.customer_name_prefixes : "*.${name}.${var.domain_name}"]
  customer_service_qa_domain_names = [for name in var.customer_name_prefixes : "*.qa.${name}.${var.domain_name}"]

  certificate_domains = (var.create_wildcard_certificates
    ? concat(
      [local.natcap_infratask2_service_domain_name],
      [local.natcap_infratask2_service_qa_domain_name],
      local.customer_service_domain_names,
      local.customer_service_qa_domain_names,
      [local.metaflow_ui_hostname],
      [local.argo_domain_name]
    )
    : concat(
      [local.metaflow_ui_hostname],
      [local.argo_domain_name]
    )
  )

  account_decommissioned = var.account_state == "decommissioned" || var.account_state == "pre-commissioned" ? true : false

  kubernetes_provider_config = {
    host                   = module.eks_cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority_data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks_cluster.cluster_name
      ]
      command = "aws"
    }
  }

  infrastructure_admin_sso_role_arns = [for arn in data.aws_iam_roles.infrastructure_admin_sso_role.arns : arn]

  # **Auth0 credentials**
  # We only need the auth0 provider in the `main` accounts.
  # Conditional providers are not supported in Terraform and the auth0 provider _requires_ the credentials to be set.
  # So we instead use conditional variables to determine the credential values.
  # If you are not in the `main` account, we set 'dummy' values for the credentials.
  # For non-`main` accounts, these are never used, so we can set them to any non-empty string.
  auth0_credentials = var.enable_auth0 ? jsondecode(data.aws_secretsmanager_secret_version.auth0_credentials[0].secret_string) : {}

  auth0_client_id     = var.enable_auth0 ? local.auth0_credentials.client_id : "client_id"
  auth0_client_secret = var.enable_auth0 ? local.auth0_credentials.client_secret : "client_secret"
  auth0_domain        = var.enable_auth0 ? local.auth0_credentials.domain : "domain"

  # Staging credentials are only used in the prod.main account for the Dashboard running in the QA namespace (dashboard.qa.infraTask2natcap.com)
  # This will be removed once staging AWS Accounts are created.
  auth0_credentials_staging = var.enable_auth0_staging ? jsondecode(data.aws_secretsmanager_secret_version.auth0_staging_credentials[0].secret_string) : {}

  auth0_client_id_staging     = var.enable_auth0_staging ? local.auth0_credentials_staging.client_id : "client_id"
  auth0_client_secret_staging = var.enable_auth0_staging ? local.auth0_credentials_staging.client_secret : "client_secret"
  auth0_domain_staging        = var.enable_auth0_staging ? local.auth0_credentials_staging.domain : "domain"
}

terraform {
  # requires .tfbackend config to be specified
  backend "s3" {}
}

provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = local.provider_default_tags
  }
}

provider "aws" {
  region = "eu-west-1"
  alias  = "main-route53"

  assume_role {
    role_arn    = "arn:aws:iam::${var.account_type == "partner" ? var.main_aws_account_id : data.aws_caller_identity.current.account_id}:role/terraform-route53"
    external_id = "terraform-route53"
  }

  default_tags {
    tags = local.provider_default_tags
  }
}

data "aws_region" "current" {}

data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_role" "eks_cluster_admin" {
  name = var.eks_cluster_admin_iam_role_name
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_iam_roles" "metaflow_sso_role" {
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
  name_regex  = "AWSReservedSSO_InfraTask2MetaflowUser.+"
}

data "aws_iam_roles" "engineering_admin_sso_role" {
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
  name_regex  = "AWSReservedSSO_InfraTask2EngineeringAdminAccess.+"
}

data "aws_iam_roles" "infrastructure_admin_sso_role" {
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
  name_regex  = "AWSReservedSSO_InfraTask2InfrastructureAdminAccess.+"
}

data "aws_iam_roles" "macie_service_linked_role" {
  name_regex  = "AWSServiceRoleForAmazonMacie"
  path_prefix = "/aws-service-role/macie.amazonaws.com/"
}

provider "kubernetes" {
  host                   = local.kubernetes_provider_config.host
  cluster_ca_certificate = local.kubernetes_provider_config.cluster_ca_certificate
  exec {
    api_version = local.kubernetes_provider_config.exec.api_version
    args        = local.kubernetes_provider_config.exec.args
    command     = local.kubernetes_provider_config.exec.command
  }
}

provider "kubectl" {
  host                   = local.kubernetes_provider_config.host
  cluster_ca_certificate = local.kubernetes_provider_config.cluster_ca_certificate
  apply_retry_count      = 5
  load_config_file       = false

  exec {
    api_version = local.kubernetes_provider_config.exec.api_version
    args        = local.kubernetes_provider_config.exec.args
    command     = local.kubernetes_provider_config.exec.command
  }
}

provider "helm" {
  # https://github.com/terraform-aws-modules/terraform-aws-eks/issues/2009#issuecomment-1096604789
  kubernetes {
    host                   = local.kubernetes_provider_config.host
    cluster_ca_certificate = local.kubernetes_provider_config.cluster_ca_certificate
    exec {
      api_version = local.kubernetes_provider_config.exec.api_version
      args        = local.kubernetes_provider_config.exec.args
      command     = local.kubernetes_provider_config.exec.command
    }
  }
}

provider "google-beta" {
  user_project_override = true
}

data "google_organization" "this" {
  domain = "infraTask2natcap.com"
}

# Auth method: Application Default Credentials (ADC) and specific administrator roles
# https://library.tf/providers/hashicorp/googleworkspace/latest#using-specific-administrator-roles
provider "googleworkspace" {
  customer_id = data.google_organization.this.directory_customer_id
  oauth_scopes = [
    # include scopes as needed
    "https://www.googleapis.com/auth/apps.groups.settings"
  ]
}

data "terraform_remote_state" "main" {
  count = var.account_type == "partner" ? 1 : 0

  backend = "s3"
  config = var.main_aws_account_state_config != null ? var.main_aws_account_state_config : {
    bucket = "ncr-infratask2-tfstate-${var.main_aws_account_id}"
    key    = "infrastructure.tfstate"
    region = "eu-west-1"
  }
}

data "terraform_remote_state" "logs" {
  backend = "s3"

  config = {
    # for now we are allowing GetObject with PrincipalOrgPaths, but this will move bucket eventually
    bucket = "ncr-infratask2-infrastructure"
    key    = "terraform/security.logs.tfstate"
    region = "eu-west-2"
  }
}

data "aws_secretsmanager_secret_version" "auth0_credentials" {
  count = var.enable_auth0 ? 1 : 0

  secret_id = var.auth0_secret_id
}

data "aws_secretsmanager_secret_version" "auth0_staging_credentials" {
  count = var.enable_auth0_staging ? 1 : 0

  secret_id = "auth0/staging"
}

provider "auth0" {
  client_id     = local.auth0_client_id
  client_secret = local.auth0_client_secret
  domain        = local.auth0_domain
}

provider "auth0" {
  client_id     = local.auth0_client_id_staging
  client_secret = local.auth0_client_secret_staging
  domain        = local.auth0_domain_staging

  alias = "infratask2-staging"
}
