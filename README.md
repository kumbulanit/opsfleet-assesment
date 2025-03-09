# opsfleet-assesment

# 🚀 EKS Cluster Deployment & Workload Guide

---

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Deploy the Cluster](#deploy-the-cluster)
3. [Deploy Workloads](#deploy-workloads)
4. [Expose Services Publicly](#expose-services-publicly)
5. [Cleanup](#cleanup)
6. [Important Notes](#important-notes)

---

## Prerequisites
1. **Terraform** (`>=1.3.0`):  
   ```bash
   terraform -install
   ```
2. **kubectl**:  
   ```bash
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   chmod +x kubectl && sudo mv kubectl /usr/local/bin/
   ```
3. **AWS CLI**:  
   ```bash
   aws configure
   ```
4. **Existing AWS Resources**:  
   - VPC ID (e.g., `vpc-0a1b2c3d4e5f67890`).  
   - Subnet IDs (e.g., `["subnet-0123...", "subnet-0456..."]`).

---

## Deploy the Cluster

### Step 1: Configure Variables
1. Copy the example variables file:  
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
2. Edit `terraform.tfvars` with your values (including AWS credentials for testing):  
   ```hcl
   # terraform.tfvars (DO NOT COMMIT TO REPO)
   aws_access_key = "YOUR_AWS_ACCESS_KEY"  # Replace with your key (only for testing)
   aws_secret_key = "YOUR_AWS_SECRET_KEY"  # Replace with your secret (only for testing)
   region        = "us-east-1"
   vpc_id        = "vpc-0a1b2c3d4e5f67890"
   subnet_ids    = ["subnet-0123...", "subnet-0456..."]
   cluster_name  = "my-eks-cluster"
   enable_public_access = false
   ```

---

### Step 2: Deploy the Cluster
```bash
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

**Output**:  
- `cluster_endpoint`: EKS cluster endpoint.  
- `kubeconfig`: Kubernetes configuration file (exported automatically).

---

### Step 3: Access the Cluster
```bash
export KUBECONFIG=$(terraform output -raw kubeconfig)
kubectl cluster-info
```

---

## Deploy Workloads

### Deploy to x86 Instances
1. Create a YAML file (e.g., `x86-pod.yaml`):  
   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: x86-pod
   spec:
     affinity:
       nodeAffinity:
         requiredDuringSchedulingIgnoredDuringExecution:
           nodeSelectorTerms:
             - matchExpressions:
                 - key: "kubernetes.io/arch"
                   operator: In
                   values:
                     - "amd64"
     containers:
       - name: my-container
         image: nginx
   ```
2. Deploy:  
   ```bash
   kubectl apply -f x86-pod.yaml
   ```

### Deploy to ARM64 (Graviton) Instances
1. Create a YAML file (e.g., `arm64-pod.yaml`):  
   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: arm64-pod
   spec:
     affinity:
       nodeAffinity:
         requiredDuringSchedulingIgnoredDuringExecution:
           nodeSelectorTerms:
             - matchExpressions:
                 - key: "kubernetes.io/arch"
                   operator: In
                   values:
                     - "arm64"
     containers:
       - name: my-container
         image: arm64/nginx  # Use ARM64-compatible image
   ```
2. Deploy:  
   ```bash
   kubectl apply -f arm64-pod.yaml
   ```

---

## Expose Services Publicly
To make an app accessible externally, create a `LoadBalancer` service:  
1. Create `service.yaml`:  
   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: my-service
   spec:
     type: LoadBalancer
     selector:
       app: my-app  # Match your pod/Deployment labels
     ports:
       - protocol: TCP
         port: 80
         targetPort: 80
   ```
2. Deploy:  
   ```bash
   kubectl apply -f service.yaml
   ```
3. Get the public IP:  
   ```bash
   kubectl get services my-service
   ```

---

## Cleanup
```bash
terraform destroy -var-file="terraform.tfvars"
```

---

## Important Notes
### 1. **Security**  
- **Avoid hardcoding credentials**:  
  - Use **environment variables** instead of `aws_access_key`/`aws_secret_key` in `terraform.tfvars`:  
    ```bash
    export AWS_ACCESS_KEY_ID="YOUR_KEY"
    export AWS_SECRET_ACCESS_KEY="YOUR_SECRET"
    ```
  - For production, use **AWS profiles** configured via `~/.aws/credentials`.

### 2. **Spot Instances**  
- Pods on Spot Instances may be interrupted by AWS. Karpenter automatically replaces them, so use this for fault-tolerant workloads (e.g., batch jobs).

### 3. **Graviton (ARM64) Support**  
- Ensure your container images are **ARM64-compatible** (e.g., `arm64/nginx`).

### 4. **Node Pool Limits**  
- The default node pools have CPU/memory limits. Adjust them in `karpenter.tf` for larger workloads.

---

### Why Spot and Graviton?
- **Cost Savings**:  
  - **Spot Instances**: Up to 90% cheaper than On-Demand instances.  
  - **Graviton**: Better price/performance for compute-heavy tasks (e.g., machine learning).
- **Auto-scaling**: Karpenter provisions nodes dynamically based on workload demands.

---

### Troubleshooting
- **Spot Interruptions**: Monitor node replacements with:  
  ```bash
  kubectl get nodes -w
  ```
- **IAM Permissions**: Ensure the AWS user/role has `AmazonEKSClusterPolicy`, `AmazonEC2FullAccess`, and `AmazonS3FullAccess` (if using remote state).


## Important Notes
### 1. **Security**  
- **Avoid hardcoding credentials**: Use AWS profiles or environment variables instead of `aws_access_key`/`aws_secret_key` in `terraform.tfvars`.
- **IAM Permissions**: Ensure the AWS user/role has `AmazonEKSClusterPolicy`, `AmazonEC2FullAccess`, and `AmazonS3FullAccess` (if using remote state).

### 2. **Spot Instances**  
- Pods on Spot Instances may be interrupted by AWS. Karpenter automatically replaces them, so use this for fault-tolerant workloads (e.g., batch jobs).

### 3. **Graviton (ARM64) Support**  
- Ensure your container images are **ARM64-compatible** (e.g., `arm64/nginx`).

### 4. **Node Pool Limits**  
- The default node pools have CPU/memory limits. Adjust them in `karpenter.tf` for larger workloads.

---
