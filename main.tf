terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Constrain to AWS provider v5.x (compatible with EKS module)
    }
  }

  backend "s3" {
    bucket         = "iftekhar-tf-state-2026"
    key            = "projects/07-eks-cluster/terraform.tfstate"
    region         = "ca-central-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}

provider "aws" {
    region = "ca-central-1"
}

# 2. NETWORK (VPC)
# EKS requires a VPC with very specific tags (for Load Balancers).
# We use a module to build a new VPC specifically for this cluster.

module "vpc" {
    source = "terraform-aws-modules/vpc/aws"
    version = "5.0.0"

    name = "eks-vpc"
    cidr = "10.0.0.0/16"

    azs = ["ca-central-1a", "ca-central-1b"]
    private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
    public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

    enable_nat_gateway = true
    single_nat_gateway = true

    # These tags are required for EKS to work properly.
    public_subnet_tags = { "kubernetes.io/role/elb" = "1" }
    private_subnet_tags = { "kubernetes.io/role/internal-elb" = "1" }

    tags = {
        Terraform = "true"
        Environment = "dev"
    }
}

# 3. EKS CLUSTER
module "eks" {
    source = "terraform-aws-modules/eks/aws"
    version = "20.10.0"

    cluster_name = "my-demo-cluster"
    cluster_version = "1.29"  # Commonly supported Kubernetes version

    # connect it to the vpc we just created
    vpc_id = module.vpc.vpc_id
    subnet_ids = module.vpc.private_subnets
    cluster_endpoint_public_access = true

    #-- THE WORKER NODES 
    eks_managed_node_groups = {
        one = {
            min_size = 1
            max_size = 2
            desired_size = 1

            instance_type = ["t3.small"]
            capacity_type = "ON_DEMAND"
        }
    }

    # enable the necessary addons
    enable_cluster_creator_admin_permissions = true

    # configure the cluster
}
