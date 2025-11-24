# Deployment Environment Setup Guide

This guide walks you through setting up a complete Python virtual environment using `uv` for deploying the SageMaker Information Security platform across AWS, Azure, and GCP.

## Why uv?

[uv](https://github.com/astral-sh/uv) is an extremely fast Python package installer and resolver written in Rust. Benefits include:

- **Speed**: 10-100x faster than pip
- **Reliability**: Better dependency resolution than pip
- **Compatibility**: Drop-in replacement for pip and pip-tools
- **Disk efficiency**: Shared package cache across environments
- **Reproducibility**: Lock files for deterministic builds

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Install uv](#install-uv)
3. [Create Virtual Environment](#create-virtual-environment)
4. [Install Python Dependencies](#install-python-dependencies)
5. [Install Cloud CLIs](#install-cloud-clis)
6. [Install Terraform](#install-terraform)
7. [Verify Installation](#verify-installation)
8. [Environment Management](#environment-management)
9. [Troubleshooting](#troubleshooting)

## Prerequisites

- **Operating System**: Linux, macOS, or Windows (WSL2 recommended)
- **Python**: 3.10 or later (uv will manage Python versions)
- **Internet Connection**: For downloading packages
- **Disk Space**: ~2GB for all dependencies

## Install uv

### Linux and macOS

```bash
# Install uv using the official installer
curl -LsSf https://astral.sh/uv/install.sh | sh

# Add uv to PATH (add to ~/.bashrc or ~/.zshrc for persistence)
export PATH="$HOME/.cargo/bin:$PATH"

# Verify installation
uv --version
```

### Windows (PowerShell)

```powershell
# Install uv using PowerShell
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"

# Verify installation
uv --version
```

### Alternative: Install via pip

```bash
pip install uv
```

### Alternative: Install via Homebrew (macOS)

```bash
brew install uv
```

## Create Virtual Environment

### Option 1: Let uv manage Python version

```bash
# Navigate to project directory
cd sagemaker-infosec

# Create virtual environment with Python 3.11 (uv will download if needed)
uv venv --python 3.11 .venv

# Activate the environment
# Linux/macOS:
source .venv/bin/activate

# Windows:
.venv\Scripts\activate
```

### Option 2: Use system Python

```bash
# Create virtual environment using system Python
uv venv .venv

# Activate the environment
source .venv/bin/activate  # Linux/macOS
.venv\Scripts\activate     # Windows
```

### Verify activation

```bash
# Check Python location (should point to .venv)
which python  # Linux/macOS
where python  # Windows

# Check Python version
python --version
```

## Install Python Dependencies

### Install project requirements

```bash
# Ensure virtual environment is activated
# Install all Python dependencies using uv
uv pip install -r requirements.txt

# Install the security integrations library in editable mode
uv pip install -e ./lib
```

### Create a lock file for reproducibility

```bash
# Generate uv.lock file for deterministic installations
uv pip compile requirements.txt -o requirements.lock

# Install from lock file (recommended for production)
uv pip sync requirements.lock
```

### Verify Python packages

```bash
# List installed packages
uv pip list

# Check specific packages
uv pip show boto3 requests pandas
```

## Install Cloud CLIs

### AWS CLI

#### Linux

```bash
# Download and install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verify installation
aws --version

# Configure AWS CLI
aws configure
```

#### macOS

```bash
# Install via Homebrew
brew install awscli

# Or download installer
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /

# Verify installation
aws --version

# Configure AWS CLI
aws configure
```

#### Windows

```powershell
# Download and run the MSI installer
# Visit: https://awscli.amazonaws.com/AWSCLIV2.msi

# Or use Chocolatey
choco install awscli

# Verify installation
aws --version

# Configure AWS CLI
aws configure
```

### Azure CLI

#### Linux

```bash
# Install via package manager (Ubuntu/Debian)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Or via pip in virtual environment
uv pip install azure-cli

# Verify installation
az --version

# Login to Azure
az login
```

#### macOS

```bash
# Install via Homebrew
brew install azure-cli

# Or via pip in virtual environment
uv pip install azure-cli

# Verify installation
az --version

# Login to Azure
az login
```

#### Windows

```powershell
# Download and run the MSI installer
# Visit: https://aka.ms/installazurecliwindows

# Or use Chocolatey
choco install azure-cli

# Or via pip in virtual environment
uv pip install azure-cli

# Verify installation
az --version

# Login to Azure
az login
```

### Google Cloud CLI (gcloud)

#### Linux

```bash
# Download and install
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz
tar -xf google-cloud-cli-linux-x86_64.tar.gz
./google-cloud-sdk/install.sh

# Add to PATH
export PATH="$HOME/google-cloud-sdk/bin:$PATH"

# Initialize gcloud
gcloud init

# Verify installation
gcloud --version
```

#### macOS

```bash
# Install via Homebrew
brew install --cask google-cloud-sdk

# Or download installer
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-darwin-x86_64.tar.gz
tar -xf google-cloud-cli-darwin-x86_64.tar.gz
./google-cloud-sdk/install.sh

# Initialize gcloud
gcloud init

# Verify installation
gcloud --version
```

#### Windows

```powershell
# Download and run the installer
# Visit: https://cloud.google.com/sdk/docs/install

# Or use Chocolatey
choco install gcloudsdk

# Initialize gcloud
gcloud init

# Verify installation
gcloud --version
```

### Install additional gcloud components

```bash
# Install beta and alpha components
gcloud components install beta alpha

# Update all components
gcloud components update
```

## Install Terraform

### Linux

```bash
# Add HashiCorp GPG key and repository
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Verify installation
terraform --version
```

### macOS

```bash
# Install via Homebrew
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Verify installation
terraform --version
```

### Windows

```powershell
# Install via Chocolatey
choco install terraform

# Verify installation
terraform --version
```

### Manual installation (all platforms)

```bash
# Download from https://www.terraform.io/downloads
# Extract and move to PATH

# Linux/macOS:
unzip terraform_*_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Windows: Add terraform.exe to PATH
```

### Enable Terraform tab completion

```bash
# Bash
terraform -install-autocomplete

# Zsh
terraform -install-autocomplete

# Restart shell for changes to take effect
```

## Verify Installation

### Create verification script

Create `verify-environment.sh` (Linux/macOS) or `verify-environment.ps1` (Windows):

```bash
#!/bin/bash
# verify-environment.sh

echo "=== Environment Verification ==="
echo ""

echo "Python Environment:"
python --version
which python
echo ""

echo "uv Package Manager:"
uv --version
echo ""

echo "AWS CLI:"
aws --version 2>/dev/null || echo "Not installed"
echo ""

echo "Azure CLI:"
az --version 2>/dev/null | head -1 || echo "Not installed"
echo ""

echo "Google Cloud CLI:"
gcloud --version 2>/dev/null | head -1 || echo "Not installed"
echo ""

echo "Terraform:"
terraform --version | head -1
echo ""

echo "Python Packages:"
echo "  boto3: $(uv pip show boto3 2>/dev/null | grep Version | cut -d' ' -f2 || echo 'Not installed')"
echo "  azure-identity: $(uv pip show azure-identity 2>/dev/null | grep Version | cut -d' ' -f2 || echo 'Not installed')"
echo "  requests: $(uv pip show requests 2>/dev/null | grep Version | cut -d' ' -f2 || echo 'Not installed')"
echo ""

echo "=== Verification Complete ==="
```

Make executable and run:

```bash
chmod +x verify-environment.sh
./verify-environment.sh
```

### Expected output

```
=== Environment Verification ===

Python Environment:
Python 3.11.x
/path/to/sagemaker-infosec/.venv/bin/python

uv Package Manager:
uv 0.x.x

AWS CLI:
aws-cli/2.x.x Python/3.x.x

Azure CLI:
azure-cli 2.x.x

Google Cloud CLI:
Google Cloud SDK 4xx.x.x

Terraform:
Terraform v1.x.x

Python Packages:
  boto3: 1.34.x
  azure-identity: 1.15.x
  requests: 2.31.x

=== Verification Complete ===
```

## Environment Management

### Activate/Deactivate environment

```bash
# Activate
source .venv/bin/activate  # Linux/macOS
.venv\Scripts\activate     # Windows

# Deactivate
deactivate
```

### Update dependencies

```bash
# Update all packages to latest compatible versions
uv pip install --upgrade -r requirements.txt

# Update a specific package
uv pip install --upgrade boto3

# Regenerate lock file
uv pip compile requirements.txt -o requirements.lock
```

### Export environment

```bash
# Create requirements file from current environment
uv pip freeze > requirements-frozen.txt

# Create lock file with all dependencies and hashes
uv pip compile requirements.txt --generate-hashes -o requirements-secure.lock
```

### Clean and rebuild environment

```bash
# Deactivate if active
deactivate

# Remove virtual environment
rm -rf .venv

# Create fresh environment
uv venv .venv
source .venv/bin/activate

# Reinstall dependencies
uv pip sync requirements.lock
```

## Quick Setup Script

Create `setup-deployment-env.sh` for automated setup:

```bash
#!/bin/bash
set -e

echo "Setting up deployment environment..."

# Install uv if not present
if ! command -v uv &> /dev/null; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# Create virtual environment
echo "Creating virtual environment..."
uv venv --python 3.11 .venv

# Activate environment
source .venv/bin/activate

# Install Python dependencies
echo "Installing Python dependencies..."
uv pip install -r requirements.txt
uv pip install -e ./lib

# Create lock file
echo "Creating lock file..."
uv pip compile requirements.txt -o requirements.lock

echo ""
echo "=== Setup Complete ==="
echo "Virtual environment created at: .venv"
echo "Activate with: source .venv/bin/activate"
echo ""
echo "Next steps:"
echo "1. Install AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
echo "2. Install Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
echo "3. Install Google Cloud CLI: https://cloud.google.com/sdk/docs/install"
echo "4. Install Terraform: https://www.terraform.io/downloads"
echo "5. Run: ./verify-environment.sh"
```

Make executable and run:

```bash
chmod +x setup-deployment-env.sh
./setup-deployment-env.sh
```

## Troubleshooting

### Issue: uv not found after installation

**Solution**:
```bash
# Add to PATH
export PATH="$HOME/.cargo/bin:$PATH"

# Make permanent (add to ~/.bashrc or ~/.zshrc)
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Issue: Permission denied errors

**Solution**:
```bash
# Don't use sudo with uv
# Ensure .venv is owned by current user
sudo chown -R $USER:$USER .venv
```

### Issue: Dependency resolution conflicts

**Solution**:
```bash
# Use uv's resolver
uv pip install --resolution highest -r requirements.txt

# Or compile with specific resolution strategy
uv pip compile --resolution highest requirements.txt -o requirements.lock
```

### Issue: AWS CLI not found

**Solution**:
```bash
# Check PATH
echo $PATH

# Add AWS CLI to PATH (Linux/macOS)
export PATH="/usr/local/bin:$PATH"

# Windows: Add to system PATH via Environment Variables
```

### Issue: Python version mismatch

**Solution**:
```bash
# Let uv install specific Python version
uv venv --python 3.11 .venv

# Or use pyenv to manage system Python
curl https://pyenv.run | bash
pyenv install 3.11.7
pyenv global 3.11.7
```

### Issue: Terraform state lock errors

**Solution**:
```bash
# Unlock state (use with caution)
terraform force-unlock <LOCK_ID>

# Or delete local state and re-initialize
rm -rf .terraform
terraform init
```

## Best Practices

1. **Use lock files**: Always commit `requirements.lock` for reproducible builds
2. **Separate environments**: Use different virtual environments for dev/staging/prod
3. **Version pinning**: Pin critical dependencies in `requirements.txt`
4. **Regular updates**: Update dependencies monthly and test thoroughly
5. **Cloud credential management**: Never commit credentials; use cloud secrets managers
6. **Environment variables**: Use `.env` files (gitignored) for local development
7. **Documentation**: Update this guide when adding new dependencies

## Additional Resources

- [uv Documentation](https://github.com/astral-sh/uv)
- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)
- [Azure CLI Documentation](https://docs.microsoft.com/en-us/cli/azure/)
- [Google Cloud CLI Documentation](https://cloud.google.com/sdk/docs)
- [Terraform Documentation](https://www.terraform.io/docs)

## Next Steps

After setting up your environment:

1. Configure cloud credentials:
   - AWS: `aws configure`
   - Azure: `az login`
   - GCP: `gcloud auth login`

2. Store API secrets in cloud secret managers:
   - Follow [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for detailed instructions

3. Deploy infrastructure:
   - Navigate to `terraform/` directory
   - Run `terraform init`
   - Run `terraform plan`
   - Run `terraform apply`

4. Verify deployment:
   - Run the verification notebook
   - Test security tool integrations
   - Validate AI agent functionality
