# Intune Export to HTML Report

## Overview

The Export-IntuneToHtmlReport.ps1 script connects to Microsoft Graph API, retrieves Intune configuration data, and generates a comprehensive HTML report of the Intune environment. This tool helps administrators document and review their Intune configurations.

## Recent Updates

### 1. Style Variant Implementation

The script now properly supports multiple visual styles through the `-StyleVariant` parameter:

- **Default**: The standard style built into the main script
- **Style1-Modern**: A modern, clean interface with improved typography and spacing
- **Style2-Corporate**: A professional style suitable for corporate environments
- **Style3-HighContrast**: Enhanced readability with high contrast colors
- **Style4-Compact**: A space-efficient design for dense information
- **Style5-Colorful**: A vibrant style with color coding for visual distinction

Style variants are separate script files in the `StyleVariants` folder. When a style variant is selected, the main script loads the variant script which then takes over the execution.

### 2. Enhanced Group Detection

Improved detection of Azure AD groups with "Intune" in their names using multiple approaches:

- **Method 1**: Uses Graph API filters for groups with names starting with "Intune" and properly handles `endswith` filtering by adding the required ConsistencyLevel header
- **Method 2**: Retrieves groups in batches and performs local filtering for "Intune" anywhere in the name
- **Method 3**: Fallback method using a simple string contains approach if the other methods don't find enough groups

The enhanced detection helps ensure that groups like "Intune User Group" are properly discovered and included in the report.

### 3. Fixed Data Structure and Type Handling

Resolved errors related to group ID handling and assignment target types:

- Fixed conversion issues where the script was attempting to convert GUIDs (strings) to integers
- Added proper handling of unexpected string targets in policy and app assignments
- Improved detection of "All Users" and "All Devices" assignments through multiple format checks
- Fixed "Unknown Target Type" issues with assignments that don't use standard group targeting
- Improved error handling for various assignment structures
- Added proper string handling for group IDs in collections
- Added robust type checking to prevent errors when accessing properties of string values

### 4. UI Improvements

The HTML report has been updated with several visual enhancements:

- **Policy Highlighting**: Policies and apps now stand out with a left border and improved typography
- **Compact Inline Assignments**: Group assignments now appear in the same row as policies for a more compact layout
- **Improved Color Scheme**: Better contrast between headers and content
- **Count Indicators**: Assignment buttons now show the number of assignments
- **Responsive Design**: Better spacing and layout for readability

## Usage

```powershell
.\Export-IntuneToHtmlReport.ps1 -StyleVariant "Style1-Modern" -OutputPath "C:\Reports\IntuneReport.html" -IncludeAssignments -IncludeDevices -IncludeGroups -CompanyName "Contoso"
```

### Parameters

- **OutputPath**: Where to save the HTML report (default: Desktop)
- **StyleVariant**: Visual style to use (default: "Default")
- **IncludeAssignments**: Whether to include group assignments (default: $true)
- **IncludeDevices**: Whether to include device information (default: $true)
- **IncludeGroups**: Whether to include Azure AD group information (default: $true)
- **CompanyName**: Company name to display in the report

## Requirements

- PowerShell 5.1 or higher
- Microsoft Graph PowerShell modules:
  - Microsoft.Graph.Intune
  - Microsoft.Graph.Authentication
  - Microsoft.Graph.Groups
- Appropriate permissions to access Intune data

## Troubleshooting

If you encounter any issues:

1. **Group Detection**: The script attempts multiple methods to find groups with "Intune" in their name. Check the console output for details on groups found.
2. **Assignment Errors**: Some assignments may have unexpected formats. The script now handles these gracefully, including "All Users" and "All Devices" assignments.
3. **API Limitations**: Some Graph API endpoints (like Security Baseline assignments) may return errors depending on your tenant configuration.
4. **ConsistencyLevel Requirements**: The `endswith` filter requires the 'ConsistencyLevel:eventual' header. The script now addresses this. 