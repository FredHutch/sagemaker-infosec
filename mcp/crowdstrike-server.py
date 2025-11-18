#!/usr/bin/env python3
"""
MCP Server for CrowdStrike Falcon API Integration
Provides security event detection, threat hunting, and incident response capabilities
"""

import asyncio
import json
import logging
from datetime import datetime, timedelta
from typing import Any, Optional

import boto3
from falconpy import Detects, Hosts, Incidents, Intel, SpotlightVulnerabilities
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Resource, Tool, TextContent

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("crowdstrike-mcp-server")


class CrowdStrikeClient:
    """CrowdStrike Falcon API client wrapper"""

    def __init__(self):
        self.client_id = None
        self.client_secret = None
        self._load_credentials()

        # Initialize Falcon API clients
        self.detects = Detects(client_id=self.client_id, client_secret=self.client_secret)
        self.hosts = Hosts(client_id=self.client_id, client_secret=self.client_secret)
        self.incidents = Incidents(client_id=self.client_id, client_secret=self.client_secret)
        self.intel = Intel(client_id=self.client_id, client_secret=self.client_secret)
        self.vulnerabilities = SpotlightVulnerabilities(
            client_id=self.client_id,
            client_secret=self.client_secret
        )

    def _load_credentials(self):
        """Load CrowdStrike credentials from AWS Secrets Manager"""
        try:
            secrets_client = boto3.client('secretsmanager')
            secret = secrets_client.get_secret_value(SecretId='crowdstrike/api-credentials')
            creds = json.loads(secret['SecretString'])
            self.client_id = creds['client_id']
            self.client_secret = creds['client_secret']
            logger.info("Successfully loaded CrowdStrike credentials")
        except Exception as e:
            logger.error(f"Failed to load credentials: {e}")
            raise

    async def get_detections(
        self,
        start_time: Optional[str] = None,
        severity: Optional[str] = None,
        limit: int = 100
    ) -> dict:
        """Get security detections from CrowdStrike"""
        try:
            # Build filter
            filters = []
            if start_time:
                filters.append(f"first_behavior:>='{start_time}'")
            if severity:
                filters.append(f"max_severity_displayname:'{severity}'")

            filter_str = "+".join(filters) if filters else None

            # Query detection IDs
            response = self.detects.query_detects(
                filter=filter_str,
                limit=limit,
                sort="first_behavior.desc"
            )

            if response['status_code'] != 200:
                return {"error": response['body']['errors']}

            detection_ids = response['body']['resources']

            if not detection_ids:
                return {"detections": [], "count": 0}

            # Get detection details
            details = self.detects.get_detect_summaries(ids=detection_ids)

            return {
                "detections": details['body']['resources'],
                "count": len(details['body']['resources'])
            }
        except Exception as e:
            logger.error(f"Error getting detections: {e}")
            return {"error": str(e)}

    async def get_host_info(self, hostname: str) -> dict:
        """Get detailed information about a host"""
        try:
            # Search for host
            query_response = self.hosts.query_devices_by_filter(
                filter=f"hostname:'{hostname}'"
            )

            if query_response['status_code'] != 200:
                return {"error": query_response['body']['errors']}

            device_ids = query_response['body']['resources']

            if not device_ids:
                return {"error": f"Host '{hostname}' not found"}

            # Get host details
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
    ) -> dict:
        """Get security incidents"""
        try:
            filters = []
            if start_time:
                filters.append(f"start:>='{start_time}'")
            if status:
                filters.append(f"status:'{status}'")

            filter_str = "+".join(filters) if filters else None

            # Query incident IDs
            response = self.incidents.query_incidents(
                filter=filter_str,
                limit=limit,
                sort="start.desc"
            )

            if response['status_code'] != 200:
                return {"error": response['body']['errors']}

            incident_ids = response['body']['resources']

            if not incident_ids:
                return {"incidents": [], "count": 0}

            # Get incident details
            details = self.incidents.get_incidents(ids=incident_ids)

            return {
                "incidents": details['body']['resources'],
                "count": len(details['body']['resources'])
            }
        except Exception as e:
            logger.error(f"Error getting incidents: {e}")
            return {"error": str(e)}

    async def get_threat_intel(self, indicator: str, indicator_type: str) -> dict:
        """Get threat intelligence for an indicator"""
        try:
            response = self.intel.query_indicator_entities(
                filter=f"indicator:'{indicator}'+type:'{indicator_type}'"
            )

            if response['status_code'] != 200:
                return {"error": response['body']['errors']}

            return {
                "intel": response['body']['resources'],
                "count": len(response['body']['resources'])
            }
        except Exception as e:
            logger.error(f"Error getting threat intel: {e}")
            return {"error": str(e)}

    async def get_vulnerabilities(self, hostname: Optional[str] = None) -> dict:
        """Get vulnerability information"""
        try:
            filter_str = f"host.hostname:'{hostname}'" if hostname else None

            response = self.vulnerabilities.query_vulnerabilities(
                filter=filter_str,
                limit=100
            )

            if response['status_code'] != 200:
                return {"error": response['body']['errors']}

            vuln_ids = response['body']['resources']

            if not vuln_ids:
                return {"vulnerabilities": [], "count": 0}

            # Get vulnerability details
            details = self.vulnerabilities.get_vulnerabilities(ids=vuln_ids)

            return {
                "vulnerabilities": details['body']['resources'],
                "count": len(details['body']['resources'])
            }
        except Exception as e:
            logger.error(f"Error getting vulnerabilities: {e}")
            return {"error": str(e)}


# Initialize MCP server
app = Server("crowdstrike-security")
crowdstrike = CrowdStrikeClient()


@app.list_resources()
async def list_resources() -> list[Resource]:
    """List available CrowdStrike resources"""
    return [
        Resource(
            uri="crowdstrike://detections",
            name="Security Detections",
            mimeType="application/json",
            description="Real-time security detections from CrowdStrike Falcon"
        ),
        Resource(
            uri="crowdstrike://incidents",
            name="Security Incidents",
            mimeType="application/json",
            description="Security incidents requiring investigation"
        ),
        Resource(
            uri="crowdstrike://hosts",
            name="Host Information",
            mimeType="application/json",
            description="Endpoint device information and status"
        ),
        Resource(
            uri="crowdstrike://vulnerabilities",
            name="Vulnerabilities",
            mimeType="application/json",
            description="System vulnerabilities and exposures"
        ),
    ]


@app.list_tools()
async def list_tools() -> list[Tool]:
    """List available CrowdStrike tools"""
    return [
        Tool(
            name="get_detections",
            description="Get recent security detections with optional filtering",
            inputSchema={
                "type": "object",
                "properties": {
                    "start_time": {
                        "type": "string",
                        "description": "ISO 8601 timestamp (e.g., 2024-01-01T00:00:00Z)"
                    },
                    "severity": {
                        "type": "string",
                        "enum": ["Critical", "High", "Medium", "Low"],
                        "description": "Filter by severity level"
                    },
                    "limit": {
                        "type": "integer",
                        "description": "Maximum number of results (default: 100)",
                        "default": 100
                    }
                }
            }
        ),
        Tool(
            name="get_host_info",
            description="Get detailed information about a specific host",
            inputSchema={
                "type": "object",
                "properties": {
                    "hostname": {
                        "type": "string",
                        "description": "Hostname to query"
                    }
                },
                "required": ["hostname"]
            }
        ),
        Tool(
            name="get_incidents",
            description="Get security incidents with optional filtering",
            inputSchema={
                "type": "object",
                "properties": {
                    "start_time": {
                        "type": "string",
                        "description": "ISO 8601 timestamp"
                    },
                    "status": {
                        "type": "string",
                        "enum": ["New", "In Progress", "Closed"],
                        "description": "Filter by incident status"
                    },
                    "limit": {
                        "type": "integer",
                        "description": "Maximum number of results (default: 50)",
                        "default": 50
                    }
                }
            }
        ),
        Tool(
            name="get_threat_intel",
            description="Get threat intelligence for an indicator (IP, domain, hash, etc.)",
            inputSchema={
                "type": "object",
                "properties": {
                    "indicator": {
                        "type": "string",
                        "description": "The indicator value (IP, domain, hash, etc.)"
                    },
                    "indicator_type": {
                        "type": "string",
                        "enum": ["ip_address", "domain", "md5", "sha256", "url"],
                        "description": "Type of indicator"
                    }
                },
                "required": ["indicator", "indicator_type"]
            }
        ),
        Tool(
            name="get_vulnerabilities",
            description="Get vulnerability information, optionally filtered by hostname",
            inputSchema={
                "type": "object",
                "properties": {
                    "hostname": {
                        "type": "string",
                        "description": "Filter by specific hostname (optional)"
                    }
                }
            }
        ),
    ]


@app.call_tool()
async def call_tool(name: str, arguments: Any) -> list[TextContent]:
    """Handle tool calls"""
    try:
        if name == "get_detections":
            result = await crowdstrike.get_detections(
                start_time=arguments.get("start_time"),
                severity=arguments.get("severity"),
                limit=arguments.get("limit", 100)
            )
        elif name == "get_host_info":
            result = await crowdstrike.get_host_info(arguments["hostname"])
        elif name == "get_incidents":
            result = await crowdstrike.get_incidents(
                start_time=arguments.get("start_time"),
                status=arguments.get("status"),
                limit=arguments.get("limit", 50)
            )
        elif name == "get_threat_intel":
            result = await crowdstrike.get_threat_intel(
                arguments["indicator"],
                arguments["indicator_type"]
            )
        elif name == "get_vulnerabilities":
            result = await crowdstrike.get_vulnerabilities(
                hostname=arguments.get("hostname")
            )
        else:
            result = {"error": f"Unknown tool: {name}"}

        return [TextContent(type="text", text=json.dumps(result, indent=2))]
    except Exception as e:
        logger.error(f"Error calling tool {name}: {e}")
        return [TextContent(type="text", text=json.dumps({"error": str(e)}))]


async def main():
    """Run the MCP server"""
    async with stdio_server() as (read_stream, write_stream):
        await app.run(read_stream, write_stream, app.create_initialization_options())


if __name__ == "__main__":
    asyncio.run(main())
