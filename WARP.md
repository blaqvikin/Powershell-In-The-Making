# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

This repository contains Azure automation scripts primarily written in PowerShell, along with supporting ARM templates, Bicep files, and Kusto queries. It's designed for Azure infrastructure management, security auditing, and Microsoft 365/Intune operations.

**Author:** Mawanda.Mlalandle@outlook.com

## Repository Structure

The codebase is organized into functional directories:

- **AD/**: Active Directory and Entra ID management scripts
- **ARMTemplates/**: Azure Resource Manager templates for infrastructure deployment
- **ASR_Backups/**: Azure Site Recovery and backup query scripts
- **AVD/**: Azure Virtual Desktop setup and configuration
- **AzureMigration/**: Migration support scripts and dependencies
- **Bicep/**: Infrastructure as Code using Azure Bicep
- **Intune/**: Microsoft Intune device management scripts
- **Kusto/**: KQL queries for Azure monitoring and diagnostics
- **Linux/**: Linux-specific automation scripts
- **Microsoft365/**: Office 365 administration scripts
- **Remote Management/**: Remote execution and management scripts

## Key Scripts and Their Purpose

### Core Infrastructure
- `LandingZoneResourceCreation.ps1`: Main script for creating Azure landing zone infrastructure including vNets, subnets, storage accounts, and Key Vault with standardized naming conventions

### Azure Virtual Desktop (AVD)
- `AVD/Setup_ForWVD.ps1`: Comprehensive AVD environment setup including FSLogix configuration, AD domain join, and host pool creation

### Security and Compliance
- `AD/FindHighlyPrivilegedRolesInEntra.ps1`: Audits highly privileged roles in Entra ID
- `ARMTemplates/CustomTagging.json`: Azure Policy for enforcing resource tagging compliance

### Device Management
- `Intune/TriggerIntuneRun.ps1`: Triggers Intune policy refresh on devices
- Scripts for managing Windows Mail app and Outlook installations

## Common Development Commands

### PowerShell Script Execution
```powershell
# Set execution policy for script running
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser

# Connect to Azure (common pattern across scripts)
Connect-AzAccount -SubscriptionName "SubscriptionName" -TenantId "TenantID"

# Run a typical infrastructure script
.\LandingZoneResourceCreation.ps1 -resourceGroupName "MyRG" -Environment "nonprod"
```

### Bicep Deployment
```bash
# Deploy Bicep templates
az deployment group create --resource-group "ResourceGroupName" --template-file ./Bicep/deployAppServices.bicep

# Validate Bicep syntax
az bicep build --file ./Bicep/deployAppServices.bicep
```

### ARM Template Deployment
```bash
# Deploy ARM templates with parameters
az deployment group create --resource-group "ResourceGroupName" --template-file ./ARMTemplates/DeployVM-With-KeyVault-DiskEncryption.json --parameters ./ARMTemplates/parameters.json
```

### Kusto Query Testing
```bash
# Run KQL queries against Azure Log Analytics
az monitor log-analytics query --workspace "WorkspaceId" --analytics-query "@./Kusto/AzureDiagnostics.kusto"
```

## Architecture and Patterns

### Naming Conventions
The repository follows Azure naming conventions with consistent prefixes:
- `vnet-{region}-{businessunit}-{environment}` for virtual networks
- `subn-{environment}-{businessunit}` for subnets  
- `sa{region}{businessunit}{environment}` for storage accounts
- `kv-{region}-{businessunit}-{environment}` for key vaults

### Common Parameters Pattern
Most PowerShell scripts follow a consistent parameter pattern:
- `$resourceGroupName`: Target resource group
- `$Environment`: Environment type (nonprod/prod)
- `$BusinessUnit`: Business unit identifier
- `$Region`: Azure region
- `$SubscriptionName`: Target subscription

### Authentication Pattern
Scripts consistently use Azure PowerShell module authentication:
```powershell
Connect-AzAccount -SubscriptionName $SubscriptionName -TenantId $TenantId
Get-AzSubscription -SubscriptionName $SubscriptionName | Set-AzContext
```

### Error Handling
Scripts include basic error checking and validation:
- Resource existence checks before creation
- PowerShell version validation
- Module installation verification

## Prerequisites

### Required PowerShell Modules
- `Az` (Azure PowerShell module)
- `ActiveDirectory` (for AD operations)
- `AzureADPreview` (for Entra ID management)
- `AzFilesHybrid` (for Azure Files domain join)

### Required Tools
- Azure CLI (for Bicep and ARM deployments)
- PowerShell 5.1+ (some scripts require PowerShell 7.1.3+)
- Domain-joined machine (for AVD and AD operations)

### Permissions Required
- Azure subscription contributor or owner rights
- Domain administrator privileges (for AD operations)
- Intune administrator role (for device management scripts)

## Environment-Specific Considerations

### Variable Substitution
Many scripts contain placeholder values that need to be replaced:
- `<Username>`: Replace with actual username
- `<TenantID>`: Replace with Azure tenant ID
- `<SubscriptionName>`: Replace with target subscription
- `<APIKey>`: Replace with actual API keys
- `<EndpointURL>`: Replace with service endpoints

### Regional Settings
Scripts are configured for South Africa regions by default but can be modified:
- Primary region: "South Africa North"  
- Timezone: "South Africa Standard Time"
- Regional codes: "san", "saw" for naming conventions

## Security Notes

- Scripts contain placeholder values for sensitive information
- API keys and tokens should be stored in Azure Key Vault or environment variables
- Storage account keys are used temporarily and should be removed after operations
- All scripts follow principle of least privilege access patterns
