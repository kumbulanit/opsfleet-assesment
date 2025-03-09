# this is just an example 
region        = "us-east-1"
vpc_id        = "vpc-0a1b2c3d4e5f67890"  # Existing VPC ID
subnet_ids    = [                        # Existing subnet IDs
  "subnet-0123456789abcdef0",
  "subnet-0fedcba9876543210"
]
vpc_cidr      = "10.0.0.0/16"            # Existing VPC CIDR
pod_cidr_block = "192.168.0.0/16"        # Kubernetes pods CIDR
service_cidr_block = "172.20.0.0/16"     # Kubernetes services CIDR
cluster_name  = "prod-eks-cluster"
cluster_version = "1.26"
enable_public_access = false