module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.27.0"

  cluster_name    = var.cluster_name
  vpc_id          = var.vpc_id
  subnet_ids      = var.subnet_ids
  cluster_version = var.cluster_version

  manage_aws_auth = true
  enable_irsa     = true

  vpc_cidr               = var.vpc_cidr
  pod_cidr_block         = var.pod_cidr_block
  service_cidr_block     = var.service_cidr_block
  enable_public_access   = var.enable_public_access

  worker_group_defaults = {
    instance_type = "t3.medium"  # Default control plane instance type
  }

  # IAM for EKS
  create_iam_role_for_service_accounts = true
}