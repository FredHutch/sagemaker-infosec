#!/bin/bash
set -eux

# This lifecycle configuration script installs security tools and dependencies

echo "Installing security tools and dependencies..."

# Update pip
pip install --upgrade pip

# Install security analysis libraries
pip install --upgrade \
    pandas \
    numpy \
    scipy \
    scikit-learn \
    matplotlib \
    seaborn \
    plotly \
    jupyter \
    jupyterlab

# Install ML/AI libraries
pip install --upgrade \
    torch \
    transformers \
    anthropic \
    openai \
    langchain \
    langchain-anthropic

# Install security-specific libraries
pip install --upgrade \
    scapy \
    pyshark \
    netaddr \
    ipaddress \
    requests \
    urllib3 \
    cryptography \
    pycryptodome

# Install data analysis libraries
pip install --upgrade \
    jupyterlab-git \
    ipywidgets \
    tqdm \
    joblib

# Install API clients for security tools
pip install --upgrade \
    crowdstrike-falconpy \
    microsoft-graph \
    azure-identity \
    azure-mgmt-security \
    boto3

# Install MCP SDK
pip install --upgrade mcp

# Create directories for security data
mkdir -p /home/sagemaker-user/threat-hunting
mkdir -p /home/sagemaker-user/incident-response
mkdir -p /home/sagemaker-user/ml-models
mkdir -p /home/sagemaker-user/security-data

# Download notebooks from S3 if configured
if [ ! -z "${notebooks_bucket}" ]; then
    echo "Syncing notebooks from S3..."
    aws s3 sync s3://${notebooks_bucket}/templates/ /home/sagemaker-user/templates/ || true
fi

# Set permissions
chown -R sagemaker-user:sagemaker-user /home/sagemaker-user

echo "Security tools installation complete!"
