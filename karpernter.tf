module "karpenter" {
  source = "aws/karpenter/aws"
  version = "4.0.0"

  cluster_name = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data
  service_account_role_arn = module.eks.oidc_provider_arn

  # Configure x86 and ARM64 node pools
  provisioner_config = [
    {
      name = "x86-spot"
      requirements = [
        { key = "kubernetes.io/arch", operator = "In", values = ["amd64"] },
        { key = "capacityType", operator = "In", values = ["spot"] }
      ]
      limits = {
        cpu    = "32"
        memory = "64Gi"
      }
    },
    {
      name = "arm64-spot"
      requirements = [
        { key = "kubernetes.io/arch", operator = "In", values = ["arm64"] },
        { key = "capacityType", operator = "In", values = ["spot"] }
      ]
      limits = {
        cpu    = "32"
        memory = "64Gi"
      }
    }
  ]

  # Graviton instances (ARM64)
  default_instance_types = ["m6g.large", "m6g.xlarge", "c6g.2xlarge"]

  # IAM for Karpenter
  irsa_create_role = true
  irsa_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  ]
}