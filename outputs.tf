output "cluster_endpoint" {
  description = "EKS Cluster Endpoint"
  value       = module.eks.cluster_endpoint
}

output "kubeconfig" {
  description = "Kubernetes configuration for the cluster"
  value       = module.eks.kube_config_raw
}

output "karpenter_node_pools" {
  description = "Names of Karpenter node pools"
  value       = [for p in module.karpenter.provisioner_config : p.name]
}