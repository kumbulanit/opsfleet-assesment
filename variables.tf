variable "aws_access_key" {
  description = "AWS Access Key (use only for testing)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "aws_secret_key" {
  description = "AWS Secret Key (use only for testing)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "region" {
  description = "AWS Region (e.g., us-east-1)"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "ID of the existing VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of Subnet IDs in the VPC"
  type        = list(string)
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "pod_cidr_block" {
  description = "CIDR block for Kubernetes pods"
  type        = string
  default     = "192.168.0.0/16"
}

variable "service_cidr_block" {
  description = "CIDR block for Kubernetes services"
  type        = string
  default     = "172.20.0.0/16"
}

variable "cluster_name" {
  description = "Name of the EKS Cluster"
  type        = string
  default     = "my-eks-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version (e.g., 1.26)"
  type        = string
  default     = "1.26"
}

variable "enable_public_access" {
  description = "Enable public access to the EKS cluster"
  type        = bool
  default     = false
}