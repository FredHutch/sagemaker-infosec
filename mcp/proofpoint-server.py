#!/usr/bin/env python3
"""
MCP Server for Proofpoint Security Integration
Provides email security, threat intelligence, and TAP (Targeted Attack Protection) data
"""

import asyncio
import json
import logging
from datetime import datetime, timedelta
from typing import Any, Optional
from urllib.parse import urljoin

import boto3
import requests
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Resource, Tool, TextContent

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("proofpoint-mcp-server")


class ProofpointClient:
    """Proofpoint API client wrapper"""

    BASE_URL = "https://tap-api-v2.proofpoint.com/v2/"

    def __init__(self):
        self.service_principal = None
        self.secret = None
        self._load_credentials()
        self.session = requests.Session()
        self.session.auth = (self.service_principal, self.secret)

    def _load_credentials(self):
        """Load Proofpoint credentials from AWS Secrets Manager"""
        try:
            secrets_client = boto3.client('secretsmanager')
            secret = secrets_client.get_secret_value(SecretId='proofpoint/api-credentials')
            creds = json.loads(secret['SecretString'])
            self.service_principal = creds['service_principal']
            self.secret = creds['secret']
            logger.info("Successfully loaded Proofpoint credentials")
        except Exception as e:
            logger.error(f"Failed to load credentials: {e}")
            raise

    def _make_request(self, endpoint: str, params: Optional[dict] = None) -> dict:
        """Make API request to Proofpoint"""
        try:
            url = urljoin(self.BASE_URL, endpoint)
            response = self.session.get(url, params=params, timeout=30)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            logger.error(f"API request failed: {e}")
            return {"error": str(e)}

    async def get_siem_events(
        self,
        interval: str = "PT1H",
        threat_type: Optional[str] = None,
        threat_status: Optional[str] = None
    ) -> dict:
        """Get SIEM events from Proofpoint TAP"""
        try:
            params = {"interval": interval, "format": "json"}

            if threat_type:
                params["threatType"] = threat_type
            if threat_status:
                params["threatStatus"] = threat_status

            data = self._make_request("siem/all", params=params)

            if "error" in data:
                return data

            return {
                "clicks_permitted": data.get("clicksPermitted", []),
                "clicks_blocked": data.get("clicksBlocked", []),
                "messages_delivered": data.get("messagesDelivered", []),
                "messages_blocked": data.get("messagesBlocked", []),
                "total_events": (
                    len(data.get("clicksPermitted", [])) +
                    len(data.get("clicksBlocked", [])) +
                    len(data.get("messagesDelivered", [])) +
                    len(data.get("messagesBlocked", []))
                )
            }
        except Exception as e:
            logger.error(f"Error getting SIEM events: {e}")
            return {"error": str(e)}

    async def get_clicks_blocked(self, interval: str = "PT1H") -> dict:
        """Get blocked clicks from Proofpoint TAP"""
        try:
            params = {"interval": interval, "format": "json"}
            data = self._make_request("siem/clicks/blocked", params=params)

            if "error" in data:
                return data

            return {
                "clicks_blocked": data.get("clicksBlocked", []),
                "count": len(data.get("clicksBlocked", []))
            }
        except Exception as e:
            logger.error(f"Error getting blocked clicks: {e}")
            return {"error": str(e)}

    async def get_messages_blocked(self, interval: str = "PT1H") -> dict:
        """Get blocked messages from Proofpoint TAP"""
        try:
            params = {"interval": interval, "format": "json"}
            data = self._make_request("siem/messages/blocked", params=params)

            if "error" in data:
                return data

            return {
                "messages_blocked": data.get("messagesBlocked", []),
                "count": len(data.get("messagesBlocked", []))
            }
        except Exception as e:
            logger.error(f"Error getting blocked messages: {e}")
            return {"error": str(e)}

    async def get_messages_delivered(
        self,
        interval: str = "PT1H",
        threat_status: Optional[str] = None
    ) -> dict:
        """Get delivered messages (potentially with threats) from Proofpoint TAP"""
        try:
            params = {"interval": interval, "format": "json"}

            if threat_status:
                params["threatStatus"] = threat_status

            data = self._make_request("siem/messages/delivered", params=params)

            if "error" in data:
                return data

            return {
                "messages_delivered": data.get("messagesDelivered", []),
                "count": len(data.get("messagesDelivered", []))
            }
        except Exception as e:
            logger.error(f"Error getting delivered messages: {e}")
            return {"error": str(e)}

    async def get_top_clickers(self, window: int = 30) -> dict:
        """Get top clickers on malicious URLs"""
        try:
            params = {"window": window}
            data = self._make_request("people/top-clickers", params=params)

            if "error" in data:
                return data

            return {
                "top_clickers": data.get("users", []),
                "count": len(data.get("users", []))
            }
        except Exception as e:
            logger.error(f"Error getting top clickers: {e}")
            return {"error": str(e)}

    async def get_vap_report(self, window: int = 30) -> dict:
        """Get Very Attacked People (VAP) report"""
        try:
            params = {"window": window}
            data = self._make_request("people/vap", params=params)

            if "error" in data:
                return data

            return {
                "very_attacked_people": data.get("users", []),
                "count": len(data.get("users", []))
            }
        except Exception as e:
            logger.error(f"Error getting VAP report: {e}")
            return {"error": str(e)}

    async def decode_url(self, encoded_url: str) -> dict:
        """Decode a Proofpoint rewritten URL"""
        try:
            params = {"urls": encoded_url}
            data = self._make_request("url/decode", params=params)

            if "error" in data:
                return data

            return {
                "decoded_urls": data.get("urls", [])
            }
        except Exception as e:
            logger.error(f"Error decoding URL: {e}")
            return {"error": str(e)}

    async def get_campaign_info(self, campaign_id: str) -> dict:
        """Get information about a specific campaign"""
        try:
            data = self._make_request(f"campaign/{campaign_id}")

            if "error" in data:
                return data

            return {
                "campaign": data
            }
        except Exception as e:
            logger.error(f"Error getting campaign info: {e}")
            return {"error": str(e)}


# Initialize MCP server
app = Server("proofpoint-security")
proofpoint = ProofpointClient()


@app.list_resources()
async def list_resources() -> list[Resource]:
    """List available Proofpoint resources"""
    return [
        Resource(
            uri="proofpoint://siem/events",
            name="SIEM Events",
            mimeType="application/json",
            description="Security events from Proofpoint TAP"
        ),
        Resource(
            uri="proofpoint://messages/blocked",
            name="Blocked Messages",
            mimeType="application/json",
            description="Emails blocked by Proofpoint"
        ),
        Resource(
            uri="proofpoint://messages/delivered",
            name="Delivered Messages",
            mimeType="application/json",
            description="Potentially malicious emails that were delivered"
        ),
        Resource(
            uri="proofpoint://people/top-clickers",
            name="Top Clickers",
            mimeType="application/json",
            description="Users who click on malicious URLs most frequently"
        ),
        Resource(
            uri="proofpoint://people/vap",
            name="Very Attacked People",
            mimeType="application/json",
            description="Users targeted most frequently by attackers"
        ),
    ]


@app.list_tools()
async def list_tools() -> list[Tool]:
    """List available Proofpoint tools"""
    return [
        Tool(
            name="get_siem_events",
            description="Get all SIEM events from Proofpoint TAP",
            inputSchema={
                "type": "object",
                "properties": {
                    "interval": {
                        "type": "string",
                        "description": "ISO 8601 duration (e.g., PT1H for 1 hour, PT24H for 24 hours)",
                        "default": "PT1H"
                    },
                    "threat_type": {
                        "type": "string",
                        "enum": ["url", "attachment", "messageText"],
                        "description": "Filter by threat type"
                    },
                    "threat_status": {
                        "type": "string",
                        "enum": ["active", "cleared", "falsePositive"],
                        "description": "Filter by threat status"
                    }
                }
            }
        ),
        Tool(
            name="get_clicks_blocked",
            description="Get blocked clicks on malicious URLs",
            inputSchema={
                "type": "object",
                "properties": {
                    "interval": {
                        "type": "string",
                        "description": "ISO 8601 duration",
                        "default": "PT1H"
                    }
                }
            }
        ),
        Tool(
            name="get_messages_blocked",
            description="Get emails blocked by Proofpoint",
            inputSchema={
                "type": "object",
                "properties": {
                    "interval": {
                        "type": "string",
                        "description": "ISO 8601 duration",
                        "default": "PT1H"
                    }
                }
            }
        ),
        Tool(
            name="get_messages_delivered",
            description="Get potentially malicious emails that were delivered",
            inputSchema={
                "type": "object",
                "properties": {
                    "interval": {
                        "type": "string",
                        "description": "ISO 8601 duration",
                        "default": "PT1H"
                    },
                    "threat_status": {
                        "type": "string",
                        "enum": ["active", "cleared", "falsePositive"],
                        "description": "Filter by threat status"
                    }
                }
            }
        ),
        Tool(
            name="get_top_clickers",
            description="Get users who click on malicious URLs most frequently",
            inputSchema={
                "type": "object",
                "properties": {
                    "window": {
                        "type": "integer",
                        "description": "Number of days to look back (default: 30)",
                        "default": 30
                    }
                }
            }
        ),
        Tool(
            name="get_vap_report",
            description="Get Very Attacked People (most targeted users)",
            inputSchema={
                "type": "object",
                "properties": {
                    "window": {
                        "type": "integer",
                        "description": "Number of days to look back (default: 30)",
                        "default": 30
                    }
                }
            }
        ),
        Tool(
            name="decode_url",
            description="Decode a Proofpoint rewritten URL",
            inputSchema={
                "type": "object",
                "properties": {
                    "encoded_url": {
                        "type": "string",
                        "description": "Proofpoint encoded URL to decode"
                    }
                },
                "required": ["encoded_url"]
            }
        ),
        Tool(
            name="get_campaign_info",
            description="Get information about a specific threat campaign",
            inputSchema={
                "type": "object",
                "properties": {
                    "campaign_id": {
                        "type": "string",
                        "description": "Campaign ID"
                    }
                },
                "required": ["campaign_id"]
            }
        ),
    ]


@app.call_tool()
async def call_tool(name: str, arguments: Any) -> list[TextContent]:
    """Handle tool calls"""
    try:
        if name == "get_siem_events":
            result = await proofpoint.get_siem_events(
                interval=arguments.get("interval", "PT1H"),
                threat_type=arguments.get("threat_type"),
                threat_status=arguments.get("threat_status")
            )
        elif name == "get_clicks_blocked":
            result = await proofpoint.get_clicks_blocked(
                interval=arguments.get("interval", "PT1H")
            )
        elif name == "get_messages_blocked":
            result = await proofpoint.get_messages_blocked(
                interval=arguments.get("interval", "PT1H")
            )
        elif name == "get_messages_delivered":
            result = await proofpoint.get_messages_delivered(
                interval=arguments.get("interval", "PT1H"),
                threat_status=arguments.get("threat_status")
            )
        elif name == "get_top_clickers":
            result = await proofpoint.get_top_clickers(
                window=arguments.get("window", 30)
            )
        elif name == "get_vap_report":
            result = await proofpoint.get_vap_report(
                window=arguments.get("window", 30)
            )
        elif name == "decode_url":
            result = await proofpoint.decode_url(arguments["encoded_url"])
        elif name == "get_campaign_info":
            result = await proofpoint.get_campaign_info(arguments["campaign_id"])
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
