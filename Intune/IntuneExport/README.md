# Intune Environment HTML Report Generator

This PowerShell script creates a comprehensive HTML report of your Microsoft Intune environment, providing IT administrators and auditors with detailed documentation of all configurations.

## Overview

The `Export-IntuneToHtmlReport.ps1` script connects to Microsoft Graph API to export, organize, and document your entire Intune environment in a well-structured, interactive HTML report. This tool is especially useful for:

- Creating documentation for auditing purposes
- Maintaining configuration records
- Sharing environment details with stakeholders
- Troubleshooting configuration issues
- Planning and change management

## Features

### Comprehensive Data Collection

The script collects information about:

- **Device Configuration Policies**
- **Compliance Policies**
- **Applications**
- **App Configuration Policies**
- **App Protection Policies**
- **Security Baselines**
- **Windows Autopilot Profiles**
- **Administrative Templates (Group Policy)**
- **Enrollment Configurations**
- **Device Categories**
- **Terms and Conditions**
- **Managed Devices** (optional)
- **Intune-Related Azure AD Groups**:
  - Groups assigned to policies/apps
  - Groups with "Intune" in their name

### Interactive HTML Report

The generated HTML report includes:

- **Navigation Sidebar**: Quick links to all sections
- **Summary Dashboard**: Overview of configuration counts
- **Collapsible Sections**: Expand/collapse details for better readability
- **Group Resolution**: Displays readable group names instead of just IDs
- **Mobile-Friendly Design**: Responsive layout that works on various devices
- **Policy Assignments**: Shows which groups are targeted by each policy/app

### Performance Optimizations

- **Targeted Group Collection**: Intelligently identifies Intune-related groups
- **Batch Processing**: Processes large datasets in manageable chunks
- **Error Resilience**: Continues execution even when individual components fail

## Requirements

- PowerShell 5.1 or later
- Microsoft Graph PowerShell modules:
  - Microsoft.Graph.Intune
  - Microsoft.Graph.Authentication
  - Microsoft.Graph.Groups
- Appropriate permissions in Microsoft Intune and Azure AD

## Installation

```powershell
# Install required modules
Install-Module -Name Microsoft.Graph.Intune -Scope CurrentUser
Install-Module -Name Microsoft.Graph.Authentication -Scope CurrentUser
Install-Module -Name Microsoft.Graph.Groups -Scope CurrentUser
```

## Usage

### Basic Usage

```powershell
.\Export-IntuneToHtmlReport.ps1
```

This will:
1. Create an HTML report on your Desktop with a timestamp in the filename
2. Include all policy assignments
3. Include managed device information
4. Include all Intune-related Azure AD groups (assigned groups and groups with "Intune" in their name)

### Customize Output Location

```powershell
.\Export-IntuneToHtmlReport.ps1 -OutputPath "C:\Reports\IntuneAudit.html"
```

### Exclude Device Information (for Faster Reports)

```powershell
.\Export-IntuneToHtmlReport.ps1 -IncludeDevices:$false
```

### Exclude Group Assignments

```powershell
.\Export-IntuneToHtmlReport.ps1 -IncludeAssignments:$false
```

### Exclude Azure AD Groups

```powershell
.\Export-IntuneToHtmlReport.ps1 -IncludeGroups:$false
```

## Report Structure

The HTML report is organized into sections:

1. **Summary**: Shows counts of all components in your environment
2. **Policy Sections**: Each policy type has its own section with details and assignments
3. **Applications**: Lists all applications with details and assignments
4. **Devices** (if included): Lists all managed devices with details
5. **Intune-Related Azure AD Groups** (if included): Lists groups assigned to Intune policies/apps and groups with "Intune" in their name, with a status indicator showing their association

## Troubleshooting

- If the script fails with permission errors, ensure you have the appropriate Graph API permissions
- Large environments may take time to process, especially when including devices
- If modules are missing, the script will offer to install them automatically

## Notes

- The report is generated with a timestamp in the filename by default
- All data is collected using read-only operations and does not modify your environment
- The Azure AD Groups section includes both groups assigned to Intune policies and groups with "Intune" in their name
- The script handles null or empty sections gracefully with appropriate alerts

## Security Considerations

This script requires access to your Intune environment with read permissions. It will prompt for authentication using the Microsoft Graph authentication flow. No credentials are stored within the script.

## License

This project is licensed under the MIT License - see the LICENSE file for details. 