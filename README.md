# Multi-Cloud AI for Information Security

A comprehensive AI-powered security operations platform for **AWS SageMaker**, **Azure Machine Learning**, and **GCP Vertex AI**, integrating machine learning, LLM-based AI agents, and enterprise security tools for intelligent threat detection, incident response, and threat hunting.

## 🌩️ Multi-Cloud Support

Deploy on your cloud of choice - or all three:

| Cloud Provider | Service | Status |
|----------------|---------|--------|
| **AWS** | SageMaker | ✅ Fully Supported |
| **Azure** | Machine Learning | ✅ Fully Supported |
| **GCP** | Vertex AI Workbench | ✅ Fully Supported |

All platforms provide the same core functionality with cloud-specific optimizations. See [MULTI_CLOUD_DEPLOYMENT_GUIDE.md](MULTI_CLOUD_DEPLOYMENT_GUIDE.md) for deployment instructions.

## Overview

This solution provides security teams with:

- **AI-Powered Incident Response**: Automated incident triage, investigation, and response using Claude AI
- **ML-Based Threat Hunting**: Machine learning models for anomaly detection and behavioral analysis
- **Multi-Tool Integration**: Unified interface for CrowdStrike, Microsoft Defender/Entra/Purview, and Proofpoint
- **MCP Protocol Support**: Modern integration with security tools via Model Context Protocol
- **Multi-Cloud Deployment**: Deploy on AWS, Azure, or GCP with identical functionality
- **Secure Infrastructure**: VPC/VNet-isolated with cloud-native authentication
- **Interactive Notebooks**: Jupyter notebooks for exploratory analysis and automated workflows

## Architecture

### Infrastructure Components

```
┌─────────────────────────────────────────────────────────────┐
│                   IAM Identity Center                        │
│                   (Authentication)                           │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                  SageMaker Domain                            │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Jupyter Notebooks                                   │   │
│  │  - Incident Response AI Assistant                    │   │
│  │  - Threat Hunting with ML                            │   │
│  │  - Custom Security Analytics                         │   │
│  └──────────────────┬───────────────────────────────────┘   │
│                     │                                        │
│  ┌──────────────────▼───────────────────────────────────┐   │
│  │  MCP Servers (Security Tool Integration)            │   │
│  │  - CrowdStrike Falcon                                │   │
│  │  - Microsoft Defender/Entra/Purview                  │   │
│  │  - Proofpoint TAP                                    │   │
│  └──────────────────┬───────────────────────────────────┘   │
└───────────────────┬─┴───────────────────────────────────────┘
                    │
┌───────────────────▼─────────────────────────────────────────┐
│                      VPC                                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ Private     │  │ NAT         │  │ VPC         │         │
│  │ Subnets     │  │ Gateways    │  │ Endpoints   │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
         │                    │                    │
┌────────▼────────┐  ┌────────▼────────┐  ┌───────▼─────────┐
│  S3 Buckets     │  │  KMS            │  │  CloudWatch     │
│  - Data         │  │  Encryption     │  │  Logging        │
│  - Models       │  │                 │  │                 │
│  - Notebooks    │  │                 │  │                 │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

### Security Tool Integration

```
┌─────────────────────────────────────────────────────────────┐
│              SageMaker Jupyter Notebooks                     │
└──────────────┬──────────────────────────────────────────────┘
               │
               │ MCP Protocol
               │
     ┌─────────┴─────────┬─────────────┬──────────────┐
     │                   │             │              │
┌────▼────────┐  ┌──────▼──────┐  ┌──▼──────────┐  ┌▼─────────┐
│ CrowdStrike │  │ Microsoft   │  │ Proofpoint  │  │ Custom   │
│ MCP Server  │  │ MCP Server  │  │ MCP Server  │  │ Tools    │
└────┬────────┘  └──────┬──────┘  └──┬──────────┘  └┬─────────┘
     │                  │             │              │
     │ API Calls        │ Graph API   │ API Calls    │
     │                  │             │              │
┌────▼────────┐  ┌──────▼──────┐  ┌──▼──────────┐  ┌▼─────────┐
│ CrowdStrike │  │ Microsoft   │  │ Proofpoint  │  │ Other    │
│ Falcon      │  │ Defender    │  │ TAP         │  │ Security │
│ Platform    │  │ Entra ID    │  │             │  │ Tools    │
│             │  │ Purview     │  │             │  │          │
└─────────────┘  └─────────────┘  └─────────────┘  └──────────┘
```

## Prerequisites

### Choose Your Cloud Provider

**AWS**:
- AWS Account with appropriate permissions
- AWS CLI configured
- IAM Identity Center configured (optional, recommended)

**Azure**:
- Azure subscription with Owner access
- Azure CLI (`az`) installed
- Entra ID configured (optional, recommended)

**GCP**:
- GCP Project with Owner permissions
- `gcloud` CLI installed
- Billing enabled on project

**All Platforms**:
- Terraform >= 1.0
- Security tool API credentials:
  - CrowdStrike Falcon API client ID and secret
  - Microsoft Azure AD application with appropriate permissions
  - Proofpoint TAP service principal and secret

## Quick Start

### AWS Deployment

#### 1. Configure Credentials

Store your security tool API credentials in AWS Secrets Manager:

```bash
# CrowdStrike credentials
aws secretsmanager create-secret \
    --name crowdstrike/api-credentials \
    --secret-string '{"client_id":"YOUR_CLIENT_ID","client_secret":"YOUR_CLIENT_SECRET"}'

# Microsoft credentials
aws secretsmanager create-secret \
    --name microsoft/api-credentials \
    --secret-string '{"tenant_id":"YOUR_TENANT_ID","client_id":"YOUR_CLIENT_ID","client_secret":"YOUR_CLIENT_SECRET"}'

# Proofpoint credentials
aws secretsmanager create-secret \
    --name proofpoint/api-credentials \
    --secret-string '{"service_principal":"YOUR_PRINCIPAL","secret":"YOUR_SECRET"}'
```

### 2. Deploy Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan \
    -var="identity_center_instance_arn=arn:aws:sso:::instance/YOUR_INSTANCE_ID" \
    -var="aws_region=us-east-1"

# Deploy
terraform apply \
    -var="identity_center_instance_arn=arn:aws:sso:::instance/YOUR_INSTANCE_ID" \
    -var="aws_region=us-east-1"
```

### 3. Access SageMaker Studio

1. Navigate to the AWS Console → SageMaker
2. Click on "Domains" → Select your domain
3. Click "Studio" to open SageMaker Studio
4. Upload the notebooks from the `notebooks/` directory

### 4. Install Dependencies

In a SageMaker notebook terminal:

```bash
# Install Python dependencies
pip install -r /home/sagemaker-user/mcp/requirements.txt

# Install security integration library
pip install -e /home/sagemaker-user/lib
```

### 5. Configure MCP Servers

Copy the MCP configuration:

```bash
cp /home/sagemaker-user/mcp/mcp-config.json ~/.config/
```

## Usage

### Incident Response

Open `notebooks/incident-response-ai-assistant.ipynb` and run through the cells to:

1. Discover incidents across all security platforms
2. AI-powered triage and prioritization
3. Deep dive investigation with automated timeline reconstruction
4. Execute containment and remediation actions
5. Generate comprehensive incident reports

### Threat Hunting

Open `notebooks/threat-hunting-ml.ipynb` and run through the cells to:

1. Collect security data from all sources
2. Run ML-based anomaly detection
3. Detect network threats (beaconing, exfiltration, lateral movement)
4. Generate AI-powered hunting hypotheses
5. Execute hypothesis-driven hunts
6. Map findings to MITRE ATT&CK

## Key Features

### AI-Powered Analysis

- **Claude AI Integration**: Uses Anthropic's Claude for intelligent analysis
- **Automated Triage**: AI prioritizes incidents based on risk and impact
- **Hypothesis Generation**: AI generates threat hunting hypotheses from findings
- **Natural Language Reports**: AI generates executive and technical reports

### Machine Learning

- **Anomaly Detection**: Isolation Forest for behavioral anomaly detection
- **Pattern Recognition**: Identifies attack patterns and campaigns
- **Predictive Analytics**: Risk scoring and threat prediction
- **Model Persistence**: Save and reuse trained models

### Security Tool Integration

- **CrowdStrike Falcon**: Detections, incidents, hosts, vulnerabilities
- **Microsoft Defender**: Alerts, threat protection
- **Microsoft Entra ID**: Sign-ins, risky users, identity protection
- **Microsoft Purview**: DLP alerts, compliance
- **Proofpoint TAP**: Email threats, top clickers, VAP users

### MCP Protocol

- **Standardized Integration**: Uses Model Context Protocol for tool integration
- **Extensible**: Easy to add new security tools
- **Type-Safe**: Strongly typed interfaces for reliability
- **Async Support**: Non-blocking operations for better performance

## Architecture Decisions

### Why SageMaker?

- **Managed Jupyter**: No infrastructure management
- **Scalable Compute**: From ml.t3.medium to ml.p4d.24xlarge
- **Security**: VPC isolation, encryption, IAM controls
- **Collaboration**: Shared spaces and notebooks
- **MLOps Ready**: Built-in support for model training and deployment

### Why MCP?

- **Standardization**: Industry-standard protocol for LLM tool integration
- **Flexibility**: Works with any MCP-compatible LLM
- **Type Safety**: Schema-driven tool definitions
- **Maintainability**: Cleaner separation of concerns

### Why Claude AI?

- **Context Window**: Large context for analyzing complex security data
- **Reasoning**: Strong analytical and reasoning capabilities
- **Safety**: Built-in safety features for security use cases
- **Speed**: Fast response times for interactive use

## Security Considerations

### Data Protection

- All data encrypted at rest (KMS) and in transit (TLS)
- VPC isolation prevents internet exposure
- S3 buckets have versioning and access logging
- CloudWatch logs for audit trail

### Access Control

- IAM Identity Center for centralized authentication
- Fine-grained IAM policies per security tool
- Separate roles for different team members
- MFA enforcement (configure in Identity Center)

### Network Security

- SageMaker Domain in private subnets
- VPC endpoints for AWS services (no internet routing)
- Security groups restrict traffic
- NAT Gateways for controlled outbound access

### Compliance

- CloudWatch logging for compliance auditing
- S3 lifecycle policies for data retention
- KMS encryption for regulatory requirements
- Network isolation for PCI/HIPAA compliance

## Customization

### Adding New Security Tools

1. Create MCP server in `mcp/your-tool-server.py`
2. Add configuration to `mcp/mcp-config.json`
3. Create client wrapper in `lib/security_integrations/your_tool_client.py`
4. Update notebooks to use new tool

### Custom ML Models

Train and save your own models:

```python
import joblib
from sklearn.ensemble import RandomForestClassifier

# Train your model
model = RandomForestClassifier()
model.fit(X_train, y_train)

# Save to S3
joblib.dump(model, '/tmp/my_model.pkl')
s3_client.upload_file(
    '/tmp/my_model.pkl',
    'your-models-bucket',
    'custom-models/my_model.pkl'
)
```

### Custom Notebooks

Create custom analysis notebooks in the SageMaker environment. All libraries are available.

## Troubleshooting

### Cannot Access SageMaker Studio

- Verify IAM Identity Center permissions
- Check VPC and subnet configuration
- Ensure security groups allow HTTPS (443)

### MCP Server Connection Failed

- Check API credentials in Secrets Manager
- Verify IAM role has secretsmanager:GetSecretValue permission
- Review MCP server logs in CloudWatch

### API Rate Limiting

- Implement exponential backoff in API calls
- Cache frequently accessed data
- Use batch API operations where available

### High Costs

- Stop SageMaker notebooks when not in use
- Use smaller instance types for development
- Implement S3 lifecycle policies
- Set CloudWatch log retention periods

## Cost Optimization

### Estimated Monthly Costs (us-east-1)

- SageMaker Domain: $0 (pay per notebook instance)
- Notebook Instance (ml.t3.medium, 8hr/day): ~$30
- S3 Storage (100GB): ~$3
- VPC (NAT Gateway): ~$33
- Data Transfer: Variable
- KMS: $1
- CloudWatch Logs (10GB): ~$5

**Total: ~$72/month** (excluding data transfer and API calls)

### Cost Reduction Tips

1. Use Spot instances for batch processing
2. Implement auto-shutdown for idle notebooks
3. Use S3 Intelligent-Tiering
4. Single NAT Gateway instead of per-AZ
5. Compress CloudWatch logs

## Support and Contributing

### Getting Help

- Review the documentation in `docs/`
- Check the example notebooks
- File issues on GitHub

### Contributing

Contributions welcome! Areas of interest:

- Additional security tool integrations
- New ML models for threat detection
- Improved visualization
- Documentation improvements

## License

This project is provided as-is for educational and professional use.

## Acknowledgments

- Anthropic for Claude AI
- AWS for SageMaker platform
- Security tool vendors for API access
- MCP protocol specification contributors
