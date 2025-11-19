#!/bin/bash
set -eux

echo "Installing security tools and dependencies..."

# Update pip
pip3 install --upgrade pip

# Install security analysis libraries
pip3 install --upgrade \
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
pip3 install --upgrade \
    torch \
    transformers \
    anthropic \
    google-cloud-aiplatform \
    langchain \
    langchain-anthropic

# Install security tool integrations
pip3 install --upgrade \
    crowdstrike-falconpy \
    microsoft-graph \
    azure-identity \
    google-cloud-secret-manager \
    google-cloud-storage

# Install MCP SDK
pip3 install --upgrade mcp

# Install network analysis tools
pip3 install --upgrade networkx scapy

# Create directories
mkdir -p /home/jupyter/threat-hunting
mkdir -p /home/jupyter/incident-response
mkdir -p /home/jupyter/ml-models
mkdir -p /home/jupyter/security-data

# Download notebooks from Cloud Storage if configured
if [ -d "/home/jupyter" ]; then
    gsutil -m rsync -r gs://${project_id}-notebooks/templates/ /home/jupyter/templates/ || true
fi

# Set permissions
chown -R jupyter:jupyter /home/jupyter

echo "Security tools installation complete!"
