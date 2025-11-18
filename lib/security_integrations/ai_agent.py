"""
Incident Response AI Agent
Leverages Claude AI for intelligent incident analysis and response
"""

import json
import logging
from datetime import datetime
from typing import Any, Dict, List, Optional

from anthropic import Anthropic

from .crowdstrike_client import CrowdStrikeClient
from .microsoft_client import MicrosoftSecurityClient
from .proofpoint_client import ProofpointClient

logger = logging.getLogger(__name__)


class IncidentResponseAgent:
    """AI-powered incident response agent using Claude"""

    def __init__(
        self,
        crowdstrike: CrowdStrikeClient,
        microsoft: MicrosoftSecurityClient,
        proofpoint: ProofpointClient
    ):
        """
        Initialize incident response agent

        Args:
            crowdstrike: CrowdStrike client instance
            microsoft: Microsoft Security client instance
            proofpoint: Proofpoint client instance
        """
        self.crowdstrike = crowdstrike
        self.microsoft = microsoft
        self.proofpoint = proofpoint
        self.anthropic = Anthropic()  # Uses ANTHROPIC_API_KEY env var

    def aggregate_incidents(
        self,
        cs_detections: Dict,
        cs_incidents: Dict,
        ms_alerts: Dict,
        pp_events: Dict
    ) -> List[Dict]:
        """
        Aggregate incidents from all security platforms

        Returns:
            List of normalized incident dictionaries
        """
        incidents = []

        # Add CrowdStrike detections
        for detection in cs_detections.get('detections', []):
            incidents.append({
                'id': detection.get('detection_id'),
                'title': detection.get('behaviors', [{}])[0].get('scenario', 'Unknown'),
                'description': detection.get('behaviors', [{}])[0].get('description', ''),
                'severity': detection.get('max_severity_displayname', 'Unknown'),
                'source': 'CrowdStrike',
                'timestamp': detection.get('first_behavior'),
                'raw_data': detection
            })

        # Add CrowdStrike incidents
        for incident in cs_incidents.get('incidents', []):
            incidents.append({
                'id': incident.get('incident_id'),
                'title': incident.get('name', 'Unnamed Incident'),
                'description': incident.get('description', ''),
                'severity': incident.get('state', 'Unknown'),
                'source': 'CrowdStrike',
                'timestamp': incident.get('start'),
                'raw_data': incident
            })

        # Add Microsoft Defender alerts
        for alert in ms_alerts.get('alerts', []):
            incidents.append({
                'id': alert.get('id'),
                'title': alert.get('title', 'Unknown Alert'),
                'description': alert.get('description', ''),
                'severity': alert.get('severity', 'Unknown'),
                'source': 'Microsoft Defender',
                'timestamp': alert.get('created_datetime'),
                'raw_data': alert
            })

        # Add Proofpoint events (high-value threats only)
        for msg in pp_events.get('messages_blocked', []):
            if msg.get('threatType') in ['url', 'attachment']:
                incidents.append({
                    'id': msg.get('GUID'),
                    'title': f"Malicious Email Blocked: {msg.get('threatType')}",
                    'description': msg.get('subject', ''),
                    'severity': 'High',
                    'source': 'Proofpoint',
                    'timestamp': msg.get('messageTime'),
                    'raw_data': msg
                })

        return incidents

    async def analyze_incidents(self, incidents: List[Dict]) -> Dict:
        """
        Use AI to analyze and prioritize incidents

        Args:
            incidents: List of incident dictionaries

        Returns:
            Dictionary with prioritized incidents and analysis
        """
        # Prepare data for AI analysis
        incident_summary = self._prepare_incident_summary(incidents)

        # Create AI prompt
        prompt = f"""You are a security analyst reviewing recent security incidents. Analyze the following incidents and:

1. Prioritize them as High, Medium, or Low based on severity, potential impact, and risk
2. Identify potential attack campaigns or related incidents
3. Provide AI risk scores (0-100) for each high-priority incident
4. Recommend specific actions for each high-priority incident
5. Explain your reasoning

Incidents to analyze:
{json.dumps(incident_summary, indent=2)}

Provide your analysis in JSON format with the following structure:
{{
    "high_priority": [
        {{
            "id": "incident_id",
            "title": "incident_title",
            "source": "source_platform",
            "severity": "severity",
            "ai_risk_score": 85,
            "recommended_actions": ["action1", "action2"],
            "ai_reasoning": "explanation"
        }}
    ],
    "medium_priority": [...],
    "low_priority": [...],
    "campaigns": [
        {{
            "name": "Campaign name",
            "related_incidents": ["id1", "id2"],
            "description": "Campaign description"
        }}
    ]
}}"""

        try:
            # Call Claude API
            response = self.anthropic.messages.create(
                model="claude-sonnet-4-20250514",
                max_tokens=4000,
                messages=[
                    {"role": "user", "content": prompt}
                ]
            )

            # Parse response
            analysis_text = response.content[0].text
            # Extract JSON from response
            json_start = analysis_text.find('{')
            json_end = analysis_text.rfind('}') + 1
            analysis = json.loads(analysis_text[json_start:json_end])

            return analysis

        except Exception as e:
            logger.error(f"Error in AI analysis: {e}")
            # Return basic prioritization if AI fails
            return self._basic_prioritization(incidents)

    def _prepare_incident_summary(self, incidents: List[Dict]) -> List[Dict]:
        """Prepare incident data for AI analysis"""
        summary = []
        for inc in incidents[:50]:  # Limit to avoid token limits
            summary.append({
                'id': inc.get('id'),
                'title': inc.get('title'),
                'description': inc.get('description', '')[:200],  # Truncate long descriptions
                'severity': inc.get('severity'),
                'source': inc.get('source'),
                'timestamp': inc.get('timestamp')
            })
        return summary

    def _basic_prioritization(self, incidents: List[Dict]) -> Dict:
        """Basic prioritization if AI is unavailable"""
        high_severity = ['Critical', 'High', 'critical', 'high']
        medium_severity = ['Medium', 'medium']

        return {
            'high_priority': [inc for inc in incidents if inc.get('severity') in high_severity],
            'medium_priority': [inc for inc in incidents if inc.get('severity') in medium_severity],
            'low_priority': [inc for inc in incidents if inc.get('severity') not in high_severity + medium_severity],
            'campaigns': []
        }

    async def investigate_incident(
        self,
        incident: Dict,
        include_timeline: bool = True,
        include_related_events: bool = True,
        include_threat_intel: bool = True
    ) -> Dict:
        """
        Perform deep investigation of an incident

        Args:
            incident: Incident dictionary
            include_timeline: Build event timeline
            include_related_events: Find related events
            include_threat_intel: Lookup threat intelligence

        Returns:
            Investigation results dictionary
        """
        investigation = {
            'incident_id': incident.get('id'),
            'timeline': [],
            'related_events': [],
            'threat_intel': {},
            'affected_assets': {},
            'ai_summary': ''
        }

        # Build timeline
        if include_timeline:
            investigation['timeline'] = await self._build_timeline(incident)

        # Find related events
        if include_related_events:
            investigation['related_events'] = await self._find_related_events(incident)

        # Get threat intelligence
        if include_threat_intel:
            investigation['threat_intel'] = await self._get_threat_intelligence(incident)

        # Get affected assets
        investigation['affected_assets'] = self._extract_affected_assets(incident)

        # Generate AI summary
        investigation['ai_summary'] = await self._generate_investigation_summary(investigation)

        return investigation

    async def _build_timeline(self, incident: Dict) -> List[Dict]:
        """Build event timeline for incident"""
        timeline = []
        # Add initial incident
        timeline.append({
            'timestamp': incident.get('timestamp'),
            'description': f"Incident detected: {incident.get('title')}",
            'source': incident.get('source'),
            'indicators': []
        })
        return timeline

    async def _find_related_events(self, incident: Dict) -> List[Dict]:
        """Find events related to the incident"""
        related = []
        # Implementation would query all sources for related events
        return related

    async def _get_threat_intelligence(self, incident: Dict) -> Dict:
        """Get threat intelligence for incident indicators"""
        threat_intel = {
            'actor': 'Unknown',
            'ttps': [],
            'malware_family': 'Unknown'
        }
        # Implementation would query threat intel sources
        return threat_intel

    def _extract_affected_assets(self, incident: Dict) -> Dict:
        """Extract affected hosts and users from incident"""
        return {
            'hosts': [],
            'users': []
        }

    async def _generate_investigation_summary(self, investigation: Dict) -> str:
        """Generate AI summary of investigation"""
        prompt = f"""Summarize this security incident investigation in 2-3 paragraphs:

{json.dumps(investigation, indent=2, default=str)}

Focus on:
1. What happened
2. Potential impact
3. Key findings
4. Recommended next steps"""

        try:
            response = self.anthropic.messages.create(
                model="claude-sonnet-4-20250514",
                max_tokens=1000,
                messages=[{"role": "user", "content": prompt}]
            )
            return response.content[0].text
        except Exception as e:
            logger.error(f"Error generating summary: {e}")
            return "Investigation summary unavailable."

    def generate_response_plan(
        self,
        incident: Dict,
        investigation: Dict,
        playbook: Dict
    ) -> Dict:
        """Generate automated response plan"""
        return {
            'containment': [
                {
                    'description': 'Isolate affected hosts',
                    'impact': 'High - will disconnect hosts from network',
                    'risk_level': 'Medium',
                    'can_automate': False
                }
            ],
            'eradication': [],
            'recovery': []
        }

    async def execute_response_actions(
        self,
        actions: List[Dict],
        auto_approve_safe_actions: bool = False
    ) -> List[Dict]:
        """Execute response actions"""
        results = []
        for action in actions:
            if action.get('can_automate') or auto_approve_safe_actions:
                results.append({
                    'action': action['description'],
                    'success': True,
                    'message': 'Action completed successfully (simulated)'
                })
            else:
                results.append({
                    'action': action['description'],
                    'success': False,
                    'message': 'Action requires manual approval'
                })
        return results

    def generate_incident_report(
        self,
        incident: Dict,
        investigation: Dict,
        response_actions: List[Dict],
        include_executive_summary: bool = True,
        include_technical_details: bool = True,
        include_recommendations: bool = True
    ) -> Dict:
        """Generate comprehensive incident report"""
        report_content = f"""# Incident Response Report

## Incident Information
- **ID**: {incident.get('id')}
- **Title**: {incident.get('title')}
- **Severity**: {incident.get('severity')}
- **Source**: {incident.get('source')}
- **Timestamp**: {incident.get('timestamp')}

## Investigation Summary
{investigation.get('ai_summary', 'No summary available')}

## Response Actions Taken
"""
        for action in response_actions:
            status = "✓" if action.get('success') else "✗"
            report_content += f"- {status} {action.get('action')}: {action.get('message')}\n"

        report_content += "\n## Recommendations\n"
        report_content += "- Review and update security policies\n"
        report_content += "- Conduct security awareness training\n"
        report_content += "- Monitor for similar indicators\n"

        return {
            'incident_id': incident.get('id'),
            'content': report_content
        }
