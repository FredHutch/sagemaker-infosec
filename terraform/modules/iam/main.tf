# SageMaker Execution Role
resource "aws_iam_role" "sagemaker_execution" {
  name = "SageMakerExecutionRole-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "SageMaker Execution Role"
  }
}

# Attach AWS managed policy for SageMaker
resource "aws_iam_role_policy_attachment" "sagemaker_full_access" {
  role       = aws_iam_role.sagemaker_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

# Custom policy for security operations
resource "aws_iam_policy" "security_operations" {
  name        = "SageMakerSecurityOperations-${var.environment}"
  description = "Policy for security team operations in SageMaker"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # S3 access for security data
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.environment}-sagemaker-infosec-*",
          "arn:aws:s3:::${var.environment}-sagemaker-infosec-*/*"
        ]
      },
      # CloudWatch Logs
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:log-group:/aws/sagemaker/*"
      },
      # KMS for encryption
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = var.kms_key_arn
      },
      # Secrets Manager for API credentials
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.secrets_manager_arns
      },
      # EC2 for VPC operations
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups"
        ]
        Resource = "*"
      },
      # ECR for custom containers
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      # STS for assuming roles
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = "arn:aws:iam::*:role/SageMaker*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "security_operations" {
  role       = aws_iam_role.sagemaker_execution.name
  policy_arn = aws_iam_policy.security_operations.arn
}

# Policy for CrowdStrike integration
resource "aws_iam_policy" "crowdstrike_access" {
  count = var.enable_crowdstrike_access ? 1 : 0

  name        = "SageMakerCrowdStrikeAccess-${var.environment}"
  description = "Policy for accessing CrowdStrike APIs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:*:*:secret:crowdstrike/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "crowdstrike_access" {
  count = var.enable_crowdstrike_access ? 1 : 0

  role       = aws_iam_role.sagemaker_execution.name
  policy_arn = aws_iam_policy.crowdstrike_access[0].arn
}

# Policy for Microsoft security tools integration
resource "aws_iam_policy" "microsoft_access" {
  count = var.enable_microsoft_access ? 1 : 0

  name        = "SageMakerMicrosoftAccess-${var.environment}"
  description = "Policy for accessing Microsoft security APIs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:*:*:secret:microsoft/*",
          "arn:aws:secretsmanager:*:*:secret:entra/*",
          "arn:aws:secretsmanager:*:*:secret:defender/*",
          "arn:aws:secretsmanager:*:*:secret:purview/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "microsoft_access" {
  count = var.enable_microsoft_access ? 1 : 0

  role       = aws_iam_role.sagemaker_execution.name
  policy_arn = aws_iam_policy.microsoft_access[0].arn
}

# Policy for Proofpoint integration
resource "aws_iam_policy" "proofpoint_access" {
  count = var.enable_proofpoint_access ? 1 : 0

  name        = "SageMakerProofpointAccess-${var.environment}"
  description = "Policy for accessing Proofpoint APIs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:*:*:secret:proofpoint/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "proofpoint_access" {
  count = var.enable_proofpoint_access ? 1 : 0

  role       = aws_iam_role.sagemaker_execution.name
  policy_arn = aws_iam_policy.proofpoint_access[0].arn
}

# Role for Identity Center users (if using SSO)
resource "aws_iam_role" "identity_center_sagemaker" {
  count = var.identity_center_instance_arn != "" ? 1 : 0

  name = "IdentityCenterSageMakerRole-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:saml-provider/AWSSSO"
        }
        Action = "sts:AssumeRoleWithSAML"
        Condition = {
          StringEquals = {
            "SAML:aud" = "https://signin.aws.amazon.com/saml"
          }
        }
      }
    ]
  })
}

# Permission set for security analysts
resource "aws_iam_policy" "security_analyst" {
  name        = "SageMakerSecurityAnalyst-${var.environment}"
  description = "Policy for security analysts using SageMaker"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sagemaker:CreatePresignedDomainUrl",
          "sagemaker:DescribeDomain",
          "sagemaker:ListDomains",
          "sagemaker:DescribeUserProfile",
          "sagemaker:ListUserProfiles",
          "sagemaker:DescribeSpace",
          "sagemaker:ListSpaces",
          "sagemaker:CreateApp",
          "sagemaker:DeleteApp",
          "sagemaker:DescribeApp",
          "sagemaker:ListApps"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sagemaker:CreateNotebookInstance",
          "sagemaker:StartNotebookInstance",
          "sagemaker:StopNotebookInstance",
          "sagemaker:DescribeNotebookInstance"
        ]
        Resource = "arn:aws:sagemaker:*:*:notebook-instance/*"
        Condition = {
          StringEquals = {
            "sagemaker:InstanceTypes" = [
              "ml.t3.medium",
              "ml.t3.large",
              "ml.t3.xlarge",
              "ml.m5.large",
              "ml.m5.xlarge"
            ]
          }
        }
      }
    ]
  })
}

data "aws_caller_identity" "current" {}
