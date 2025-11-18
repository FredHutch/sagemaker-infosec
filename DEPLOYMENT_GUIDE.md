# SageMaker Information Security Platform - Deployment Guide

This guide provides step-by-step instructions for deploying the SageMaker AI-powered security platform.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Pre-Deployment Checklist](#pre-deployment-checklist)
3. [Step-by-Step Deployment](#step-by-step-deployment)
4. [Post-Deployment Configuration](#post-deployment-configuration)
5. [Validation and Testing](#validation-and-testing)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

### AWS Account Requirements

- AWS Account with Administrator access (or equivalent permissions)
- AWS CLI installed and configured
- Terraform >= 1.0 installed
- Python 3.10+ installed locally

### IAM Permissions Required

The deployment requires permissions for:
- SageMaker (full access)
- VPC creation and management
- IAM role creation
- S3 bucket creation
- KMS key creation
- Secrets Manager
- CloudWatch Logs
- EC2 (for VPC resources)

### Security Tool Access

You'll need API credentials for:
- **CrowdStrike Falcon**: API client ID and secret with permissions for Detections, Hosts, Incidents, Intel
- **Microsoft**: Azure AD application with permissions for:
  - Microsoft Graph API (SecurityEvents.Read.All, User.Read.All, AuditLog.Read.All)
  - Microsoft Defender API
  - Microsoft Purview API
- **Proofpoint TAP**: Service principal and secret

## Pre-Deployment Checklist

### 1. Gather Information

Before starting, collect the following information:

```
□ AWS Account ID: _______________________
□ AWS Region: ___________________________
□ VPC CIDR Block: _______________________ (default: 10.0.0.0/16)
□ Availability Zones: ___________________ (default: 3 AZs)
□ IAM Identity Center Instance ARN: _______________
□ CrowdStrike API Client ID: ___________________
□ CrowdStrike API Client Secret: _______________
□ Microsoft Tenant ID: _________________________
□ Microsoft Client ID: _________________________
□ Microsoft Client Secret: _____________________
□ Proofpoint Service Principal: _______________
□ Proofpoint Secret: __________________________
```

### 2. Configure AWS CLI

```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, and default region
```

Verify configuration:
```bash
aws sts get-caller-identity
```

### 3. Enable IAM Identity Center (Optional but Recommended)

If not already enabled:

1. Navigate to IAM Identity Center in AWS Console
2. Click "Enable"
3. Note the Instance ARN for later use

## Step-by-Step Deployment

### Phase 1: Store Credentials in Secrets Manager

#### CrowdStrike Credentials

```bash
aws secretsmanager create-secret \
    --name crowdstrike/api-credentials \
    --description "CrowdStrike Falcon API credentials" \
    --secret-string '{
        "client_id": "YOUR_CROWDSTRIKE_CLIENT_ID",
        "client_secret": "YOUR_CROWDSTRIKE_CLIENT_SECRET"
    }' \
    --region us-east-1
```

#### Microsoft Credentials

```bash
aws secretsmanager create-secret \
    --name microsoft/api-credentials \
    --description "Microsoft Security API credentials" \
    --secret-string '{
        "tenant_id": "YOUR_TENANT_ID",
        "client_id": "YOUR_CLIENT_ID",
        "client_secret": "YOUR_CLIENT_SECRET"
    }' \
    --region us-east-1
```

#### Proofpoint Credentials

```bash
aws secretsmanager create-secret \
    --name proofpoint/api-credentials \
    --description "Proofpoint TAP API credentials" \
    --secret-string '{
        "service_principal": "YOUR_SERVICE_PRINCIPAL",
        "secret": "YOUR_SECRET"
    }' \
    --region us-east-1
```

Verify secrets were created:
```bash
aws secretsmanager list-secrets --region us-east-1 | grep -E "crowdstrike|microsoft|proofpoint"
```

### Phase 2: Prepare Terraform Variables

Create `terraform/terraform.tfvars`:

```hcl
aws_region                    = "us-east-1"
environment                   = "prod"
sagemaker_domain_name         = "infosec-ml-domain"
vpc_cidr                      = "10.0.0.0/16"
availability_zones            = ["us-east-1a", "us-east-1b", "us-east-1c"]
identity_center_instance_arn  = "arn:aws:sso:::instance/ssoins-XXXXXXXXXXXXX"

# KMS key administrators (IAM user/role ARNs)
kms_key_administrators = [
    "arn:aws:iam::ACCOUNT_ID:user/admin-user",
    "arn:aws:iam::ACCOUNT_ID:role/AdminRole"
]

# KMS key users (IAM user/role ARNs)
kms_key_users = [
    "arn:aws:iam::ACCOUNT_ID:user/security-analyst",
]

# Secrets Manager ARNs
secrets_manager_arns = [
    "arn:aws:secretsmanager:us-east-1:ACCOUNT_ID:secret:crowdstrike/*",
    "arn:aws:secretsmanager:us-east-1:ACCOUNT_ID:secret:microsoft/*",
    "arn:aws:secretsmanager:us-east-1:ACCOUNT_ID:secret:proofpoint/*"
]

log_retention_days = 90

# Optional: SNS topic for CloudWatch alarms
alarm_sns_topic_arn = ""
```

### Phase 3: Deploy Infrastructure with Terraform

```bash
cd terraform

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Preview changes
terraform plan

# Review the plan carefully, then deploy
terraform apply

# Type 'yes' when prompted
```

This will take approximately 10-15 minutes.

### Phase 4: Capture Outputs

After successful deployment, save the outputs:

```bash
terraform output > ../deployment-outputs.txt

# Display important values
terraform output sagemaker_domain_url
terraform output sagemaker_domain_id
terraform output vpc_id
terraform output data_bucket_name
```

### Phase 5: Upload Code to S3

```bash
# Get bucket name from terraform output
NOTEBOOKS_BUCKET=$(terraform output -raw notebooks_bucket_name)

# Upload MCP servers
aws s3 cp ../mcp/ s3://$NOTEBOOKS_BUCKET/mcp/ --recursive

# Upload Python libraries
aws s3 cp ../lib/ s3://$NOTEBOOKS_BUCKET/lib/ --recursive

# Upload notebooks
aws s3 cp ../notebooks/ s3://$NOTEBOOKS_BUCKET/templates/ --recursive
```

## Post-Deployment Configuration

### 1. Configure IAM Identity Center Access

If using IAM Identity Center:

1. Navigate to IAM Identity Center in AWS Console
2. Click "Users" → "Add user"
3. Create users for your security team
4. Click "Permission sets" → "Create permission set"
5. Create custom permission set with SageMaker access
6. Assign users to your AWS account with the permission set

### 2. Create SageMaker User Profiles

```bash
# Get domain ID
DOMAIN_ID=$(terraform output -raw sagemaker_domain_id)

# Get execution role ARN
EXECUTION_ROLE=$(terraform output -raw sagemaker_execution_role_arn)

# Create user profile for analyst
aws sagemaker create-user-profile \
    --domain-id $DOMAIN_ID \
    --user-profile-name security-analyst-1 \
    --user-settings '{
        "ExecutionRole": "'$EXECUTION_ROLE'",
        "JupyterServerAppSettings": {
            "DefaultResourceSpec": {
                "InstanceType": "ml.t3.medium"
            }
        }
    }'
```

### 3. Access SageMaker Studio

1. Navigate to AWS Console → Amazon SageMaker
2. Click "Domains" in the left sidebar
3. Click on your domain name
4. Click on a user profile
5. Click "Open Studio"

Wait for Studio to load (first launch may take 3-5 minutes)

### 4. Set Up Notebook Environment

In SageMaker Studio terminal:

```bash
# Sync code from S3
aws s3 sync s3://YOUR-NOTEBOOKS-BUCKET/mcp/ /home/sagemaker-user/mcp/
aws s3 sync s3://YOUR-NOTEBOOKS-BUCKET/lib/ /home/sagemaker-user/lib/
aws s3 sync s3://YOUR-NOTEBOOKS-BUCKET/templates/ /home/sagemaker-user/templates/

# Install dependencies
pip install -r /home/sagemaker-user/mcp/requirements.txt

# Install security integrations library
cd /home/sagemaker-user/lib
pip install -e .

# Configure MCP
mkdir -p ~/.config
cp /home/sagemaker-user/mcp/mcp-config.json ~/.config/
```

### 5. Configure Anthropic API Key

Set up Claude AI access:

```bash
# In SageMaker Studio terminal
echo 'export ANTHROPIC_API_KEY="your-api-key"' >> ~/.bashrc
source ~/.bashrc
```

Or create a secret in Secrets Manager:

```bash
aws secretsmanager create-secret \
    --name anthropic/api-key \
    --secret-string '{"api_key":"YOUR_ANTHROPIC_API_KEY"}'
```

## Validation and Testing

### 1. Verify Infrastructure

```bash
# Check SageMaker Domain status
aws sagemaker describe-domain --domain-id $DOMAIN_ID

# Verify S3 buckets
aws s3 ls | grep sagemaker-infosec

# Check KMS key
aws kms describe-key --key-id alias/sagemaker-infosec-prod

# Verify VPC endpoints
aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$VPC_ID"
```

### 2. Test Security Tool Connectivity

Open a SageMaker notebook and test:

```python
import sys
sys.path.append('/home/sagemaker-user/lib')

from security_integrations import CrowdStrikeClient, MicrosoftSecurityClient, ProofpointClient

# Test CrowdStrike
cs = CrowdStrikeClient()
result = await cs.get_detections(limit=5)
print(f"CrowdStrike: {result['count']} detections")

# Test Microsoft
ms = MicrosoftSecurityClient()
result = await ms.get_defender_alerts(limit=5)
print(f"Microsoft: {result['count']} alerts")

# Test Proofpoint
pp = ProofpointClient()
result = await pp.get_siem_events()
print(f"Proofpoint: {result['total_events']} events")
```

### 3. Run Sample Notebook

1. In SageMaker Studio, navigate to templates/
2. Open `incident-response-ai-assistant.ipynb`
3. Run the first few cells to verify setup
4. Check that data is retrieved successfully

## Troubleshooting

### Issue: Terraform Apply Fails

**Symptom**: Error during `terraform apply`

**Solutions**:
```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify IAM permissions
aws iam get-user

# Check for resource limits
aws service-quotas list-service-quotas --service-code sagemaker

# Review Terraform state
terraform show
```

### Issue: Cannot Access SageMaker Studio

**Symptom**: "Access Denied" or timeout when opening Studio

**Solutions**:
1. Verify user has correct IAM permissions
2. Check VPC security groups allow HTTPS (443)
3. Verify NAT Gateway is running
4. Check VPC endpoints are active

```bash
# Check security group
aws ec2 describe-security-groups --group-ids $SG_ID

# Verify NAT Gateway
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID"
```

### Issue: Secrets Manager Access Denied

**Symptom**: Cannot retrieve API credentials

**Solutions**:
```bash
# Verify secrets exist
aws secretsmanager list-secrets

# Check IAM role has permissions
aws iam get-role-policy \
    --role-name SageMakerExecutionRole-prod \
    --policy-name SageMakerSecurityOperations-prod

# Test secret access
aws secretsmanager get-secret-value \
    --secret-id crowdstrike/api-credentials
```

### Issue: MCP Server Connection Failed

**Symptom**: Cannot connect to security tools via MCP

**Solutions**:
1. Verify API credentials are correct
2. Check network connectivity
3. Review MCP server logs

```bash
# Test MCP server manually
python /home/sagemaker-user/mcp/crowdstrike-server.py

# Check CloudWatch logs
aws logs tail /aws/sagemaker/infosec-ml-domain --follow
```

### Issue: High Costs

**Symptom**: Unexpected AWS bill

**Solutions**:
```bash
# Stop unused notebook instances
aws sagemaker list-notebook-instances
aws sagemaker stop-notebook-instance --notebook-instance-name NAME

# Check NAT Gateway data transfer
aws cloudwatch get-metric-statistics \
    --namespace AWS/NATGateway \
    --metric-name BytesOutToSource \
    --start-time 2024-01-01T00:00:00Z \
    --end-time 2024-01-31T23:59:59Z \
    --period 86400 \
    --statistics Sum

# Review S3 storage
aws s3 ls --summarize --human-readable --recursive s3://YOUR-BUCKET/
```

## Rollback Procedure

If you need to remove the deployment:

```bash
cd terraform

# Destroy all resources
terraform destroy

# Manually delete S3 buckets if needed (Terraform may fail if buckets have content)
aws s3 rb s3://BUCKET-NAME --force

# Delete secrets
aws secretsmanager delete-secret --secret-id crowdstrike/api-credentials --force-delete-without-recovery
aws secretsmanager delete-secret --secret-id microsoft/api-credentials --force-delete-without-recovery
aws secretsmanager delete-secret --secret-id proofpoint/api-credentials --force-delete-without-recovery
```

## Next Steps

After successful deployment:

1. Review the [README.md](README.md) for usage instructions
2. Open and explore the sample notebooks
3. Configure custom hunting hypotheses
4. Set up automated monitoring
5. Train custom ML models on your security data

## Support

For issues or questions:
- Review the [troubleshooting](#troubleshooting) section
- Check AWS Service Health Dashboard
- Consult AWS SageMaker documentation
- Review security tool API documentation

## Appendix

### Minimum IAM Policy for Deployment

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sagemaker:*",
                "ec2:*",
                "iam:CreateRole",
                "iam:AttachRolePolicy",
                "iam:PutRolePolicy",
                "iam:PassRole",
                "s3:*",
                "kms:*",
                "secretsmanager:*",
                "logs:*",
                "elasticfilesystem:*"
            ],
            "Resource": "*"
        }
    ]
}
```

### Resource Tagging Strategy

All resources are tagged with:
- `Project`: SageMaker-InfoSec
- `ManagedBy`: Terraform
- `Environment`: prod/dev/staging
- `Team`: SecurityOps
- `CostCenter`: (your cost center)

### Backup and Disaster Recovery

1. **S3 Versioning**: Enabled on all buckets
2. **KMS Key**: Automatic rotation enabled
3. **Terraform State**: Stored in S3 with versioning
4. **Notebook Backups**: Automatically saved to S3

### Compliance Considerations

- **HIPAA**: Enable additional encryption and logging
- **PCI DSS**: Implement network segmentation
- **SOC 2**: Enable CloudTrail and Config
- **GDPR**: Implement data retention policies
