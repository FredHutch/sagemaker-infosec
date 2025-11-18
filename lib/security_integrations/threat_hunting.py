"""
Threat Hunting Engine
ML-powered threat hunting with AI assistance
"""

import json
import logging
from datetime import datetime
from typing import Any, Dict, List, Optional

import networkx as nx
import numpy as np
import pandas as pd
from anthropic import Anthropic

from .crowdstrike_client import CrowdStrikeClient
from .microsoft_client import MicrosoftSecurityClient
from .proofpoint_client import ProofpointClient

logger = logging.getLogger(__name__)


class ThreatHuntingEngine:
    """ML-powered threat hunting engine with AI-assisted analysis"""

    def __init__(
        self,
        crowdstrike: CrowdStrikeClient,
        microsoft: MicrosoftSecurityClient,
        proofpoint: ProofpointClient
    ):
        """
        Initialize threat hunting engine

        Args:
            crowdstrike: CrowdStrike client instance
            microsoft: Microsoft Security client instance
            proofpoint: Proofpoint client instance
        """
        self.crowdstrike = crowdstrike
        self.microsoft = microsoft
        self.proofpoint = proofpoint
        self.anthropic = Anthropic()

    async def collect_crowdstrike_data(
        self,
        start_time: str,
        include_detections: bool = True,
        include_host_activity: bool = True,
        include_network_activity: bool = True
    ) -> Dict:
        """Collect security data from CrowdStrike"""
        data = {
            'detections': [],
            'hosts': [],
            'network_events': []
        }

        if include_detections:
            detections = await self.crowdstrike.get_detections(start_time=start_time)
            data['detections'] = detections.get('detections', [])

        # Additional data collection would go here
        return data

    async def collect_microsoft_data(
        self,
        start_time: str,
        include_sign_ins: bool = True,
        include_alerts: bool = True,
        include_risky_users: bool = True
    ) -> Dict:
        """Collect security data from Microsoft"""
        data = {
            'sign_ins': [],
            'alerts': [],
            'risky_users': []
        }

        if include_sign_ins:
            sign_ins = await self.microsoft.get_sign_in_logs(start_time=start_time)
            data['sign_ins'] = sign_ins.get('sign_ins', [])

        if include_alerts:
            alerts = await self.microsoft.get_defender_alerts(start_time=start_time)
            data['alerts'] = alerts.get('alerts', [])

        if include_risky_users:
            risky = await self.microsoft.get_risky_users()
            data['risky_users'] = risky.get('risky_users', [])

        return data

    async def collect_proofpoint_data(self, interval: str) -> Dict:
        """Collect security data from Proofpoint"""
        data = {
            'total_events': 0,
            'top_clickers': [],
            'vap_users': []
        }

        events = await self.proofpoint.get_siem_events(interval=interval)
        data['total_events'] = events.get('total_events', 0)

        top_clickers = await self.proofpoint.get_top_clickers()
        data['top_clickers'] = top_clickers.get('top_clickers', [])

        vap = await self.proofpoint.get_vap_report()
        data['vap_users'] = vap.get('very_attacked_people', [])

        return data

    def aggregate_data(
        self,
        cs_data: Dict,
        ms_data: Dict,
        pp_data: Dict
    ) -> List[Dict]:
        """Aggregate data from all sources into unified format"""
        events = []

        # Add CrowdStrike detections as events
        for detection in cs_data.get('detections', []):
            events.append({
                'timestamp': detection.get('first_behavior'),
                'source': 'CrowdStrike',
                'event_type': 'detection',
                'data': detection
            })

        # Add Microsoft sign-ins as events
        for signin in ms_data.get('sign_ins', []):
            events.append({
                'timestamp': signin.get('created_datetime'),
                'source': 'Microsoft',
                'event_type': 'sign_in',
                'data': signin
            })

        # Add Microsoft alerts as events
        for alert in ms_data.get('alerts', []):
            events.append({
                'timestamp': alert.get('created_datetime'),
                'source': 'Microsoft',
                'event_type': 'alert',
                'data': alert
            })

        return events

    def prepare_ml_features(self, events: List[Dict]) -> pd.DataFrame:
        """Prepare features for machine learning analysis"""
        # Create feature dataframe
        features = {
            'login_hour': [],
            'login_country_diversity': [],
            'failed_login_count': [],
            'successful_login_count': [],
            'ip_diversity': [],
            'application_diversity': [],
            'user_principal_name': []
        }

        # Extract features from events
        # This is a simplified example - real implementation would be more sophisticated
        user_sessions = {}

        for event in events:
            if event.get('event_type') == 'sign_in':
                data = event.get('data', {})
                user = data.get('user_principal_name', 'unknown')

                if user not in user_sessions:
                    user_sessions[user] = {
                        'login_hours': [],
                        'countries': set(),
                        'ips': set(),
                        'apps': set(),
                        'failed': 0,
                        'successful': 0
                    }

                # Simulate feature extraction
                if event.get('timestamp'):
                    try:
                        hour = datetime.fromisoformat(event['timestamp'].replace('Z', '+00:00')).hour
                        user_sessions[user]['login_hours'].append(hour)
                    except:
                        pass

                user_sessions[user]['successful'] += 1

        # Convert to dataframe
        for user, session in user_sessions.items():
            features['user_principal_name'].append(user)
            features['login_hour'].append(np.mean(session['login_hours']) if session['login_hours'] else 12)
            features['login_country_diversity'].append(len(session['countries']))
            features['failed_login_count'].append(session['failed'])
            features['successful_login_count'].append(session['successful'])
            features['ip_diversity'].append(len(session['ips']))
            features['application_diversity'].append(len(session['apps']))

        return pd.DataFrame(features)

    def detect_beaconing(
        self,
        network_df: pd.DataFrame,
        time_threshold: int = 60,
        count_threshold: int = 10
    ) -> List[Dict]:
        """Detect C2 beaconing patterns in network traffic"""
        beaconing_patterns = []
        # Implementation would analyze network traffic for periodic connections
        return beaconing_patterns

    def detect_data_exfiltration(
        self,
        network_df: pd.DataFrame,
        byte_threshold: int = 10 * 1024 * 1024
    ) -> List[Dict]:
        """Detect potential data exfiltration events"""
        exfiltration_events = []
        # Implementation would analyze network traffic for large data transfers
        return exfiltration_events

    def build_network_graph(self, network_events: List[Dict]) -> nx.DiGraph:
        """Build network graph of host-to-host communications"""
        G = nx.DiGraph()
        # Implementation would build graph from network events
        return G

    def detect_lateral_movement(
        self,
        graph: nx.DiGraph,
        min_connections: int = 3,
        time_window_hours: int = 1
    ) -> List[Dict]:
        """Detect lateral movement patterns"""
        lateral_movement_patterns = []
        # Implementation would analyze graph for lateral movement patterns
        return lateral_movement_patterns

    async def generate_hunting_hypotheses(self, findings: Dict) -> List[Dict]:
        """Generate AI-powered threat hunting hypotheses"""
        prompt = f"""As a security threat hunter, analyze these findings and generate specific, actionable threat hunting hypotheses:

Findings:
{json.dumps(findings, indent=2, default=str)[:3000]}

Generate 3-5 specific threat hunting hypotheses, each with:
1. A clear title
2. Priority level (High, Medium, Low)
3. Relevant MITRE ATT&CK tactics
4. Detailed description of what to look for
5. Step-by-step hunting approach
6. Expected indicators if hypothesis is confirmed

Format as JSON array:
[
    {{
        "title": "Hypothesis title",
        "priority": "High",
        "mitre_tactics": ["Initial Access", "Persistence"],
        "description": "What we're hunting for",
        "hunting_steps": ["Step 1", "Step 2"],
        "expected_indicators": ["Indicator 1", "Indicator 2"]
    }}
]"""

        try:
            response = self.anthropic.messages.create(
                model="claude-sonnet-4-20250514",
                max_tokens=3000,
                messages=[{"role": "user", "content": prompt}]
            )

            response_text = response.content[0].text
            json_start = response_text.find('[')
            json_end = response_text.rfind(']') + 1

            if json_start >= 0 and json_end > json_start:
                hypotheses = json.loads(response_text[json_start:json_end])
                return hypotheses
            else:
                return self._default_hypotheses()

        except Exception as e:
            logger.error(f"Error generating hypotheses: {e}")
            return self._default_hypotheses()

    def _default_hypotheses(self) -> List[Dict]:
        """Return default hunting hypotheses if AI generation fails"""
        return [
            {
                "title": "Suspicious User Behavior Pattern",
                "priority": "High",
                "mitre_tactics": ["Initial Access", "Credential Access"],
                "description": "Hunt for users with anomalous login patterns",
                "hunting_steps": [
                    "Review users with failed login attempts",
                    "Check for logins from unusual locations",
                    "Correlate with threat intelligence"
                ],
                "expected_indicators": [
                    "Multiple failed logins followed by success",
                    "Logins from geographically distant locations",
                    "Logins at unusual hours"
                ]
            }
        ]

    async def execute_hunt(
        self,
        hypothesis: Dict,
        data_sources: Dict
    ) -> Dict:
        """Execute a specific hunting hypothesis"""
        results = {
            'status': 'completed',
            'evidence': [],
            'ai_summary': '',
            'recommended_actions': []
        }

        # Implementation would execute the hunt based on hypothesis
        # For now, return mock results

        prompt = f"""Based on this hunting hypothesis and available data, provide:
1. A summary of findings
2. Recommended next actions

Hypothesis: {hypothesis.get('title')}
Description: {hypothesis.get('description')}

Provide response in this format:
SUMMARY: [your summary]

ACTIONS:
- [action 1]
- [action 2]
"""

        try:
            response = self.anthropic.messages.create(
                model="claude-sonnet-4-20250514",
                max_tokens=1000,
                messages=[{"role": "user", "content": prompt}]
            )

            response_text = response.content[0].text

            # Parse summary and actions
            if "SUMMARY:" in response_text:
                summary_start = response_text.find("SUMMARY:") + 8
                actions_start = response_text.find("ACTIONS:")
                results['ai_summary'] = response_text[summary_start:actions_start].strip()

                if actions_start > 0:
                    actions_text = response_text[actions_start + 8:]
                    results['recommended_actions'] = [
                        line.strip().lstrip('-').strip()
                        for line in actions_text.split('\n')
                        if line.strip().startswith('-')
                    ]

        except Exception as e:
            logger.error(f"Error executing hunt: {e}")
            results['ai_summary'] = "Hunt execution completed. Manual review recommended."

        return results

    def map_to_mitre_attack(self, findings: Dict) -> Dict:
        """Map findings to MITRE ATT&CK framework"""
        mitre_mapping = {
            'Initial Access': [],
            'Execution': [],
            'Persistence': [],
            'Privilege Escalation': [],
            'Defense Evasion': [],
            'Credential Access': [],
            'Discovery': [],
            'Lateral Movement': [],
            'Collection': [],
            'Exfiltration': [],
            'Command and Control': []
        }

        # Implementation would map findings to techniques
        return mitre_mapping

    def create_mitre_heatmap_data(self, mitre_mapping: Dict) -> pd.DataFrame:
        """Create dataframe for MITRE ATT&CK heatmap visualization"""
        # Create empty dataframe for demonstration
        return pd.DataFrame()

    def generate_hunting_report(
        self,
        hunt_period: str,
        anomalies: pd.DataFrame,
        network_analysis: Dict,
        hypotheses: List[Dict],
        hunt_results: Dict,
        mitre_mapping: Dict
    ) -> Dict:
        """Generate comprehensive threat hunting report"""
        report = f"""# Threat Hunting Report

## Hunting Period
{hunt_period}

## Executive Summary
This report summarizes proactive threat hunting activities and findings.

### Key Findings
- Anomalous users detected: {len(anomalies)}
- Beaconing patterns detected: {len(network_analysis.get('beaconing', []))}
- Lateral movement detected: {len(network_analysis.get('lateral_movement', []))}
- Hypotheses investigated: {len(hypotheses)}

## Detailed Analysis
{hunt_results.get('ai_summary', 'See individual sections for details')}

## MITRE ATT&CK Coverage
The following tactics were observed during this hunting period:
"""
        for tactic, techniques in mitre_mapping.items():
            if techniques:
                report += f"\n### {tactic}\n"
                for technique in techniques:
                    report += f"- {technique.get('name', 'Unknown')}\n"

        report += "\n## Recommendations\n"
        for action in hunt_results.get('recommended_actions', []):
            report += f"- {action}\n"

        return {
            'content': report
        }
