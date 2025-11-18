"""
Security Integrations Package
Provides clients and utilities for integrating with security tools
"""

from .crowdstrike_client import CrowdStrikeClient
from .microsoft_client import MicrosoftSecurityClient
from .proofpoint_client import ProofpointClient
from .ai_agent import IncidentResponseAgent
from .threat_hunting import ThreatHuntingEngine

__all__ = [
    'CrowdStrikeClient',
    'MicrosoftSecurityClient',
    'ProofpointClient',
    'IncidentResponseAgent',
    'ThreatHuntingEngine',
]

__version__ = '1.0.0'
