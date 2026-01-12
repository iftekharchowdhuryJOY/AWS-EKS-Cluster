# AWS EKS Cluster (Terraform + Kubernetes)

## 📖 Project Overview

This project provisions a managed **Kubernetes (EKS)** cluster on AWS using Terraform. It demonstrates the ability to orchestrate complex container workloads in a cloud-native environment.

The cluster allows for the deployment of microservices (like the FastAPI app from Project 6), exposing them via AWS Load Balancers, and scaling them across multiple worker nodes.

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

## 🧠 Key Concepts Learned

* **EKS Management:** Provisioning Control Planes and Node Groups.
* **Kubernetes Networking:** Services, Deployments, and Load Balancers.
* **Infrastructure Modules:** Reusing community-standard modules for complex resources.

