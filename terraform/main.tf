terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "SageMaker-InfoSec"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

# VPC for SageMaker
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  environment          = var.environment
  enable_vpn_gateway   = var.enable_vpn_gateway
  enable_nat_gateway   = true
  single_nat_gateway   = false
}

# SageMaker Domain with IAM Identity Center
module "sagemaker_domain" {
  source = "./modules/sagemaker"

  domain_name              = var.sagemaker_domain_name
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnet_ids
  security_group_ids       = [module.vpc.sagemaker_security_group_id]
  auth_mode                = "IAM"  # Using IAM with Identity Center integration
  identity_center_instance = var.identity_center_instance_arn
  execution_role_arn       = module.iam.sagemaker_execution_role_arn
  environment              = var.environment

  # Enable notebook features
  enable_jupyter_lab       = true
  enable_kernel_gateway    = true

  # Security settings
  kms_key_id              = module.kms.key_id
  enable_network_isolation = false  # Set to true for stricter isolation

  tags = {
    Team = "SecurityOps"
    Purpose = "ThreatHunting-IncidentResponse"
  }
}

# KMS encryption
module "kms" {
  source = "./modules/kms"

  description = "KMS key for SageMaker InfoSec encryption"
  environment = var.environment

  key_administrators = var.kms_key_administrators
  key_users         = var.kms_key_users
}

# IAM roles and policies
module "iam" {
  source = "./modules/iam"

  environment                  = var.environment
  sagemaker_domain_name        = var.sagemaker_domain_name
  kms_key_arn                  = module.kms.key_arn
  vpc_id                       = module.vpc.vpc_id
  identity_center_instance_arn = var.identity_center_instance_arn

  # Security tool access
  enable_crowdstrike_access    = true
  enable_microsoft_access      = true
  enable_proofpoint_access     = true

  # Secrets Manager for API keys
  secrets_manager_arns = var.secrets_manager_arns
}

# S3 buckets for data and models
module "s3" {
  source = "./modules/s3"

  environment     = var.environment
  kms_key_id      = module.kms.key_id

  # Create buckets for different purposes
  create_data_bucket      = true
  create_models_bucket    = true
  create_notebooks_bucket = true
  create_logs_bucket      = true

  # Enable versioning and logging
  enable_versioning = true
  enable_logging    = true

  # Lifecycle policies
  enable_lifecycle_policies = true
}

# CloudWatch logging
module "cloudwatch" {
  source = "./modules/cloudwatch"

  environment           = var.environment
  sagemaker_domain_name = var.sagemaker_domain_name

  # Log retention
  log_retention_days = var.log_retention_days

  # Alarms for security monitoring
  enable_alarms = true
  alarm_sns_topic_arn = var.alarm_sns_topic_arn
}
