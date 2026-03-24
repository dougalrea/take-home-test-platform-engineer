resource "kubernetes_namespace" "aws_observability" {
  count = var.account_decommissioned ? 0 : 1
  # Required for housing Fargate logging ConfigMaps.
  # https://docs.aws.amazon.com/eks/latest/userguide/fargate-logging.html
  # We cannot create a namespace in Helm with the appropriate labels:
  # https://github.com/helm/helm/issues/3503#issuecomment-696712443

  metadata {
    annotations = {
      name = "aws-observability"
    }

    labels = {
      aws-observability = "enabled"
      Managed           = "terraform"
    }

    name = "aws-observability"
  }
}

resource "aws_iam_policy" "eks_fargate_logging_iam_role" {
  count = var.account_decommissioned ? 0 : 1

  name        = "eks-fargate-logging-policy"
  description = "IAM policy for EKS Fargate pods writing to CloudWatch"

  # https://raw.githubusercontent.com/aws-samples/amazon-eks-fluent-logging-examples/mainline/examples/fargate/cloudwatchlogs/permissions.json
  policy = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:CreateLogGroup",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents",
        "logs:PutRetentionPolicy"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "eks_fargate_logging" {
  count = var.account_decommissioned ? 0 : 1

  # should this be the fargate_profile_pod_execution_role_arn?
  role       = module.eks.fargate_profiles["kube_system"].iam_role_name
  policy_arn = aws_iam_policy.eks_fargate_logging_iam_role[0].arn
}

resource "terraform_data" "cloudwatch_log_group_names" {
  for_each = toset(var.cloudwatch_log_group_names)

  input = each.key
}

resource "kubectl_manifest" "aws_logging_configmap" {
  count = var.account_decommissioned ? 0 : 1
  yaml_body = <<-YAML
    ---
      # Default configMap for aws-logging
      # https://docs.aws.amazon.com/eks/latest/userguide/fargate-logging.html
      kind: ConfigMap
      apiVersion: v1
      metadata:
        name: aws-logging
        namespace: ${kubernetes_namespace.aws_observability.id}
      data:
        flb_log_cw: "false"  # Set to true to ship Fluent Bit process logs to CloudWatch.
        filters.conf: |
          [FILTER]
              Name parser
              Match *
              Key_name log
              Parser crio
          [FILTER]
              Name kubernetes
              Match kube.*
              Merge_Log On
              Keep_Log Off
              Buffer_Size 0
              Kube_Meta_Cache_TTL 300s
        output.conf: |
          [OUTPUT]
              Name cloudwatch_logs
              Match   kube.*
              region eu-west-1
              log_group_name /aws/eks/${module.eks.cluster_name}/fargate
              log_group_template /aws/eks/${module.eks.cluster_name}/workload/$kubernetes['namespace_name']
              log_stream_prefix fluentbit-
              log_stream_template $kubernetes['pod_name'].$kubernetes['container_name']
              log_retention_days 60
              auto_create_group true
        parsers.conf: |
          [PARSER]
              Name crio
              Format Regex
              Regex ^(?<time>[^ ]+) (?<stream>stdout|stderr) (?<logtag>P|F) (?<log>.*)$
              Time_Key    time
              Time_Format %Y-%m-%dT%H:%M:%S.%L%z
  YAML

  depends_on = [
    module.eks,
    terraform_data.cloudwatch_log_group_names # Ensure we have the EKS CloudWatch log groups created before Fargate starts logging
  ]
}

data "aws_iam_policy_document" "cloudwatch_observability_iam_role" {
  count = var.eks_addon_observability_enabled ? 1 : 0

  statement {
    sid    = "CWACloudWatchServerPermissions"
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData",
      "ec2:DescribeVolumes",
      "ec2:DescribeTags",
      "logs:PutLogEvents",
      "logs:PutRetentionPolicy",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
      "xray:GetSamplingStatisticSummaries"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "cloudwatch_observability_trust" {
  count = var.eks_addon_observability_enabled ? 1 : 0

  version = "2012-10-17"

  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    principals {
      type = "Federated"
      identifiers = [
        module.eks.oidc_provider_arn
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:amazon-cloudwatch:cloudwatch-agent",
        "system:serviceaccount:amazon-cloudwatch:amazon-cloudwatch-observability-controller-manager"
      ]
    }
  }
}

resource "aws_iam_policy" "cloudwatch_observability_iam_role" {
  count = var.eks_addon_observability_enabled ? 1 : 0

  name        = "AmazonCloudwatchObservabilityPolicy"
  description = "Allows CloudWatch Observability to collect metrics and logs"
  policy      = data.aws_iam_policy_document.cloudwatch_observability_iam_role[0].json
}

resource "aws_iam_role" "cloudwatch_observability" {
  count = var.eks_addon_observability_enabled ? 1 : 0

  name               = "AmazonCloudwatchObservability"
  description        = "Role used by the cloudwatch-observability add-on"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_observability_trust[0].json
}

resource "aws_iam_role_policy_attachment" "cloudwatch_observability" {
  count = var.eks_addon_observability_enabled ? 1 : 0

  role       = aws_iam_role.cloudwatch_observability[0].name
  policy_arn = aws_iam_policy.cloudwatch_observability_iam_role[0].arn
}
