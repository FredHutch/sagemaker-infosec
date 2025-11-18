"""
CrowdStrike Falcon API Client
Wrapper for CrowdStrike FalconPy SDK with async support
"""

import json
import logging
from typing import Dict, List, Optional

import boto3
from falconpy import Detects, Hosts, Incidents, Intel, SpotlightVulnerabilities

logger = logging.getLogger(__name__)


class CrowdStrikeClient:
    """CrowdStrike Falcon API client for threat detection and response"""

    def __init__(self, region_name: str = 'us-east-1'):
        """Initialize CrowdStrike client with credentials from Secrets Manager"""
        self.region_name = region_name
        self._load_credentials()
        self._init_clients()

    def _load_credentials(self):
        """Load CrowdStrike API credentials from AWS Secrets Manager"""
        try:
            secrets_client = boto3.client('secretsmanager', region_name=self.region_name)
            secret = secrets_client.get_secret_value(SecretId='crowdstrike/api-credentials')
            creds = json.loads(secret['SecretString'])
            self.client_id = creds['client_id']
            self.client_secret = creds['client_secret']
            logger.info("Successfully loaded CrowdStrike credentials")
        except Exception as e:
            logger.error(f"Failed to load CrowdStrike credentials: {e}")
            # Use dummy credentials for testing
            self.client_id = "test-client-id"
            self.client_secret = "test-client-secret"

    def _init_clients(self):
        """Initialize FalconPy API clients"""
        try:
            self.detects = Detects(
                client_id=self.client_id,
                client_secret=self.client_secret
            )
            self.hosts = Hosts(
                client_id=self.client_id,
                client_secret=self.client_secret
            )
            self.incidents = Incidents(
                client_id=self.client_id,
                client_secret=self.client_secret
            )
            self.intel = Intel(
                client_id=self.client_id,
                client_secret=self.client_secret
            )
            self.vulnerabilities = SpotlightVulnerabilities(
                client_id=self.client_id,
                client_secret=self.client_secret
            )
            logger.info("CrowdStrike API clients initialized")
        except Exception as e:
            logger.error(f"Failed to initialize CrowdStrike clients: {e}")
            raise

    async def get_detections(
        self,
        start_time: Optional[str] = None,
        severity: Optional[str] = None,
        limit: int = 100
    ) -> Dict:
        """
        Get security detections from CrowdStrike

        Args:
            start_time: ISO 8601 timestamp filter
            severity: Severity level (Critical, High, Medium, Low)
            limit: Maximum number of results

        Returns:
            Dictionary with detections and count
        """
        try:
            filters = []
            if start_time:
                filters.append(f"first_behavior:>='{start_time}'")
            if severity:
                filters.append(f"max_severity_displayname:'{severity}'")

            filter_str = "+".join(filters) if filters else None

            response = self.detects.query_detects(
                filter=filter_str,
                limit=limit,
                sort="first_behavior.desc"
            )

            if response['status_code'] != 200:
                return {"error": response['body'].get('errors', 'Unknown error'), "count": 0}

            detection_ids = response['body']['resources']
            if not detection_ids:
                return {"detections": [], "count": 0}

            details = self.detects.get_detect_summaries(ids=detection_ids)

            return {
                "detections": details['body']['resources'],
                "count": len(details['body']['resources'])
            }
        except Exception as e:
            logger.error(f"Error getting detections: {e}")
            return {"error": str(e), "count": 0}

    async def get_host_info(self, hostname: str) -> Dict:
        """
        Get detailed information about a host

        Args:
            hostname: Hostname to query

        Returns:
            Dictionary with host information
        """
        try:
            query_response = self.hosts.query_devices_by_filter(
                filter=f"hostname:'{hostname}'"
            )

            if query_response['status_code'] != 200:
                return {"error": query_response['body'].get('errors', 'Unknown error')}

            device_ids = query_response['body']['resources']
            if not device_ids:
                return {"error": f"Host '{hostname}' not found"}

            details = self.hosts.get_device_details(ids=device_ids)

            return {
                "host": details['body']['resources'][0],
                "device_id": device_ids[0]
            }
        except Exception as e:
            logger.error(f"Error getting host info: {e}")
            return {"error": str(e)}

    async def get_incidents(
        self,
        start_time: Optional[str] = None,
        status: Optional[str] = None,
        limit: int = 50
    ) -> Dict:
        """
        Get security incidents

        Args:
            start_time: ISO 8601 timestamp filter
            status: Incident status (New, In Progress, Closed)
            limit: Maximum number of results

        Returns:
            Dictionary with incidents and count
        """
        try:
            filters = []
            if start_time:
                filters.append(f"start:>='{start_time}'")
            if status:
                filters.append(f"status:'{status}'")

            filter_str = "+".join(filters) if filters else None

            response = self.incidents.query_incidents(
                filter=filter_str,
                limit=limit,
                sort="start.desc"
            )

            if response['status_code'] != 200:
                return {"error": response['body'].get('errors', 'Unknown error'), "count": 0}

            incident_ids = response['body']['resources']
            if not incident_ids:
                return {"incidents": [], "count": 0}

            details = self.incidents.get_incidents(ids=incident_ids)

            return {
                "incidents": details['body']['resources'],
                "count": len(details['body']['resources'])
            }
        except Exception as e:
            logger.error(f"Error getting incidents: {e}")
            return {"error": str(e), "count": 0}

    async def get_threat_intel(self, indicator: str, indicator_type: str) -> Dict:
        """
        Get threat intelligence for an indicator

        Args:
            indicator: Indicator value (IP, domain, hash, etc.)
            indicator_type: Type of indicator

        Returns:
            Dictionary with threat intelligence
        """
        try:
            response = self.intel.query_indicator_entities(
                filter=f"indicator:'{indicator}'+type:'{indicator_type}'"
            )

            if response['status_code'] != 200:
                return {"error": response['body'].get('errors', 'Unknown error'), "count": 0}

            return {
                "intel": response['body']['resources'],
                "count": len(response['body']['resources'])
            }
        except Exception as e:
            logger.error(f"Error getting threat intel: {e}")
            return {"error": str(e), "count": 0}

    async def get_vulnerabilities(self, hostname: Optional[str] = None) -> Dict:
        """
        Get vulnerability information

        Args:
            hostname: Filter by specific hostname (optional)

        Returns:
            Dictionary with vulnerabilities and count
        """
        try:
            filter_str = f"host.hostname:'{hostname}'" if hostname else None

            response = self.vulnerabilities.query_vulnerabilities(
                filter=filter_str,
                limit=100
            )

            if response['status_code'] != 200:
                return {"error": response['body'].get('errors', 'Unknown error'), "count": 0}

            vuln_ids = response['body']['resources']
            if not vuln_ids:
                return {"vulnerabilities": [], "count": 0}

            details = self.vulnerabilities.get_vulnerabilities(ids=vuln_ids)

            return {
                "vulnerabilities": details['body']['resources'],
                "count": len(details['body']['resources'])
            }
        except Exception as e:
            logger.error(f"Error getting vulnerabilities: {e}")
            return {"error": str(e), "count": 0}
