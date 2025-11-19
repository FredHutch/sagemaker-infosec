resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.environment}-infosec-ml"
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    Environment = var.environment
  }
}

# Subnet for ML workspace
resource "azurerm_subnet" "ml_subnet" {
  name                 = "snet-${var.environment}-ml"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_prefixes.ml_subnet]

  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.ContainerRegistry"
  ]
}

# Subnet for compute instances
resource "azurerm_subnet" "compute_subnet" {
  name                 = "snet-${var.environment}-compute"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_prefixes.compute_subnet]

  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault"
  ]
}

# Subnet for private endpoints
resource "azurerm_subnet" "pe_subnet" {
  name                 = "snet-${var.environment}-private-endpoints"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_prefixes.pe_subnet]

  private_endpoint_network_policies_enabled = false
}

# Network Security Group for ML subnet
resource "azurerm_network_security_group" "ml_nsg" {
  name                = "nsg-${var.environment}-ml"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowAzureMLInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "AzureMachineLearning"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowBatchNodeManagement"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "29876-29877"
    source_address_prefix      = "BatchNodeManagement"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "ml_nsg_assoc" {
  subnet_id                 = azurerm_subnet.ml_subnet.id
  network_security_group_id = azurerm_network_security_group.ml_nsg.id
}

# NAT Gateway for outbound connectivity
resource "azurerm_public_ip" "nat_ip" {
  name                = "pip-${var.environment}-nat"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat" {
  name                = "nat-${var.environment}-ml"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "nat_ip_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.nat.id
  public_ip_address_id = azurerm_public_ip.nat_ip.id
}

resource "azurerm_subnet_nat_gateway_association" "ml_nat" {
  subnet_id      = azurerm_subnet.ml_subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat.id
}
