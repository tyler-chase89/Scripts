<#
.SYNOPSIS
    Exports Intune configuration to an HTML report.

.DESCRIPTION
    This script connects to Microsoft Graph API, retrieves Intune configuration data,
    and generates a comprehensive HTML report of the Intune environment.

.NOTES
    Author: Technical Writer Auditor
    Version: 1.0
    Requires: Microsoft Graph PowerShell modules

.LINK
    https://learn.microsoft.com/en-us/mem/intune/
    https://learn.microsoft.com/en-us/graph/api/resources/intune-graph-overview
#>

#Requires -Modules Microsoft.Graph.Intune, Microsoft.Graph.Authentication, Microsoft.Graph.Groups

# Parameters
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "$($env:USERPROFILE)\Desktop\IntuneReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html",
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeAssignments = $true,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeDevices = $true,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeGroups = $true,
    
    [Parameter(Mandatory = $false)]
    [string]$CompanyName = ""
)

# Function to check if required modules are installed
function Test-RequiredModules {
    $requiredModules = @("Microsoft.Graph.Intune", "Microsoft.Graph.Authentication", "Microsoft.Graph.Groups")
    $missingModules = @()
    
    foreach ($module in $requiredModules) {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            $missingModules += $module
        }
    }
    
    if ($missingModules.Count -gt 0) {
        Write-Host "The following required modules are missing: $($missingModules -join ', ')" -ForegroundColor Red
        $installModules = Read-Host "Do you want to install them now? (Y/N)"
        
        if ($installModules -eq 'Y') {
            foreach ($module in $missingModules) {
                Write-Host "Installing $module..." -ForegroundColor Yellow
                Install-Module -Name $module -Scope CurrentUser -Force
            }
        } else {
            Write-Host "Required modules are missing. Script cannot continue." -ForegroundColor Red
            exit
        }
    }
}

# Function to connect to Microsoft Graph
function Connect-ToMSGraph {
    try {
        Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
        Connect-MgGraph -Scopes @(
            "DeviceManagementApps.Read.All", 
            "DeviceManagementConfiguration.Read.All", 
            "DeviceManagementManagedDevices.Read.All",
            "Group.Read.All",
            "GroupMember.Read.All",
            "Directory.Read.All"
        )
        Write-Host "Connected to Microsoft Graph successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to connect to Microsoft Graph: $_" -ForegroundColor Red
        exit
    }
}

# Function to get Intune policies
function Get-IntunePolicies {
    Write-Host "Retrieving Intune policies..." -ForegroundColor Yellow
    
    $policies = @{
        "Device Configuration Policies" = Get-MgDeviceManagementDeviceConfiguration
        "Device Compliance Policies" = Get-MgDeviceManagementDeviceCompliancePolicy
        "App Configuration Policies" = Get-MgDeviceAppManagementMobileAppConfiguration
        "App Protection Policies" = Get-MgDeviceAppManagementManagedAppPolicy | Where-Object { $_.AdditionalProperties.'@odata.type' -like '#microsoft.graph.androidManagedAppProtection' -or $_.AdditionalProperties.'@odata.type' -like '#microsoft.graph.iosManagedAppProtection' }
    }
    
    # Add Security baselines
    try {
        $securityBaselines = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/templates?`$filter=templateType eq 'securityBaseline'" 
        if ($securityBaselines.value) {
            $policies["Security Baselines"] = $securityBaselines.value
        }
    }
    catch {
        Write-Host "Error retrieving security baselines: $_" -ForegroundColor Yellow
    }
    
    # Add Windows Autopilot profiles
    try {
        $autopilotProfiles = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeploymentProfiles"
        if ($autopilotProfiles.value) {
            $policies["Windows Autopilot Profiles"] = $autopilotProfiles.value
        }
    }
    catch {
        Write-Host "Error retrieving Windows Autopilot profiles: $_" -ForegroundColor Yellow
    }
    
    # Add Administrative Templates (Group Policy)
    try {
        $adminTemplates = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/groupPolicyConfigurations"
        if ($adminTemplates.value) {
            $policies["Administrative Templates"] = $adminTemplates.value
        }
    }
    catch {
        Write-Host "Error retrieving Administrative Templates: $_" -ForegroundColor Yellow
    }
    
    # Add Enrollment Configurations
    try {
        $enrollmentConfigs = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceEnrollmentConfigurations"
        if ($enrollmentConfigs.value) {
            $policies["Enrollment Configurations"] = $enrollmentConfigs.value
        }
    }
    catch {
        Write-Host "Error retrieving Enrollment Configurations: $_" -ForegroundColor Yellow
    }
    
    # Add Device Categories
    try {
        $deviceCategories = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceCategories"
        if ($deviceCategories.value) {
            $policies["Device Categories"] = $deviceCategories.value
        }
    }
    catch {
        Write-Host "Error retrieving Device Categories: $_" -ForegroundColor Yellow
    }
    
    # Add Terms and Conditions
    try {
        $termsAndConditions = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/termsAndConditions"
        if ($termsAndConditions.value) {
            $policies["Terms and Conditions"] = $termsAndConditions.value
        }
    }
    catch {
        Write-Host "Error retrieving Terms and Conditions: $_" -ForegroundColor Yellow
    }
    
    Write-Host "Retrieved Intune policies successfully." -ForegroundColor Green
    return $policies
}

# Function to get Intune apps
function Get-IntuneApps {
    Write-Host "Retrieving Intune applications..." -ForegroundColor Yellow
    
    try {
        $apps = Get-MgDeviceAppManagementMobileApp
        Write-Host "Retrieved Intune applications successfully." -ForegroundColor Green
        return $apps
    }
    catch {
        Write-Host "Error retrieving Intune applications: $_" -ForegroundColor Red
        return @() # Return an empty array instead of null
    }
}

# Function to get Intune devices if requested
function Get-IntuneDevices {
    if ($IncludeDevices) {
        Write-Host "Retrieving Intune devices (this may take some time)..." -ForegroundColor Yellow
        
        $devices = Get-MgDeviceManagementManagedDevice
        
        Write-Host "Retrieved Intune devices successfully." -ForegroundColor Green
        return $devices
    } else {
        Write-Host "Skipping device retrieval as per parameters." -ForegroundColor Yellow
        return $null
    }
}

# Function to get policy assignments if requested
function Get-PolicyAssignments {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Policy,
        
        [Parameter(Mandatory = $true)]
        [string]$PolicyType,
        
        [Parameter(Mandatory = $false)]
        [ref]$GroupIdsCollector
    )
    
    if ($IncludeAssignments) {
        try {
            $assignments = $null
            
            switch ($PolicyType) {
                "Device Configuration Policies" {
                    $assignments = Get-MgDeviceManagementDeviceConfigurationAssignment -DeviceConfigurationId $Policy.Id
                }
                "Device Compliance Policies" {
                    $assignments = Get-MgDeviceManagementDeviceCompliancePolicyAssignment -DeviceCompliancePolicyId $Policy.Id
                }
                "App Configuration Policies" {
                    $assignments = Get-MgDeviceAppManagementMobileAppConfigurationAssignment -MobileAppConfigurationId $Policy.Id
                }
                "Windows Autopilot Profiles" {
                    $uri = "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeploymentProfiles/$($Policy.id)/assignments"
                    $result = Invoke-MgGraphRequest -Method GET -Uri $uri
                    $assignments = $result.value
                }
                "Administrative Templates" {
                    $uri = "https://graph.microsoft.com/beta/deviceManagement/groupPolicyConfigurations/$($Policy.id)/assignments"
                    $result = Invoke-MgGraphRequest -Method GET -Uri $uri
                    $assignments = $result.value
                }
                "Security Baselines" {
                    # Updated endpoint for security baselines
                    try {
                        $uri = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($Policy.id)/assignments"
                        $result = Invoke-MgGraphRequest -Method GET -Uri $uri
                        $assignments = $result.value
                    }
                    catch {
                        Write-Host "Error retrieving Security Baseline assignments using first method: $_" -ForegroundColor Yellow
                        try {
                            # Fallback to template assignments if first method fails
                            $uri = "https://graph.microsoft.com/beta/deviceManagement/intents/$($Policy.id)/assignments"
                            $result = Invoke-MgGraphRequest -Method GET -Uri $uri
                            $assignments = $result.value
                        }
                        catch {
                            Write-Host "Error retrieving Security Baseline assignments using second method: $_" -ForegroundColor Yellow
                        }
                    }
                }
                "Enrollment Configurations" {
                    $uri = "https://graph.microsoft.com/beta/deviceManagement/deviceEnrollmentConfigurations/$($Policy.id)/assignments"
                    $result = Invoke-MgGraphRequest -Method GET -Uri $uri
                    $assignments = $result.value
                }
                "Terms and Conditions" {
                    $uri = "https://graph.microsoft.com/beta/deviceManagement/termsAndConditions/$($Policy.id)/assignments"
                    $result = Invoke-MgGraphRequest -Method GET -Uri $uri
                    $assignments = $result.value
                }
                default {
                    $assignments = $null
                }
            }
            
            # If we're collecting group IDs and have a valid collector reference
            if ($assignments -and $GroupIdsCollector) {
                foreach ($assignment in $assignments) {
                    try {
                        # Improve error handling for different assignment structures
                        $targetGroupId = $null
                        
                        if ($assignment.Target -and $assignment.Target.AdditionalProperties -and $assignment.Target.AdditionalProperties.ContainsKey('groupId')) {
                            $targetGroupId = $assignment.Target.AdditionalProperties.groupId
                        }
                        elseif ($assignment.target -and $assignment.target.groupId) {
                            $targetGroupId = $assignment.target.groupId
                        }
                        
                        if ($targetGroupId) {
                            # Ensure it's treated as a string
                            if ($targetGroupId -isnot [string]) {
                                $targetGroupId = $targetGroupId.ToString()
                            }
                            
                            $GroupIdsCollector.Value[$targetGroupId] = $true
                        }
                    }
                    catch {
                        Write-Host "Error processing assignment for policy $($Policy.DisplayName): $_" -ForegroundColor Yellow
                    }
                }
            }
            
            return $assignments
        }
        catch {
            Write-Host "Error retrieving assignments for $($Policy.DisplayName): $_" -ForegroundColor Red
            return $null
        }
    }
    
    return $null
}

# Function to get application assignments
function Get-AppAssignments {
    param (
        [Parameter(Mandatory = $true)]
        [object]$App,
        
        [Parameter(Mandatory = $false)]
        [ref]$GroupIdsCollector
    )
    
    if ($IncludeAssignments) {
        try {
            $uri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($App.id)/assignments"
            $result = Invoke-MgGraphRequest -Method GET -Uri $uri
            
            # If we're collecting group IDs and have a valid collector reference
            if ($result.value -and $GroupIdsCollector) {
                foreach ($assignment in $result.value) {
                    $targetGroupId = $assignment.target.groupId
                    if ($targetGroupId) {
                        $GroupIdsCollector.Value[$targetGroupId] = $true
                    }
                }
            }
            
            return $result.value
        }
        catch {
            Write-Host "Error retrieving assignments for app $($App.DisplayName): $_" -ForegroundColor Red
            return $null
        }
    }
    
    return $null
}

# Function to collect all unique group IDs used in Intune assignments
function Get-IntuneAssignmentGroupIds {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Policies,
        
        [Parameter(Mandatory = $true)]
        [object]$Apps
    )
    
    Write-Host "Collecting group IDs used in Intune assignments..." -ForegroundColor Yellow
    
    # Create a hashtable to store unique group IDs
    $uniqueGroupIds = @{}
    
    # Process all policies
    foreach ($policyType in $Policies.Keys) {
        if ($Policies[$policyType] -ne $null) {
            foreach ($policy in $Policies[$policyType]) {
                Get-PolicyAssignments -Policy $policy -PolicyType $policyType -GroupIdsCollector ([ref]$uniqueGroupIds) | Out-Null
            }
        }
    }
    
    # Process all apps
    if ($Apps -ne $null) {
        foreach ($app in $Apps) {
            Get-AppAssignments -App $app -GroupIdsCollector ([ref]$uniqueGroupIds) | Out-Null
        }
    }
    
    $groupIds = $uniqueGroupIds.Keys
    Write-Host "Found $($groupIds.Count) unique groups used in Intune assignments." -ForegroundColor Green
    
    return $groupIds
}

# Function to get Azure AD Groups if requested
function Get-AzureADGroups {
    if ($IncludeGroups) {
        Write-Host "Retrieving Azure AD Groups used in Intune..." -ForegroundColor Yellow
        
        try {
            # Initialize an array to hold all groups
            $groups = @()
            
            # Get all unique group IDs used in assignments
            $groupIds = $global:IntuneAssignmentGroupIds
            
            if ($groupIds.Count -gt 0) {
                Write-Host "Found $($groupIds.Count) unique groups used in Intune assignments." -ForegroundColor Green
                
                # Process assignment groups in batches to avoid potential API limitations
                $batchSize = 20
                for ($i = 0; $i -lt $groupIds.Count; $i += $batchSize) {
                    $batchIds = $groupIds | Select-Object -Skip $i -First $batchSize
                    
                    foreach ($groupId in $batchIds) {
                        try {
                            $group = Get-MgGroup -GroupId $groupId
                            if ($group) {
                                # Add a property to indicate this group is assigned to Intune policy/app
                                $group | Add-Member -NotePropertyName "AssignedToIntunePolicy" -NotePropertyValue $true -Force
                                $groups += $group
                            }
                        }
                        catch {
                            Write-Host "Error retrieving group $groupId : $_" -ForegroundColor Yellow
                        }
                    }
                }
            }
            else {
                Write-Host "No Azure AD Groups found in Intune assignments." -ForegroundColor Yellow
            }
            
            # Also search for groups with "Intune" in the name - using two different approaches for thoroughness
            Write-Host "Searching for groups with 'Intune' in their name..." -ForegroundColor Yellow
            
            try {
                # First approach: Using startswith filter only (contains is not supported)
                $intuneNamedGroups = Get-MgGroup -Filter "startswith(displayName,'Intune')" -All
                
                if ($intuneNamedGroups.Count -gt 0) {
                    Write-Host "Found $($intuneNamedGroups.Count) groups with 'Intune' in their name using filter." -ForegroundColor Green
                    
                    foreach ($intuneGroup in $intuneNamedGroups) {
                        # Check if this group is already in our list (from assignments)
                        $existingGroup = $groups | Where-Object { $_.Id -eq $intuneGroup.Id }
                        if (-not $existingGroup) {
                            # Add a property to indicate this group was included due to naming
                            $intuneGroup | Add-Member -NotePropertyName "AssignedToIntunePolicy" -NotePropertyValue $false -Force
                            $groups += $intuneGroup
                        }
                    }
                }
            }
            catch {
                Write-Host "Error in first method of searching for groups with 'Intune' in their name: $_" -ForegroundColor Yellow
                # Continue to the next method
            }
            
            # Second approach: Get all groups and filter locally
            # This is a fallback in case the Graph API filter doesn't work as expected
            try {
                Write-Host "Using alternative method to find groups with 'Intune' in their name..." -ForegroundColor Yellow
                
                # Get all groups in the tenant, but limit to first 999 to avoid performance issues
                # Adjust this number based on your environment size
                $allGroups = Get-MgGroup -Top 999
                
                # Filter locally for groups with "Intune" in their name (case-insensitive)
                $localFilteredGroups = $allGroups | Where-Object { 
                    $_.DisplayName -match "Intune" 
                }
                
                $newGroupsCount = 0
                
                if ($localFilteredGroups.Count -gt 0) {
                    foreach ($localGroup in $localFilteredGroups) {
                        # Check if this group is already in our list
                        $existingGroup = $groups | Where-Object { $_.Id -eq $localGroup.Id }
                        if (-not $existingGroup) {
                            # Add a property to indicate this group was included due to naming
                            $localGroup | Add-Member -NotePropertyName "AssignedToIntunePolicy" -NotePropertyValue $false -Force
                            $groups += $localGroup
                            $newGroupsCount++
                        }
                    }
                    
                    Write-Host "Found $newGroupsCount additional groups with 'Intune' in their name using local filtering." -ForegroundColor Green
                }
            }
            catch {
                Write-Host "Error in second method of searching for groups with 'Intune' in their name: $_" -ForegroundColor Yellow
            }
            
            Write-Host "Retrieved $($groups.Count) Azure AD Groups related to Intune in total." -ForegroundColor Green
            return $groups
        }
        catch {
            Write-Host "Error retrieving Azure AD Groups: $_" -ForegroundColor Red
            return @()
        }
    } else {
        Write-Host "Skipping Azure AD Groups retrieval as per parameters." -ForegroundColor Yellow
        return $null
    }
}

# Function to resolve group IDs to names
function Resolve-GroupName {
    param (
        [Parameter(Mandatory = $true)]
        [string]$GroupId,
        
        [Parameter(Mandatory = $false)]
        [object]$Groups
    )
    
    if ($IncludeGroups -and $Groups) {
        $group = $Groups | Where-Object { $_.Id -eq $GroupId }
        if ($group) {
            return $group.DisplayName
        }
    }
    
    return "Group: $GroupId"
}

# Function to generate HTML report
function Generate-HtmlReport {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Policies,
        
        [Parameter(Mandatory = $false)]
        [object]$Apps = @(),
        
        [Parameter(Mandatory = $false)]
        [object]$Devices,
        
        [Parameter(Mandatory = $false)]
        [object]$Groups
    )
    
    Write-Host "Generating HTML report..." -ForegroundColor Yellow
    
    # HTML header with CSS styling
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Intune Environment Report</title>
    <style>
        :root {
            --primary-color: #6200ee;
            --device-color: #2979ff;
            --compliance-color: #00c853;
            --app-color: #f50057;
            --group-color: #ff6d00;
            --security-color: #aa00ff;
            --device-light: #e3f2fd;
            --compliance-light: #e8f5e9;
            --app-light: #fce4ec;
            --group-light: #fff3e0;
            --security-light: #f3e5f5;
        }
        body {
            font-family: 'Segoe UI', 'Roboto', sans-serif;
            margin: 0;
            padding: 0;
            color: #333;
            background-color: #f5f5f5;
            line-height: 1.6;
        }
        .container {
            display: flex;
            flex-direction: row;
        }
        .sidebar {
            width: 250px;
            background-color: var(--primary-color);
            background-image: linear-gradient(45deg, var(--primary-color), #7c4dff);
            color: white;
            position: fixed;
            height: 100vh;
            overflow-y: auto;
            padding: 0;
            box-shadow: 2px 0 10px rgba(0,0,0,0.2);
        }
        .sidebar h2 {
            padding: 20px;
            margin: 0;
            font-size: 18px;
            background-color: rgba(0,0,0,0.2);
            font-weight: 500;
            letter-spacing: 0.5px;
        }
        .sidebar ul {
            list-style-type: none;
            padding: 10px 0;
            margin: 0;
        }
        .sidebar ul li {
            padding: 0;
            margin: 5px 0;
        }
        .sidebar ul li a {
            color: white;
            text-decoration: none;
            display: block;
            padding: 10px 20px;
            margin: 0 5px;
            border-radius: 5px;
            transition: all 0.2s ease;
        }
        .sidebar ul li a:hover {
            background-color: rgba(255,255,255,0.2);
            transform: translateX(5px);
        }
        .content {
            margin-left: 250px;
            padding: 25px;
            width: calc(100% - 250px);
            box-sizing: border-box;
        }
        .content-inner {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            border-radius: 10px;
        }
        h1 {
            color: var(--primary-color);
            border-bottom: 3px solid var(--primary-color);
            padding-bottom: 15px;
            margin-top: 0;
            font-weight: 500;
            font-size: 28px;
        }
        h2 {
            margin-top: 30px;
            padding: 12px 15px;
            border-radius: 5px;
            font-weight: 500;
            font-size: 20px;
            color: white;
        }
        /* Color-coded headers */
        #Device-Configuration-Policies h2 {
            background-color: var(--device-color);
        }
        #Device-Compliance-Policies h2 {
            background-color: var(--compliance-color);
        }
        #App-Configuration-Policies h2, #App-Protection-Policies h2, #applications h2 {
            background-color: var(--app-color);
        }
        #Security-Baselines h2 {
            background-color: var(--security-color);
        }
        #groups h2 {
            background-color: var(--group-color);
        }
        #devices h2 {
            background-color: var(--device-color);
        }
        #summary h2 {
            background-color: var(--primary-color);
        }
        
        h3 {
            color: var(--primary-color);
            margin-top: 20px;
            font-weight: 500;
            font-size: 18px;
        }
        table {
            width: 100%;
            border-collapse: separate;
            border-spacing: 0;
            margin-bottom: 25px;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 1px 5px rgba(0,0,0,0.1);
        }
        th, td {
            border: none;
            padding: 12px 15px;
            text-align: left;
        }
        th {
            color: white;
            font-weight: 500;
        }
        /* Color-coded tables */
        #Device-Configuration-Policies th {
            background-color: var(--device-color);
        }
        #Device-Configuration-Policies tr:nth-child(even) {
            background-color: var(--device-light);
        }
        #Device-Compliance-Policies th {
            background-color: var(--compliance-color);
        }
        #Device-Compliance-Policies tr:nth-child(even) {
            background-color: var(--compliance-light);
        }
        #App-Configuration-Policies th, #App-Protection-Policies th, #applications th {
            background-color: var(--app-color);
        }
        #App-Configuration-Policies tr:nth-child(even), #App-Protection-Policies tr:nth-child(even), #applications tr:nth-child(even) {
            background-color: var(--app-light);
        }
        #Security-Baselines th {
            background-color: var(--security-color);
        }
        #Security-Baselines tr:nth-child(even) {
            background-color: var(--security-light);
        }
        #groups th {
            background-color: var(--group-color);
        }
        #groups tr:nth-child(even) {
            background-color: var(--group-light);
        }
        #devices th {
            background-color: var(--device-color);
        }
        #devices tr:nth-child(even) {
            background-color: var(--device-light);
        }
        #summary th {
            background-color: var(--primary-color);
        }
        
        tr {
            border-bottom: 1px solid #eee;
        }
        tr:last-child {
            border-bottom: none;
        }
        
        .timestamp {
            font-style: italic;
            color: #777;
            margin-bottom: 25px;
            text-align: right;
            font-size: 14px;
        }
        .section {
            margin-bottom: 35px;
            scroll-margin-top: 20px;
            border-radius: 10px;
            overflow: hidden;
        }
        .policy-details {
            margin-left: 20px;
            margin-bottom: 20px;
        }
        .alert {
            background-color: #ffebee;
            border-left: 4px solid #f44336;
            padding: 15px;
            margin-bottom: 20px;
            color: #b71c1c;
            border-radius: 4px;
        }
        .collapsible {
            background-color: #f5f5f5;
            color: #555;
            cursor: pointer;
            padding: 10px 15px;
            width: 100%;
            border: none;
            text-align: left;
            outline: none;
            font-size: 13px;
            border-radius: 4px;
            margin: 5px 0;
            display: flex;
            justify-content: space-between;
            align-items: center;
            transition: all 0.3s;
        }
        .collapsible:hover {
            background-color: #eee;
        }
        .collapsible:before {
            content: "+";
            color: #777;
            font-weight: bold;
            font-size: 14px;
            margin-right: 10px;
        }
        .active {
            background-color: #eee;
        }
        .active:before {
            content: "-";
        }
        .collapsible-content {
            padding: 0;
            max-height: 0;
            overflow: hidden;
            transition: max-height 0.3s ease-out;
            background-color: #fff;
            border-radius: 0 0 4px 4px;
            margin-bottom: 5px;
            border: 1px solid #eee;
            border-top: none;
        }
        .policy-details {
            padding: 15px;
            margin: 0;
        }
        .policy-details ul {
            margin: 0;
            padding-left: 20px;
        }
        .policy-details li {
            margin-bottom: 5px;
            padding: 3px 0;
            font-size: 13px;
        }
        .policy-name {
            font-weight: 500;
            font-size: 15px;
            color: var(--primary-color);
        }
        .company-name {
            color: #555;
            font-size: 18px;
            margin-bottom: 5px;
        }
        a {
            color: var(--primary-color);
            text-decoration: none;
            transition: all 0.2s ease;
        }
        a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="container">
        <nav class="sidebar">
            <h2>Contents</h2>
            <ul>
                <li><a href="#summary">Summary</a></li>
"@

    # Add sidebar navigation links for each section
    foreach ($policyType in $Policies.Keys) {
        $sectionId = $policyType -replace '\s+', '-' -replace '[^\w\-]', ''
        $html += "<li><a href='#$sectionId'>$policyType</a></li>`n"
    }
    
    $html += "<li><a href='#applications'>Applications</a></li>`n"
    
    if ($IncludeDevices) {
        $html += "<li><a href='#devices'>Managed Devices</a></li>`n"
    }
    
    if ($IncludeGroups -and $Groups -and $Groups.Count -gt 0) {
        $html += "<li><a href='#groups'>Azure AD Groups</a></li>`n"
    }
    
    $html += @"
            </ul>
        </nav>
        <div class="content">
            <div class="content-inner">
"@

    # Add company name to the title if provided
    if (-not [string]::IsNullOrWhiteSpace($CompanyName)) {
        $html += @"
                <h1>$CompanyName - Intune Environment Report</h1>
"@
    }
    else {
        $html += @"
                <h1>Intune Environment Report</h1>
"@
    }

    # Remove the separate company name div since we're now including it in the h1
    $html += @"
                <div class="timestamp">Generated on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</div>
"@

    # Summary section
    $html += @"
                <div id="summary" class="section">
                    <h2>Summary</h2>
                    <table>
                        <tr>
                            <th>Category</th>
                            <th>Count</th>
                        </tr>
"@

    # Add policy counts
    foreach ($policyType in $Policies.Keys) {
        $count = if ($Policies[$policyType] -eq $null) { 0 } else { $Policies[$policyType].Count }
        $html += @"
                        <tr>
                            <td>$policyType</td>
                            <td>$count</td>
                        </tr>
"@
    }

    # Add app counts (handle null case)
    $appCount = if ($Apps -eq $null) { 0 } else { $Apps.Count }
    $html += @"
                        <tr>
                            <td>Applications</td>
                            <td>$appCount</td>
                        </tr>
"@

    # Add device counts if requested
    if ($IncludeDevices) {
        $deviceCount = if ($Devices -eq $null) { 0 } else { $Devices.Count }
        $html += @"
                        <tr>
                            <td>Managed Devices</td>
                            <td>$deviceCount</td>
                        </tr>
"@
    }
    
    # Add groups count if requested
    if ($IncludeGroups -and $Groups) {
        $groupCount = if ($Groups -eq $null) { 0 } else { $Groups.Count }
        $html += @"
                        <tr>
                            <td>Azure AD Groups</td>
                            <td>$groupCount</td>
                        </tr>
"@
    }

    $html += @"
                    </table>
                </div>
"@

    # Policies sections
    foreach ($policyType in $Policies.Keys) {
        $sectionId = $policyType -replace '\s+', '-' -replace '[^\w\-]', ''
        $html += @"
                <div id="$sectionId" class="section">
                    <h2>$policyType</h2>
"@
        
        if ($Policies[$policyType] -eq $null -or $Policies[$policyType].Count -eq 0) {
            $html += @"
                    <div class="alert">
                        No $policyType found in this Intune environment.
                    </div>
"@
        } else {
            $html += @"
                    <table>
                        <tr>
                            <th>Name</th>
                            <th>Description</th>
                            <th>Created</th>
                            <th>Last Modified</th>
                        </tr>
"@

            foreach ($policy in $Policies[$policyType]) {
                $html += @"
                        <tr>
                            <td class="policy-name">$($policy.DisplayName)</td>
                            <td>$($policy.Description)</td>
                            <td>$($policy.CreatedDateTime)</td>
                            <td>$($policy.LastModifiedDateTime)</td>
                        </tr>
"@

                if ($IncludeAssignments) {
                    $assignments = Get-PolicyAssignments -Policy $policy -PolicyType $policyType -GroupIdsCollector ([ref]$global:IntuneAssignmentGroupIds)
                    
                    if ($assignments -and $assignments.Count -gt 0) {
                        $html += @"
                        <tr>
                            <td colspan="4">
                                <button class="collapsible">Assignments</button>
                                <div class="collapsible-content">
                                    <div class="policy-details">
                                        <ul>
"@
                        foreach ($assignment in $assignments) {
                            $targetGroupId = $assignment.Target.AdditionalProperties.groupId
                            if ($targetGroupId) {
                                $groupName = Resolve-GroupName -GroupId $targetGroupId -Groups $Groups
                                $html += "<li>$groupName</li>"
                            }
                            else {
                                $targetType = if ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.allDevicesAssignmentTarget') {
                                    "All Devices"
                                }
                                elseif ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.allUsersAssignmentTarget') {
                                    "All Users"
                                }
                                else {
                                    "Unknown Target Type"
                                }
                                
                                $html += "<li>$targetType</li>"
                            }
                        }
                        
                        $html += @"
                                        </ul>
                                    </div>
                                </div>
                            </td>
                        </tr>
"@
                    }
                }
            }
            
            $html += "</table>"
        }
        
        $html += "</div>"
    }

    # Applications section
    $html += @"
                <div id="applications" class="section">
                    <h2>Applications</h2>
"@

    if ($Apps -eq $null -or $Apps.Count -eq 0) {
        $html += @"
                    <div class="alert">
                        No applications found in this Intune environment.
                    </div>
"@
    } else {
        $html += @"
                    <table>
                        <tr>
                            <th>Name</th>
                            <th>Publisher</th>
                            <th>Type</th>
                            <th>Created</th>
                        </tr>
"@

        foreach ($app in $Apps) {
            $appType = $app.AdditionalProperties.'@odata.type' -replace '#microsoft.graph.', ''
            
            $html += @"
                        <tr>
                            <td class="policy-name">$($app.DisplayName)</td>
                            <td>$($app.Publisher)</td>
                            <td>$appType</td>
                            <td>$($app.CreatedDateTime)</td>
                        </tr>
"@

            if ($IncludeAssignments) {
                $appAssignments = Get-AppAssignments -App $app -GroupIdsCollector ([ref]$global:IntuneAssignmentGroupIds)
                
                if ($appAssignments -and $appAssignments.Count -gt 0) {
                    $html += @"
                        <tr>
                            <td colspan="4">
                                <button class="collapsible">Assignments</button>
                                <div class="collapsible-content">
                                    <div class="policy-details">
                                        <ul>
"@
                    foreach ($assignment in $appAssignments) {
                        $targetGroupId = $assignment.target.groupId
                        $intent = $assignment.intent
                        
                        if ($targetGroupId) {
                            $groupName = Resolve-GroupName -GroupId $targetGroupId -Groups $Groups
                            $html += "<li>$groupName - Intent: $intent</li>"
                        }
                        else {
                            $targetType = if ($assignment.target.'@odata.type' -eq '#microsoft.graph.allDevicesAssignmentTarget') {
                                "All Devices"
                            }
                            elseif ($assignment.target.'@odata.type' -eq '#microsoft.graph.allUsersAssignmentTarget') {
                                "All Users"
                            }
                            else {
                                "Unknown Target Type"
                            }
                            
                            $html += "<li>$targetType - Intent: $intent</li>"
                        }
                    }
                    
                    $html += @"
                                        </ul>
                                    </div>
                                </div>
                            </td>
                        </tr>
"@
                }
            }
        }
        
        $html += "</table>"
    }
    
    $html += "</div>"

    # Devices section
    if ($IncludeDevices) {
        $html += @"
                <div id="devices" class="section">
                    <h2>Managed Devices</h2>
"@

        if ($Devices -eq $null -or $Devices.Count -eq 0) {
            $html += @"
                    <div class="alert">
                        No managed devices found in this Intune environment.
                    </div>
"@
        } else {
            $html += @"
                    <table>
                        <tr>
                            <th>Device Name</th>
                            <th>OS</th>
                            <th>OS Version</th>
                            <th>Ownership</th>
                            <th>Compliance</th>
                            <th>Last Sync</th>
                        </tr>
"@

            foreach ($device in $Devices) {
                $complianceState = if ($device.ComplianceState -eq 'compliant') {
                    "Compliant"
                } elseif ($device.ComplianceState -eq 'noncompliant') {
                    "Non-compliant"
                } else {
                    $device.ComplianceState
                }
                
                $ownership = if ($device.ManagedDeviceOwnerType -eq 'company') {
                    "Corporate"
                } elseif ($device.ManagedDeviceOwnerType -eq 'personal') {
                    "Personal"
                } else {
                    $device.ManagedDeviceOwnerType
                }
                
                $html += @"
                        <tr>
                            <td>$($device.DeviceName)</td>
                            <td>$($device.OperatingSystem)</td>
                            <td>$($device.OsVersion)</td>
                            <td>$ownership</td>
                            <td>$complianceState</td>
                            <td>$($device.LastSyncDateTime)</td>
                        </tr>
"@
            }
            
            $html += "</table>"
        }
        
        $html += "</div>"
    }

    # Groups section
    if ($IncludeGroups -and $Groups -and $Groups.Count -gt 0) {
        $html += @"
                <div id="groups" class="section">
                    <h2>Intune-Related Azure AD Groups</h2>
                    <p>This section includes groups assigned to Intune policies/apps and groups with "Intune" in their name.</p>
                    <table>
                        <tr>
                            <th>Group Name</th>
                            <th>Group ID</th>
                            <th>Description</th>
                            <th>Type</th>
                            <th>Assignment Status</th>
                        </tr>
"@

        foreach ($group in $Groups) {
            $assignmentStatus = if ($group.AssignedToIntunePolicy) { "Assigned to policy/app" } else { "Not assigned (named match)" }
            
            $html += @"
                        <tr>
                            <td>$($group.DisplayName)</td>
                            <td>$($group.Id)</td>
                            <td>$($group.Description)</td>
                            <td>$($group.GroupTypes -join ', ')</td>
                            <td>$assignmentStatus</td>
                        </tr>
"@
        }
        
        $html += "</table></div>"
    }

    # HTML footer with JavaScript for collapsible sections
    $html += @"
                <div class="section">
                    <h2>References</h2>
                    <ul>
                        <li><a href="https://learn.microsoft.com/en-us/mem/intune/" target="_blank">Microsoft Intune Documentation</a></li>
                        <li><a href="https://learn.microsoft.com/en-us/graph/api/resources/intune-graph-overview" target="_blank">Microsoft Graph API for Intune</a></li>
                    </ul>
                </div>
                <div class="section">
                    <h2>Errors and Limitations</h2>
                    <p>This report may have the following limitations:</p>
                    <ul>
                        <li>Some Security Baseline assignments may not be displayed due to API limitations</li>
                        <li>Some group assignments may not be fully retrieved due to varying data structures</li>
                        <li>Groups with "Intune" in their name (but not at the start) are found using local filtering rather than API filtering</li>
                    </ul>
                    <p>These limitations are due to Microsoft Graph API constraints and do not affect the accuracy of the data shown.</p>
                </div>
            </div>
        </div>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function() {
            var coll = document.getElementsByClassName("collapsible");
            for (var i = 0; i < coll.length; i++) {
                coll[i].addEventListener("click", function() {
                    this.classList.toggle("active");
                    var content = this.nextElementSibling;
                    if (content.style.maxHeight) {
                        content.style.maxHeight = null;
                    } else {
                        content.style.maxHeight = content.scrollHeight + "px";
                    }
                });
            }
        });
    </script>
</body>
</html>
"@

    return $html
}

# Main script execution
try {
    # Check for required modules
    Test-RequiredModules
    
    # Prompt for company name if not provided
    if ([string]::IsNullOrWhiteSpace($CompanyName)) {
        $CompanyName = Read-Host "Enter company name for the report (leave blank for generic report)"
    }
    
    # Connect to Microsoft Graph
    Connect-ToMSGraph
    
    # Get Intune data with error handling
    try {
        $policies = Get-IntunePolicies
        if ($policies -eq $null) {
            $policies = @{} # Empty hashtable if null
            Write-Host "Warning: No policies were retrieved." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Error retrieving policies: $_" -ForegroundColor Red
        $policies = @{} # Empty hashtable on error
    }
    
    try {
        $apps = Get-IntuneApps
        if ($apps -eq $null) {
            $apps = @() # Empty array if null
            Write-Host "Warning: No applications were retrieved." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Error retrieving applications: $_" -ForegroundColor Red
        $apps = @() # Empty array on error
    }
    
    # Collect all unique group IDs used in Intune assignments before retrieving groups
    if ($IncludeAssignments -and $IncludeGroups) {
        $global:IntuneAssignmentGroupIds = Get-IntuneAssignmentGroupIds -Policies $policies -Apps $apps
    } else {
        $global:IntuneAssignmentGroupIds = @()
    }
    
    try {
        $groups = Get-AzureADGroups
        if ($groups -eq $null -and $IncludeGroups) {
            $groups = @() # Empty array if null
            Write-Host "Warning: No Azure AD Groups were retrieved." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Error retrieving Azure AD Groups: $_" -ForegroundColor Red
        $groups = @() # Empty array on error
    }
    
    try {
        $devices = Get-IntuneDevices
        if ($devices -eq $null -and $IncludeDevices) {
            $devices = @() # Empty array if null
            Write-Host "Warning: No devices were retrieved." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Error retrieving devices: $_" -ForegroundColor Red
        $devices = @() # Empty array on error
    }
    
    # Generate HTML report with error handling
    $htmlReport = Generate-HtmlReport -Policies $policies -Apps $apps -Devices $devices -Groups $groups
    
    # Save the report
    $htmlReport | Out-File -FilePath $OutputPath -Encoding UTF8
    
    Write-Host "Report generated successfully at: $OutputPath" -ForegroundColor Green
    
    # Open the report
    $openReport = Read-Host "Do you want to open the report now? (Y/N)"
    if ($openReport -eq 'Y') {
        Start-Process $OutputPath
    }
}
catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}
finally {
    # Disconnect from Microsoft Graph
    Disconnect-MgGraph -ErrorAction SilentlyContinue
    # Clean up global variable
    Remove-Variable -Name IntuneAssignmentGroupIds -Scope Global -ErrorAction SilentlyContinue
}
