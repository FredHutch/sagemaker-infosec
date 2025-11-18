from setuptools import setup, find_packages

setup(
    name="security-integrations",
    version="1.0.0",
    description="Security tool integrations for SageMaker AI platform",
    author="Security Team",
    packages=find_packages(),
    install_requires=[
        "anthropic>=0.18.0",
        "boto3>=1.34.0",
        "crowdstrike-falconpy>=1.3.0",
        "azure-identity>=1.15.0",
        "msgraph-sdk>=1.1.0",
        "requests>=2.31.0",
        "pandas>=2.0.0",
        "numpy>=1.24.0",
        "networkx>=3.1",
    ],
    python_requires=">=3.10",
)
