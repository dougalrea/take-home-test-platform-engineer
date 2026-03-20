locals {
  node_policy_attachments = [
    "AmazonEC2ContainerRegistryReadOnly",
    "AmazonEKS_CNI_Policy",
    "AmazonEKSWorkerNodePolicy",
    "AmazonSSMManagedInstanceCore"
  ]
}

resource "aws_iam_role" "this" {
  name               = "karpenter-${var.eks_cluster_name}-nodeclass-${var.nodeclass_name}"
  assume_role_policy = data.aws_iam_policy_document.this.json
}

data "aws_iam_policy_document" "this" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = toset(local.node_policy_attachments)

  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
}

resource "aws_iam_instance_profile" "this" {
  name = aws_iam_role.this.name
  role = aws_iam_role.this.name
}

resource "aws_eks_access_entry" "this" {
  count = var.create_eks_access_entry ? 1 : 0

  cluster_name  = var.eks_cluster_name
  principal_arn = aws_iam_role.this.arn
  type          = "EC2_LINUX"
}

resource "kubectl_manifest" "this" {

  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: ${var.nodeclass_name}
    spec:
      %{if var.enable_instance_store_policy}
      instanceStorePolicy: RAID0
      %{endif}
      role: "${aws_iam_role.this.name}"
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: "${var.eks_cluster_name}"
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: "${var.eks_cluster_name}"
      amiSelectorTerms:
        - alias: ${var.ami_alias}
      detailedMonitoring: ${var.detailed_monitoring}
  YAML
}
