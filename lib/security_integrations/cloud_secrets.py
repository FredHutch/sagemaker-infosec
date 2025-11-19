"""
Cloud-agnostic secrets management
Supports AWS Secrets Manager, Azure Key Vault, and GCP Secret Manager
"""

import json
import logging
import os
from typing import Dict, Optional

logger = logging.getLogger(__name__)


class CloudSecretsManager:
    """
    Unified interface for secrets management across cloud providers
    Automatically detects cloud environment and uses appropriate service
    """

    def __init__(self, cloud_provider: Optional[str] = None):
        """
        Initialize secrets manager

        Args:
            cloud_provider: 'aws', 'azure', or 'gcp'. Auto-detected if not specified.
        """
        self.cloud_provider = cloud_provider or self._detect_cloud_provider()
        self._init_client()

    def _detect_cloud_provider(self) -> str:
        """Auto-detect cloud provider from environment"""
        if os.getenv('AWS_REGION') or os.getenv('AWS_DEFAULT_REGION'):
            return 'aws'
        elif os.getenv('AZURE_SUBSCRIPTION_ID') or os.getenv('AZURE_TENANT_ID'):
            return 'azure'
        elif os.getenv('GOOGLE_CLOUD_PROJECT') or os.getenv('GCP_PROJECT'):
            return 'gcp'
        else:
            logger.warning("Could not auto-detect cloud provider, defaulting to AWS")
            return 'aws'

    def _init_client(self):
        """Initialize cloud-specific secrets client"""
        if self.cloud_provider == 'aws':
            import boto3
            self.client = boto3.client('secretsmanager')
            self.get_secret = self._get_secret_aws
        elif self.cloud_provider == 'azure':
            from azure.identity import DefaultAzureCredential
            from azure.keyvault.secrets import SecretClient
            key_vault_url = os.getenv('AZURE_KEY_VAULT_URL')
            if not key_vault_url:
                raise ValueError("AZURE_KEY_VAULT_URL environment variable required for Azure")
            credential = DefaultAzureCredential()
            self.client = SecretClient(vault_url=key_vault_url, credential=credential)
            self.get_secret = self._get_secret_azure
        elif self.cloud_provider == 'gcp':
            from google.cloud import secretmanager
            self.client = secretmanager.SecretManagerServiceClient()
            self.project_id = os.getenv('GOOGLE_CLOUD_PROJECT') or os.getenv('GCP_PROJECT')
            if not self.project_id:
                raise ValueError("GOOGLE_CLOUD_PROJECT environment variable required for GCP")
            self.get_secret = self._get_secret_gcp
        else:
            raise ValueError(f"Unsupported cloud provider: {self.cloud_provider}")

        logger.info(f"Initialized secrets manager for {self.cloud_provider}")

    def _get_secret_aws(self, secret_name: str) -> Dict:
        """Get secret from AWS Secrets Manager"""
        try:
            response = self.client.get_secret_value(SecretId=secret_name)
            return json.loads(response['SecretString'])
        except Exception as e:
            logger.error(f"Error retrieving AWS secret {secret_name}: {e}")
            raise

    def _get_secret_azure(self, secret_name: str) -> Dict:
        """Get secret from Azure Key Vault"""
        try:
            secret = self.client.get_secret(secret_name)
            return json.loads(secret.value)
        except Exception as e:
            logger.error(f"Error retrieving Azure secret {secret_name}: {e}")
            raise

    def _get_secret_gcp(self, secret_name: str) -> Dict:
        """Get secret from GCP Secret Manager"""
        try:
            name = f"projects/{self.project_id}/secrets/{secret_name}/versions/latest"
            response = self.client.access_secret_version(request={"name": name})
            payload = response.payload.data.decode('UTF-8')
            return json.loads(payload)
        except Exception as e:
            logger.error(f"Error retrieving GCP secret {secret_name}: {e}")
            raise

    def get_crowdstrike_credentials(self) -> Dict:
        """Get CrowdStrike API credentials"""
        secret_names = {
            'aws': 'crowdstrike/api-credentials',
            'azure': 'crowdstrike-api-credentials',
            'gcp': 'crowdstrike-api-credentials-prod'
        }
        return self.get_secret(secret_names[self.cloud_provider])

    def get_microsoft_credentials(self) -> Dict:
        """Get Microsoft API credentials"""
        secret_names = {
            'aws': 'microsoft/api-credentials',
            'azure': 'microsoft-api-credentials',
            'gcp': 'microsoft-api-credentials-prod'
        }
        return self.get_secret(secret_names[self.cloud_provider])

    def get_proofpoint_credentials(self) -> Dict:
        """Get Proofpoint API credentials"""
        secret_names = {
            'aws': 'proofpoint/api-credentials',
            'azure': 'proofpoint-api-credentials',
            'gcp': 'proofpoint-api-credentials-prod'
        }
        return self.get_secret(secret_names[self.cloud_provider])
