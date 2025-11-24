# Multi-Cloud Deployment Guide

This guide provides instructions for deploying the AI-powered security platform across AWS, Azure, and GCP.

## Overview

The platform can be deployed on any or all of the three major cloud providers:

- **AWS**: Amazon SageMaker
- **Azure**: Azure Machine Learning
- **GCP**: Vertex AI Workbench

Each deployment provides the same core functionality with cloud-specific optimizations.

## Architecture Comparison

| Feature | AWS (SageMaker) | Azure (ML) | GCP (Vertex AI) |
|---------|-----------------|------------|------------------|
| **Compute** | SageMaker Domain | ML Workspace | Workbench Instance |
| **Notebooks** | JupyterLab | JupyterLab | JupyterLab |
| **Storage** | S3 | Storage Account | Cloud Storage |
| **Secrets** | Secrets Manager | Key Vault | Secret Manager |
| **Network** | VPC | VNet | VPC |
| **Identity** | IAM Identity Center | Entra ID | Cloud IAM |
| **Encryption** | KMS | Key Vault | Cloud KMS |
| **Logging** | CloudWatch | Log Analytics | Cloud Logging |
| **Monitoring** | CloudWatch | Monitor | Cloud Monitoring |

## Prerequisites by Cloud

### AWS
- AWS Account with Administrator access
- AWS CLI configured
- Terraform >= 1.0
- Perplexity Enterprise API key
- (Optional) IAM Identity Center configured

### Azure
- Azure subscription with Owner access
- Azure CLI (`az`) installed
- Terraform >= 1.0
- Perplexity Enterprise API key
- (Optional) Entra ID configured

### GCP
- GCP Project with Owner permissions
- `gcloud` CLI installed
- Terraform >= 1.0
- Perplexity Enterprise API key
- Billing enabled on project

## Deployment Instructions

### Option 1: AWS SageMaker

```bash
cd terraform

# Configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Deploy
terraform init
terraform apply

# Get outputs
terraform output
```

See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for detailed AWS instructions.

### Option 2: Azure Machine Learning

```bash
cd terraform-azure

# Login to Azure
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Configure variables
cat > terraform.tfvars <<EOF
location                 = "eastus"
environment              = "prod"
key_vault_admins         = ["YOUR_USER_OBJECT_ID"]
EOF

# Deploy
terraform init
terraform apply

# Get outputs
terraform output ml_workspace_endpoint
```

#### Post-Deployment Steps (Azure)

1. **Update Key Vault Secrets**:
```bash
VAULT_NAME=$(terraform output -raw key_vault_name)

# Update Perplexity API credentials
az keyvault secret set \
    --vault-name $VAULT_NAME \
    --name perplexity-api-credentials \
    --value '{
        "api_key": "YOUR_PERPLEXITY_API_KEY"
    }'

# Update CrowdStrike credentials
az keyvault secret set \
    --vault-name $VAULT_NAME \
    --name crowdstrike-api-credentials \
    --value '{
        "client_id": "YOUR_CLIENT_ID",
        "client_secret": "YOUR_CLIENT_SECRET"
    }'

# Update Microsoft credentials
az keyvault secret set \
    --vault-name $VAULT_NAME \
    --name microsoft-api-credentials \
    --value '{
        "tenant_id": "YOUR_TENANT_ID",
        "client_id": "YOUR_CLIENT_ID",
        "client_secret": "YOUR_CLIENT_SECRET"
    }'

# Update Proofpoint credentials
az keyvault secret set \
    --vault-name $VAULT_NAME \
    --name proofpoint-api-credentials \
    --value '{
        "service_principal": "YOUR_PRINCIPAL",
        "secret": "YOUR_SECRET"
    }'
```

2. **Access Azure ML Studio**:
```bash
# Open the workspace URL from terraform output
open $(terraform output -raw ml_workspace_endpoint)
```

3. **Upload Notebooks**:
```bash
STORAGE_ACCOUNT=$(terraform output -raw storage_account_name)

# Upload notebooks
az storage blob upload-batch \
    --account-name $STORAGE_ACCOUNT \
    --destination notebooks/templates \
    --source ../notebooks \
    --auth-mode login

# Upload Python libraries
az storage blob upload-batch \
    --account-name $STORAGE_ACCOUNT \
    --destination notebooks/lib \
    --source ../lib \
    --auth-mode login
```

4. **Create Compute Instance**:
   - Navigate to Azure ML Studio
   - Click "Compute" → "Compute instances" → "New"
   - Name: `security-analyst-instance`
   - VM size: `Standard_DS3_v2` (or larger)
   - Click "Create"

5. **Install Dependencies**:

In the compute instance terminal:
```bash
# Set environment variables
export AZURE_KEY_VAULT_URL="https://$VAULT_NAME.vault.azure.net/"
export AZURE_SUBSCRIPTION_ID="YOUR_SUBSCRIPTION_ID"

# Install dependencies
pip install -r /mnt/batch/tasks/shared/LS_root/mounts/clusters/default/code/requirements.txt

# Install security integrations
cd /mnt/batch/tasks/shared/LS_root/mounts/clusters/default/code/lib
pip install -e .
```

### Option 3: GCP Vertex AI

```bash
cd terraform-gcp

# Login to GCP
gcloud auth login
gcloud auth application-default login

# Set project
export PROJECT_ID="your-gcp-project-id"
gcloud config set project $PROJECT_ID

# Enable required APIs
gcloud services enable \
    compute.googleapis.com \
    aiplatform.googleapis.com \
    notebooks.googleapis.com \
    secretmanager.googleapis.com \
    storage.googleapis.com \
    artifactregistry.googleapis.com

# Configure variables
cat > terraform.tfvars <<EOF
project_id  = "$PROJECT_ID"
region      = "us-central1"
zone        = "us-central1-a"
environment = "prod"
EOF

# Deploy
terraform init
terraform apply

# Get outputs
terraform output
```

#### Post-Deployment Steps (GCP)

1. **Update Secrets**:
```bash
# Get secret names
gcloud secrets list

# Update Perplexity API credentials
echo '{
    "api_key": "YOUR_PERPLEXITY_API_KEY"
}' | gcloud secrets versions add perplexity-api-credentials-prod --data-file=-

# Update CrowdStrike credentials
echo '{
    "client_id": "YOUR_CLIENT_ID",
    "client_secret": "YOUR_CLIENT_SECRET"
}' | gcloud secrets versions add crowdstrike-api-credentials-prod --data-file=-

# Update Microsoft credentials
echo '{
    "tenant_id": "YOUR_TENANT_ID",
    "client_id": "YOUR_CLIENT_ID",
    "client_secret": "YOUR_CLIENT_SECRET"
}' | gcloud secrets versions add microsoft-api-credentials-prod --data-file=-

# Update Proofpoint credentials
echo '{
    "service_principal": "YOUR_PRINCIPAL",
    "secret": "YOUR_SECRET"
}' | gcloud secrets versions add proofpoint-api-credentials-prod --data-file=-
```

2. **Upload Code to Cloud Storage**:
```bash
# Get bucket names
NOTEBOOKS_BUCKET=$(terraform output -json storage_buckets | jq -r '.notebooks')

# Upload notebooks
gsutil -m cp -r ../notebooks/* gs://$NOTEBOOKS_BUCKET/templates/

# Upload libraries
gsutil -m cp -r ../lib/* gs://$NOTEBOOKS_BUCKET/lib/

# Upload MCP servers
gsutil -m cp -r ../mcp/* gs://$NOTEBOOKS_BUCKET/mcp/
```

3. **Access Vertex AI Workbench**:
```bash
# Open Vertex AI Workbench
open "https://console.cloud.google.com/vertex-ai/workbench/instances?project=$PROJECT_ID"

# Or get the direct JupyterLab URL
INSTANCE_NAME=$(terraform output -raw workbench_instance_name)
echo "JupyterLab URL: $(gcloud notebooks instances describe $INSTANCE_NAME --location=us-central1-a --format='value(proxyUri)')"
```

4. **Install Dependencies in Workbench**:

In JupyterLab terminal:
```bash
# Set environment variables
export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"
export GCP_PROJECT="$PROJECT_ID"

# Sync code from Cloud Storage
mkdir -p /home/jupyter/code
gsutil -m rsync -r gs://$NOTEBOOKS_BUCKET/ /home/jupyter/code/

# Install dependencies
pip3 install -r /home/jupyter/code/requirements.txt

# Install security integrations
cd /home/jupyter/code/lib
pip3 install -e .
```

## Multi-Cloud Security Integration

The platform includes cloud-agnostic security tool integrations that automatically detect and adapt to the cloud environment.

### Using Cloud-Agnostic Secrets

The `CloudSecretsManager` class automatically detects the cloud provider:

```python
from security_integrations.cloud_secrets import CloudSecretsManager

# Auto-detects cloud provider from environment
secrets = CloudSecretsManager()

# Get credentials (works on all clouds)
perplexity_creds = secrets.get_perplexity_credentials()
crowdstrike_creds = secrets.get_crowdstrike_credentials()
microsoft_creds = secrets.get_microsoft_credentials()
proofpoint_creds = secrets.get_proofpoint_credentials()
```

### Environment Variables by Cloud

**AWS**:
```bash
export AWS_REGION=us-east-1
export AWS_DEFAULT_REGION=us-east-1
```

**Azure**:
```bash
export AZURE_SUBSCRIPTION_ID=your-subscription-id
export AZURE_TENANT_ID=your-tenant-id
export AZURE_KEY_VAULT_URL=https://your-vault.vault.azure.net/
```

**GCP**:
```bash
export GOOGLE_CLOUD_PROJECT=your-project-id
export GCP_PROJECT=your-project-id
```

## Notebook Compatibility

All Jupyter notebooks work across all three cloud platforms with minimal modifications:

1. **Incident Response AI Assistant**: ✅ AWS | ✅ Azure | ✅ GCP
2. **Threat Hunting with ML**: ✅ AWS | ✅ Azure | ✅ GCP

The notebooks automatically detect the cloud environment and use the appropriate secrets management and storage services.

## Cost Comparison

Estimated monthly costs (8 hours/day usage):

| Component | AWS | Azure | GCP |
|-----------|-----|-------|-----|
| **Compute Instance** | $30 | $35 | $32 |
| **Storage (100GB)** | $3 | $3 | $2 |
| **Network (NAT/Egress)** | $33 | $30 | $28 |
| **Secrets Management** | $1 | Included | $1 |
| **Logging (10GB)** | $5 | $3 | $2 |
| **Total** | **~$72** | **~$71** | **~$65** |

*Costs vary by region and actual usage. Enable auto-shutdown and use spot/preemptible instances to reduce costs.*

## Security Best Practices

### All Clouds

1. **Enable MFA** on all admin accounts
2. **Use private networks** only (no public IPs)
3. **Encrypt all data** at rest and in transit
4. **Enable audit logging** for compliance
5. **Regular security scans** of infrastructure
6. **Principle of least privilege** for all IAM/RBAC
7. **Rotate API keys regularly** including Perplexity API key

### Cloud-Specific

**AWS**:
- Enable GuardDuty
- Use AWS Config for compliance
- Enable S3 Block Public Access
- Use VPC endpoints

**Azure**:
- Enable Microsoft Defender for Cloud
- Use Azure Policy for governance
- Enable Storage Account firewall
- Use Private Endpoints

**GCP**:
- Enable Security Command Center
- Use Organization Policies
- Enable VPC Service Controls
- Use Private Google Access

## Troubleshooting

### AWS Issues

See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md#troubleshooting)

### Azure Issues

**Issue**: Cannot access Key Vault

**Solution**:
```bash
# Grant yourself access
az keyvault set-policy \
    --name $VAULT_NAME \
    --upn YOUR_EMAIL \
    --secret-permissions get list set
```

**Issue**: Compute instance won't start

**Solution**:
```bash
# Check quota
az vm list-usage --location eastus --output table

# Request quota increase if needed
```

### GCP Issues

**Issue**: Permission denied accessing secrets

**Solution**:
```bash
# Grant service account access
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:vertex-ai-prod@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"
```

**Issue**: Workbench instance won't connect

**Solution**:
```bash
# Check firewall rules
gcloud compute firewall-rules list

# Verify instance is running
gcloud notebooks instances list --location=us-central1-a
```

## Migration Between Clouds

To migrate your work between cloud platforms:

1. **Export notebooks and models**:
```bash
# From AWS
aws s3 sync s3://your-notebooks-bucket/ ./backup/

# To Azure
az storage blob upload-batch \
    --account-name $AZURE_STORAGE \
    --destination notebooks \
    --source ./backup/

# To GCP
gsutil -m cp -r ./backup/* gs://your-gcp-bucket/
```

2. **Update environment variables** in notebooks
3. **Re-configure secrets** in the new cloud's secrets manager (including Perplexity API key)
4. **Re-train models** if using cloud-specific ML services

## Support

For cloud-specific issues:
- **AWS**: AWS Support or [SageMaker documentation](https://docs.aws.amazon.com/sagemaker/)
- **Azure**: Azure Support or [ML documentation](https://docs.microsoft.com/azure/machine-learning/)
- **GCP**: Google Cloud Support or [Vertex AI documentation](https://cloud.google.com/vertex-ai/docs)
- **Perplexity AI**: Enterprise support portal

For platform issues, see the main [README.md](README.md).

## Next Steps

After deployment:
1. Open the notebooks in your cloud's ML environment
2. Verify Perplexity AI integration is working
3. Run the incident response assistant
4. Execute threat hunting workflows
5. Train custom ML models on your security data
6. Set up automated monitoring and alerting

## Appendix: Resource Naming Conventions

### AWS
- S3: `{environment}-sagemaker-infosec-{purpose}`
- IAM: `SageMaker{Purpose}Role-{environment}`
- KMS: `alias/sagemaker-infosec-{environment}`
- Secrets: `{tool}/api-credentials`

### Azure
- Resource Group: `rg-{environment}-infosec-ml`
- Storage: `st{environment}infosec{random}`
- Key Vault: `kv-{environment}-infosec-{random}`
- Secrets: `{tool}-api-credentials`

### GCP
- Buckets: `{project-id}-{purpose}-{environment}`
- Secrets: `{tool}-api-credentials-{environment}`
- Workbench: `workbench-{environment}-infosec`
