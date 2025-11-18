#!/usr/bin/env python3
"""
MCP Server for Microsoft Security Tools Integration
Integrates with Microsoft Defender, Entra ID, and Purview
"""

import asyncio
import json
import logging
from datetime import datetime, timedelta
from typing import Any, Optional

import boto3
from azure.identity import ClientSecretCredential
from msgraph import GraphServiceClient
from msgraph.generated.models.alert import Alert
from msgraph.generated.security.alerts.alerts_request_builder import AlertsRequestBuilder
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Resource, Tool, TextContent

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("microsoft-security-mcp-server")


class MicrosoftSecurityClient:
    """Microsoft Security APIs client wrapper"""

    def __init__(self):
        self.tenant_id = None
        self.client_id = None
        self.client_secret = None
        self._load_credentials()

        # Initialize Microsoft Graph client
        credential = ClientSecretCredential(
            tenant_id=self.tenant_id,
            client_id=self.client_id,
            client_secret=self.client_secret
        )
        self.graph_client = GraphServiceClient(credential)

    def _load_credentials(self):
        """Load Microsoft credentials from AWS Secrets Manager"""
        try:
            secrets_client = boto3.client('secretsmanager')
            secret = secrets_client.get_secret_value(SecretId='microsoft/api-credentials')
            creds = json.loads(secret['SecretString'])
            self.tenant_id = creds['tenant_id']
            self.client_id = creds['client_id']
            self.client_secret = creds['client_secret']
            logger.info("Successfully loaded Microsoft credentials")
        except Exception as e:
            logger.error(f"Failed to load credentials: {e}")
            raise

    async def get_defender_alerts(
        self,
        start_time: Optional[str] = None,
        severity: Optional[str] = None,
        status: Optional[str] = None,
        limit: int = 100
    ) -> dict:
        """Get Microsoft Defender alerts"""
        try:
            # Build filter query
            filters = []
            if start_time:
                filters.append(f"createdDateTime ge {start_time}")
            if severity:
                filters.append(f"severity eq '{severity}'")
            if status:
                filters.append(f"status eq '{status}'")

            filter_str = " and ".join(filters) if filters else None

            # Query alerts
            request_config = AlertsRequestBuilder.AlertsRequestBuilderGetRequestConfiguration(
                query_parameters=AlertsRequestBuilder.AlertsRequestBuilderGetQueryParameters(
                    filter=filter_str,
                    top=limit,
                    orderby=["createdDateTime desc"]
                )
            )

            alerts = await self.graph_client.security.alerts.get(
                request_configuration=request_config
            )

            return {
                "alerts": [self._serialize_alert(alert) for alert in alerts.value],
                "count": len(alerts.value)
            }
        except Exception as e:
            logger.error(f"Error getting Defender alerts: {e}")
            return {"error": str(e)}

    def _serialize_alert(self, alert: Alert) -> dict:
        """Serialize alert object to dict"""
        return {
            "id": alert.id,
            "title": alert.title,
            "description": alert.description,
            "severity": alert.severity,
            "status": alert.status,
            "category": alert.category,
            "created_datetime": alert.created_date_time.isoformat() if alert.created_date_time else None,
            "assigned_to": alert.assigned_to,
            "user_principal_name": alert.user_states[0].user_principal_name if alert.user_states else None,
            "host_fqdn": alert.host_states[0].fqdn if alert.host_states else None,
        }

    async def get_entra_users(
        self,
        filter_query: Optional[str] = None,
        limit: int = 100
    ) -> dict:
        """Get Entra ID (Azure AD) users"""
        try:
            from msgraph.generated.users.users_request_builder import UsersRequestBuilder

            request_config = UsersRequestBuilder.UsersRequestBuilderGetRequestConfiguration(
                query_parameters=UsersRequestBuilder.UsersRequestBuilderGetQueryParameters(
                    filter=filter_query,
                    top=limit
                )
            )

            users = await self.graph_client.users.get(request_configuration=request_config)

            return {
                "users": [{
                    "id": user.id,
                    "display_name": user.display_name,
                    "user_principal_name": user.user_principal_name,
                    "mail": user.mail,
                    "job_title": user.job_title,
                    "department": user.department,
                    "account_enabled": user.account_enabled,
                } for user in users.value],
                "count": len(users.value)
            }
        except Exception as e:
            logger.error(f"Error getting Entra users: {e}")
            return {"error": str(e)}

    async def get_risky_users(self, limit: int = 50) -> dict:
        """Get risky users from Entra ID Protection"""
        try:
            from msgraph.generated.identity_protection.risky_users.risky_users_request_builder import (
                RiskyUsersRequestBuilder
            )

            request_config = RiskyUsersRequestBuilder.RiskyUsersRequestBuilderGetRequestConfiguration(
                query_parameters=RiskyUsersRequestBuilder.RiskyUsersRequestBuilderGetQueryParameters(
                    top=limit,
                    orderby=["riskLastUpdatedDateTime desc"]
                )
            )

            risky_users = await self.graph_client.identity_protection.risky_users.get(
                request_configuration=request_config
            )

            return {
                "risky_users": [{
                    "id": user.id,
                    "user_principal_name": user.user_principal_name,
                    "risk_level": user.risk_level,
                    "risk_state": user.risk_state,
                    "risk_detail": user.risk_detail,
                    "risk_last_updated": user.risk_last_updated_date_time.isoformat() if user.risk_last_updated_date_time else None,
                } for user in risky_users.value],
                "count": len(risky_users.value)
            }
        except Exception as e:
            logger.error(f"Error getting risky users: {e}")
            return {"error": str(e)}

    async def get_sign_in_logs(
        self,
        user_principal_name: Optional[str] = None,
        start_time: Optional[str] = None,
        limit: int = 100
    ) -> dict:
        """Get sign-in logs from Entra ID"""
        try:
            from msgraph.generated.audit_logs.sign_ins.sign_ins_request_builder import (
                SignInsRequestBuilder
            )

            filters = []
            if user_principal_name:
                filters.append(f"userPrincipalName eq '{user_principal_name}'")
            if start_time:
                filters.append(f"createdDateTime ge {start_time}")

            filter_str = " and ".join(filters) if filters else None

            request_config = SignInsRequestBuilder.SignInsRequestBuilderGetRequestConfiguration(
                query_parameters=SignInsRequestBuilder.SignInsRequestBuilderGetQueryParameters(
                    filter=filter_str,
                    top=limit,
                    orderby=["createdDateTime desc"]
                )
            )

            sign_ins = await self.graph_client.audit_logs.sign_ins.get(
                request_configuration=request_config
            )

            return {
                "sign_ins": [{
                    "id": log.id,
                    "created_datetime": log.created_date_time.isoformat() if log.created_date_time else None,
                    "user_principal_name": log.user_principal_name,
                    "app_display_name": log.app_display_name,
                    "ip_address": log.ip_address,
                    "location": f"{log.location.city}, {log.location.country_or_region}" if log.location else None,
                    "status": log.status.error_code if log.status else "Success",
                    "risk_level": log.risk_level_aggregated,
                } for log in sign_ins.value],
                "count": len(sign_ins.value)
            }
        except Exception as e:
            logger.error(f"Error getting sign-in logs: {e}")
            return {"error": str(e)}

    async def get_purview_dlp_alerts(self, limit: int = 50) -> dict:
        """Get Data Loss Prevention alerts from Purview"""
        try:
            # Note: This requires Microsoft 365 Compliance API permissions
            from msgraph.generated.security.alerts_v2.alerts_v2_request_builder import (
                AlertsV2RequestBuilder
            )

            request_config = AlertsV2RequestBuilder.AlertsV2RequestBuilderGetRequestConfiguration(
                query_parameters=AlertsV2RequestBuilder.AlertsV2RequestBuilderGetQueryParameters(
                    filter="serviceSource eq 'microsoftPurview'",
                    top=limit,
                    orderby=["createdDateTime desc"]
                )
            )

            alerts = await self.graph_client.security.alerts_v2.get(
                request_configuration=request_config
            )

            return {
                "dlp_alerts": [{
                    "id": alert.id,
                    "title": alert.title,
                    "description": alert.description,
                    "severity": alert.severity,
                    "status": alert.status,
                    "created_datetime": alert.created_date_time.isoformat() if alert.created_date_time else None,
                } for alert in alerts.value],
                "count": len(alerts.value)
            }
        except Exception as e:
            logger.error(f"Error getting Purview DLP alerts: {e}")
            return {"error": str(e)}


# Initialize MCP server
app = Server("microsoft-security")
microsoft = MicrosoftSecurityClient()


@app.list_resources()
async def list_resources() -> list[Resource]:
    """List available Microsoft Security resources"""
    return [
        Resource(
            uri="microsoft://defender/alerts",
            name="Microsoft Defender Alerts",
            mimeType="application/json",
            description="Security alerts from Microsoft Defender"
        ),
        Resource(
            uri="microsoft://entra/users",
            name="Entra ID Users",
            mimeType="application/json",
            description="User accounts from Entra ID (Azure AD)"
        ),
        Resource(
            uri="microsoft://entra/risky-users",
            name="Risky Users",
            mimeType="application/json",
            description="Risky user accounts identified by Entra ID Protection"
        ),
        Resource(
            uri="microsoft://entra/sign-ins",
            name="Sign-in Logs",
            mimeType="application/json",
            description="User sign-in activity logs"
        ),
        Resource(
            uri="microsoft://purview/dlp-alerts",
            name="Purview DLP Alerts",
            mimeType="application/json",
            description="Data Loss Prevention alerts from Microsoft Purview"
        ),
    ]


@app.list_tools()
async def list_tools() -> list[Tool]:
    """List available Microsoft Security tools"""
    return [
        Tool(
            name="get_defender_alerts",
            description="Get Microsoft Defender security alerts",
            inputSchema={
                "type": "object",
                "properties": {
                    "start_time": {
                        "type": "string",
                        "description": "ISO 8601 timestamp"
                    },
                    "severity": {
                        "type": "string",
                        "enum": ["informational", "low", "medium", "high"],
                        "description": "Alert severity"
                    },
                    "status": {
                        "type": "string",
                        "enum": ["newAlert", "inProgress", "resolved"],
                        "description": "Alert status"
                    },
                    "limit": {
                        "type": "integer",
                        "default": 100
                    }
                }
            }
        ),
        Tool(
            name="get_entra_users",
            description="Get Entra ID user accounts",
            inputSchema={
                "type": "object",
                "properties": {
                    "filter_query": {
                        "type": "string",
                        "description": "OData filter query (e.g., \"department eq 'IT'\")"
                    },
                    "limit": {
                        "type": "integer",
                        "default": 100
                    }
                }
            }
        ),
        Tool(
            name="get_risky_users",
            description="Get risky users from Entra ID Protection",
            inputSchema={
                "type": "object",
                "properties": {
                    "limit": {
                        "type": "integer",
                        "default": 50
                    }
                }
            }
        ),
        Tool(
            name="get_sign_in_logs",
            description="Get user sign-in activity logs",
            inputSchema={
                "type": "object",
                "properties": {
                    "user_principal_name": {
                        "type": "string",
                        "description": "Filter by specific user"
                    },
                    "start_time": {
                        "type": "string",
                        "description": "ISO 8601 timestamp"
                    },
                    "limit": {
                        "type": "integer",
                        "default": 100
                    }
                }
            }
        ),
        Tool(
            name="get_purview_dlp_alerts",
            description="Get Data Loss Prevention alerts from Purview",
            inputSchema={
                "type": "object",
                "properties": {
                    "limit": {
                        "type": "integer",
                        "default": 50
                    }
                }
            }
        ),
    ]


@app.call_tool()
async def call_tool(name: str, arguments: Any) -> list[TextContent]:
    """Handle tool calls"""
    try:
        if name == "get_defender_alerts":
            result = await microsoft.get_defender_alerts(
                start_time=arguments.get("start_time"),
                severity=arguments.get("severity"),
                status=arguments.get("status"),
                limit=arguments.get("limit", 100)
            )
        elif name == "get_entra_users":
            result = await microsoft.get_entra_users(
                filter_query=arguments.get("filter_query"),
                limit=arguments.get("limit", 100)
            )
        elif name == "get_risky_users":
            result = await microsoft.get_risky_users(
                limit=arguments.get("limit", 50)
            )
        elif name == "get_sign_in_logs":
            result = await microsoft.get_sign_in_logs(
                user_principal_name=arguments.get("user_principal_name"),
                start_time=arguments.get("start_time"),
                limit=arguments.get("limit", 100)
            )
        elif name == "get_purview_dlp_alerts":
            result = await microsoft.get_purview_dlp_alerts(
                limit=arguments.get("limit", 50)
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
