# AWS EKS Cluster (Terraform + Kubernetes)

## 📖 Project Overview

This project provisions a managed **Kubernetes (EKS)** cluster on AWS using Terraform. It demonstrates the ability to orchestrate complex container workloads in a cloud-native environment.

The cluster allows for the deployment of microservices (like the FastAPI app from Project 6), exposing them via AWS Load Balancers, and scaling them across multiple worker nodes.
![Architecture Diagram](architecture-diagram.png)

## 🏗 Architecture

* **VPC Module:** A custom VPC created specifically for EKS, with public/private subnets and NAT Gateways.
* **EKS Control Plane:** Managed Kubernetes master nodes (Serverless).
* **Worker Nodes:** EC2 instances (t3.small) managed by an Auto Scaling Group that run the actual application pods.
* **Security:** IAM Roles for Service Accounts (IRSA) and strict Security Group rules.

## ⚙️ Technical Highlights

* **Modular Terraform:** Utilizes the official `terraform-aws-modules` for VPC and EKS to implement industry best practices (Tagging, Subnet layout).
* **Remote State:** State is stored in S3 (Project 1) with DynamoDB locking.
* **Load Balancer Integration:** The cluster is configured to automatically provision AWS CLB/NLB when a Kubernetes `Service` of type `LoadBalancer` is created.

## 💻 Usage

### 1. Provision Cluster

```bash
terraform init
terraform apply

```

### 2. Connect `kubectl`

```bash
aws eks update-kubeconfig --region ca-central-1 --name my-demo-cluster

```

### 3. Deploy Application

```bash
# Deploy the container from ECR (Project 7)
kubectl create deployment my-app --image=[YOUR_ECR_URL]:v1

# Expose to Internet
kubectl expose deployment my-app --type=LoadBalancer --port=80 --target-port=8000

```

## 🐛 Troubleshooting / Common Issues

### Q: Error: "Blocks of type 'elastic_gpu_specifications' are not expected here"

**A:** This error occurs due to version incompatibility between the AWS provider and the EKS module.

**Solution:**
- The EKS module v20.0.0 is designed for AWS provider v5.x
- AWS provider v6.x removed support for `elastic_gpu_specifications` and `elastic_inference_accelerator` blocks
- Add provider version constraint in `main.tf`:
  ```hcl
  terraform {
    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = "~> 5.0"  # Constrain to AWS provider v5.x
      }
    }
  }
  ```
- Run `terraform init -upgrade` to download the compatible provider version

---

### Q: Error: "InvalidParameterException: unsupported Kubernetes version 1.31" (or similar)

**A:** The specified Kubernetes version doesn't exist or isn't supported in your region.

**Solution:**
- Kubernetes version 1.31 doesn't exist (as of 2025, latest stable versions are around 1.28-1.30)
- Use a valid Kubernetes version (e.g., 1.29)
- Update `cluster_version` in your EKS module configuration:
  ```hcl
  cluster_version = "1.29"  # Valid, widely supported version
  ```

---

### Q: Error: "Requested AMI for this version 1.28 is not supported" / "InvalidParameterException: Requested AMI for this version X is not supported"

**A:** AWS doesn't have AMIs (Amazon Machine Images) available for the specified Kubernetes version in your region.

**Solution:**
- Not all Kubernetes versions have AMIs available in all AWS regions immediately
- Try a more commonly supported version like 1.29
- If the cluster was already created with an unsupported version:
  1. Delete the cluster: `terraform destroy`
  2. Update `cluster_version` to a supported version (e.g., 1.29)
  3. Recreate: `terraform apply`
- **Note:** Kubernetes doesn't support downgrades, so you must delete and recreate

---

### Q: Error: "Error acquiring the state lock" - DynamoDB table not found

**A:** The DynamoDB table for Terraform state locking doesn't exist.

**Solution:**
- Create the DynamoDB table manually:
  ```bash
  aws dynamodb create-table \
    --table-name terraform-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region ca-central-1
  ```
- Wait for the table to become ACTIVE: `aws dynamodb wait table-exists --table-name terraform-lock --region ca-central-1`

---

### Q: Warning: "inline_policy is deprecated" when running terraform apply

**A:** This is a deprecation warning from the EKS module, not an error.

**Solution:**
- This warning doesn't prevent the cluster from working
- It's an internal issue in the EKS module that will be fixed in future versions
- You can safely ignore this warning - it doesn't affect functionality

---

### Q: Pod status shows "ErrImagePull" / "ImagePullBackOff"

**A:** Kubernetes cannot pull the container image from ECR.

**Common Causes & Solutions:**
1. **Image doesn't exist or wrong tag:**
   - Check if the image exists: `aws ecr list-images --repository-name my-fastapi-app --region ca-central-1`
   - Ensure you're using the correct image tag (e.g., `:v1` instead of `:latest`)

2. **Missing ECR authentication:**
   - ECR requires authentication. Configure imagePullSecrets or use IAM Roles for Service Accounts (IRSA)
   - Authenticate kubectl with ECR: `aws ecr get-login-password --region ca-central-1 | docker login --username AWS --password-stdin 225989342003.dkr.ecr.ca-central-1.amazonaws.com`

3. **Node group IAM permissions:**
   - Ensure your node group IAM role has `AmazonEC2ContainerRegistryReadOnly` policy attached

## 🧠 Key Concepts Learned

* **EKS Management:** Provisioning Control Planes and Node Groups.
* **Kubernetes Networking:** Services, Deployments, and Load Balancers.
* **Infrastructure Modules:** Reusing community-standard modules for complex resources.
* **Version Compatibility:** Importance of matching Terraform provider versions with module requirements.
* **Regional Availability:** Not all Kubernetes versions are immediately available in all AWS regions.

