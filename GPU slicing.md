


#### **1. What is GPU Slicing (NVIDIA MIG)?**  
**GPU Slicing** (via NVIDIA's **Multi-Instance GPU**, or **MIG**) partitions a single GPU into smaller, logical slices. Each slice acts as an independent GPU, enabling concurrent workloads to run on the same physical GPU. For example, an NVIDIA A100 GPU can be divided into **up to 7 slices** (e.g., `mig-1g.5gb` for 1 GPU engine and 5GB memory). This allows efficient resource sharing and cost optimization for GPU-intensive workloads.  

---

#### **2. Advantages of GPU Slicing for AI Workloads**  
- **Cost Efficiency**:  
  - Run multiple jobs on a single GPU, reducing hardware costs by **30–50%**.  
  - Ideal for **inference**, small training tasks, or hyperparameter tuning.  
- **Higher Utilization**:  
  - Leverage idle GPU capacity for additional workloads.  
- **Flexibility**:  
  - Concurrently run training, inference, and other tasks on the same GPU.  
- **Faster Turnaround**:  
  - Smaller jobs start immediately without waiting for full GPU availability.  
- **Scalability with Karpenter**:  
  - Automatically provision nodes with the right MIG profiles.  

---

#### **3. Disadvantages of GPU Slicing**  
- **Performance Overhead**:  
  - Slices may have **lower throughput** due to shared resources (e.g., memory bandwidth).  
  - Full GPU horsepower is best for large-scale training.  
- **Setup Complexity**:  
  - Requires configuring MIG partitions and Kubernetes resources.  
- **Workload Compatibility**:  
  - Not all AI frameworks natively support MIG (e.g., test frameworks like PyTorch/TensorFlow).  
- **Limited GPU Models**:  
  - Supported only on NVIDIA A100, H100, and H800 GPUs (AWS instances like `p4d.24xlarge`).  

---

#### **4. Implementation Steps for EKS Clusters**  

---

##### **4.1 Prerequisites**  
- **EC2 Instances**: Use NVIDIA A100/H100 instances (e.g., `p4d.24xlarge`, `trn1n.32xlarge`).  
- **NVIDIA Drivers**: Ensure drivers ≥ `525.60.11` (for A100).  
- **NVIDIA Device Plugin**: Installed in EKS (version ≥ v1.14.1).  

---

##### **4.2 Enable MIG on EC2 Instances**  
Configure MIG partitions **before** nodes join the cluster.  

**Option A: Configure at Launch (via User Data)**  
Add the following script to EC2 user data:  
```bash
#!/bin/bash
# Install NVIDIA drivers
sudo apt-get update && sudo apt-get install -y nvidia-driver-525
sudo reboot

# Enable MIG partitions (e.g., 3 slices of mig-1g.5gb)
sudo nvidia-smi mig -cgi 3
sudo nvidia-smi mig -g 0 -i 3
```

**Option B: Enable on Existing Instances**  
SSH into the instance and run the commands above manually.  

**Verify MIG Configuration**:  
```bash
sudo nvidia-smi mig -li
```

---

##### **4.3 Configure NVIDIA Device Plugin**  
Update the NVIDIA device plugin to enable MIG support:  
```yaml
# Modify the DaemonSet YAML for the NVIDIA device plugin
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: nvidia-device-plugin-ds
  namespace: kube-system
spec:
  template:
    spec:
      containers:
        - name: nvidia-device-plugin
          args:
            - --verbose
            - --enable-mig  # Enable MIG support
          image: <nvidia-device-plugin-image>
```

---

##### **4.4 Update Pod Specifications**  
Request MIG slices in your workload manifests:  
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ai-workload
spec:
  containers:
    - name: ai-container
      image: your-ai-image
      resources:
        limits:
          nvidia.com/gpu: "1"       # Total slices
          nvidia.com/mig-1g.5gb: "1"  # Specify the MIG profile
```

---

##### **4.5 Validate Configuration**  
Check node labels and resources:  
```bash
kubectl describe node <node-name> | grep "nvidia.com/mig"
kubectl get nodes --selector=nvidia.com/mig.profile=mig-1g.5gb
```

---

#### **5. GPU Slicing with Karpenter Autoscaler**  



##### **5.1 Define Karpenter Node Templates**  
Create templates specifying MIG-capable instances and profiles:  
```yaml
apiVersion: "node.k8s.io/v1beta1"
kind: NodeTemplate
metadata:
  name: migslice-template
spec:
  provider:
    ec2:
      amiFamily: al2
      instanceType: p4d.24xlarge
      subnetSelector:
        subnet_utilization: karpenter
  requirements:
    - operator: In
      key: nvidia.com/mig.profile
      values: ["mig-1g.5gb"]
  labels:
    nvidia.com/mig.profile: "mig-1g.5gb"  # Label nodes with MIG profile
```

---

##### **5.2 Configure Karpenter for MIG**  
- **Custom AMI or Launch Template**:  
  Use instances pre-configured with MIG (via the user data script above).  
- **Pod Requirements**:  
  Ensure pods explicitly request MIG profiles (e.g., `nvidia.com/mig-1g.5gb`).  

---

##### **5.3 Deploy Workloads**  
Karpenter will auto-provision nodes matching the requested MIG profile. Example:  
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ai-workload
spec:
  containers:
    - name: ai-container
      resources:
        limits:
          nvidia.com/mig-1g.5gb: "1"
```

---

#### **6. Best Practices & Considerations**  
- **Workload Compatibility**:  
  - Test frameworks (e.g., PyTorch, TensorFlow) for MIG compatibility.  
- **Slice Configuration**:  
  - Balance cost and performance (e.g., **2–4 slices per GPU** is optimal for most workloads).  
- **Avoid Oversubscription**:  
  - Ensure memory and compute resources are sufficient for concurrent tasks.  
- **Monitoring**:  
  - Use **AWS CloudWatch** or **Karpenter dashboards** to track utilization and costs.  
- **Performance Testing**:  
  - Measure latency/throughput post-implementation to validate results.  

---

#### **7. Example Workflow**  
1. **Launch MIG-enabled instances** with Karpenter templates.  
2. **Deploy AI workloads** requesting `nvidia.com/mig-1g.5gb` slices.  
3. **Scale automatically**: Karpenter provisions nodes as demand increases.  

---

#### **8. Summary**  
GPU slicing on EKS reduces costs by **30–50%** while improving GPU utilization for AI workloads. When paired with **Karpenter**, it enables dynamic scaling of MIG slices, ensuring efficient resource allocation. Start with a pilot workload to validate performance and gradually roll out to production. Always prioritize testing and monitoring to balance cost savings with workload requirements.