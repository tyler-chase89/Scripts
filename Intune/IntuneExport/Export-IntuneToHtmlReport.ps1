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
    [string]$StyleVariant = "Default",
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeAssignments = $true,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeDevices = $true,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeGroups = $true,
    
    [Parameter(Mandatory = $false)]
    [string]$CompanyName = ""
)

# Handle style variants - this is the added code
if ($StyleVariant -ne "Default") {
    # Try to load the selected style variant
    $styleVariantPath = Join-Path -Path $PSScriptRoot -ChildPath "StyleVariants\Style$StyleVariant.ps1"
    $alternateStyleVariantPath = Join-Path -Path $PSScriptRoot -ChildPath "StyleVariants\$StyleVariant.ps1"
    
    if (Test-Path -Path $styleVariantPath) {
        Write-Host "Loading style variant: $StyleVariant" -ForegroundColor Green
        # Dot source the style variant script
        . $styleVariantPath
        # Exit the current script because the style variant will take over
        exit
    }
    elseif (Test-Path -Path $alternateStyleVariantPath) {
        Write-Host "Loading style variant: $StyleVariant" -ForegroundColor Green
        # Dot source the style variant script
        . $alternateStyleVariantPath
        # Exit the current script because the style variant will take over
        exit
    }
    else {
        Write-Host "Style variant '$StyleVariant' not found. Using default style." -ForegroundColor Yellow
        # Continue with the default style
    }
}

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
    
    # Add Targeted App Configuration Policies (managed app configs)
    try {
        Write-Host "Retrieving Targeted App Configuration Policies..." -ForegroundColor Yellow
        $targetedAppConfigs = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceAppManagement/targetedManagedAppConfigurations"
        if ($targetedAppConfigs.value) {
            $policies["Targeted App Configuration Policies"] = $targetedAppConfigs.value
            Write-Host "Retrieved $($targetedAppConfigs.value.Count) Targeted App Configuration Policies." -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Error retrieving Targeted App Configuration Policies: $_" -ForegroundColor Yellow
    }
    
    # Add iOS App Configuration Policies 
    try {
        Write-Host "Retrieving iOS App Configuration Policies..." -ForegroundColor Yellow
        $iosAppConfigs = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceAppManagement/iosAppProvisioningProfiles"
        if ($iosAppConfigs.value) {
            $policies["iOS App Provisioning Profiles"] = $iosAppConfigs.value
            Write-Host "Retrieved $($iosAppConfigs.value.Count) iOS App Provisioning Profiles." -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Error retrieving iOS App Provisioning Profiles: $_" -ForegroundColor Yellow
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
                "Targeted App Configuration Policies" {
                    $uri = "https://graph.microsoft.com/beta/deviceAppManagement/targetedManagedAppConfigurations/$($Policy.id)/assignments"
                    $result = Invoke-MgGraphRequest -Method GET -Uri $uri
                    $assignments = $result.value
                }
                "iOS App Provisioning Profiles" {
                    $uri = "https://graph.microsoft.com/beta/deviceAppManagement/iosAppProvisioningProfiles/$($Policy.id)/assignments"
                    $result = Invoke-MgGraphRequest -Method GET -Uri $uri
                    $assignments = $result.value
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
                        # Skip if assignment.Target is not an object
                        if ($assignment.Target -isnot [object] -or $assignment.Target -is [string]) {
                            continue
                        }
                        
                        # Extract group ID from different possible structures
                        $targetGroupId = $null
                        
                        if ($assignment.Target -and $assignment.Target.AdditionalProperties -and 
                            $assignment.Target.AdditionalProperties.ContainsKey('groupId')) {
                            $targetGroupId = $assignment.Target.AdditionalProperties.groupId
                        }
                        elseif ($assignment.target -and $assignment.target.groupId) {
                            $targetGroupId = $assignment.target.groupId
                        }
                        
                        # Add to collector if we found a valid group ID
                        if ($targetGroupId) {
                            $targetGroupIdString = $targetGroupId.ToString()
                            $GroupIdsCollector.Value[$targetGroupIdString] = $true
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
                    try {
                        # Skip if target is not an object
                        if ($assignment.target -isnot [object] -or $assignment.target -is [string]) {
                            continue
                        }
                        
                        # Extract group ID
                        $targetGroupId = $null
                        if ($assignment.target -and $assignment.target.groupId) {
                            $targetGroupId = $assignment.target.groupId
                            
                            # Add to collector if we found a valid group ID
                            if ($targetGroupId) {
                                $targetGroupIdString = $targetGroupId.ToString()
                                $GroupIdsCollector.Value[$targetGroupIdString] = $true
                            }
                        }
                    }
                    catch {
                        Write-Host "Error processing assignment for app $($App.DisplayName): $_" -ForegroundColor Yellow
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
            
            # Search for groups with "Intune" in the name using multiple approaches for thoroughness
            Write-Host "Searching for groups with 'Intune' in their name..." -ForegroundColor Yellow
            
            # Approach 1: Using startswith and endswith filters
            try {
                Write-Host "Method 1: Using startswith/endswith filter..." -ForegroundColor Yellow
                # First try using startswith filter
                $startWithGroups = Get-MgGroup -Filter "startswith(displayName,'Intune')" -All
                Write-Host "  - Found $($startWithGroups.Count) groups that start with 'Intune'" -ForegroundColor Green
                
                # Then try using endswith filter with the required ConsistencyLevel header
                try {
                    $endWithGroups = @()
                    $pageSize = 100
                    $skipToken = $null

                    Write-Host "  - Attempting to find groups ending with 'Intune' (with ConsistencyLevel)..." -ForegroundColor Yellow
                    do {
                        $headers = @{
                            'ConsistencyLevel' = 'eventual'
                        }
                        
                        $params = @{
                            'PageSize' = $pageSize
                            'Headers' = $headers
                            'Filter' = "endswith(displayName,'Intune')"
                        }
                        
                        if ($skipToken) {
                            $params['Skip'] = $skipToken
                        }
                        
                        $result = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups" -Headers $headers -OutputType PSObject -QueryParameters @{'$filter' = "endswith(displayName,'Intune')"; '$count' = 'true'; '$top' = $pageSize}
                        if ($result.value) {
                            $endWithGroups += $result.value
                        }
                        
                        # Get the skipToken if there are more results
                        $skipToken = $null
                        if ($result.'@odata.nextLink') {
                            $skipToken = $result.'@odata.nextLink'
                        }
                    } while ($skipToken)
                    
                    Write-Host "  - Found $($endWithGroups.Count) groups that end with 'Intune'" -ForegroundColor Green
                } 
                catch {
                    Write-Host "  - Error finding groups that end with 'Intune': $_" -ForegroundColor Yellow
                    $endWithGroups = @()
                }
                
                $intuneNamedGroups = $startWithGroups + $endWithGroups
                
                if ($intuneNamedGroups.Count -gt 0) {
                    Write-Host "Found $($intuneNamedGroups.Count) groups with 'Intune' at start/end using filters." -ForegroundColor Green
                    
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
            
            # Approach 2: Get all groups and filter locally (comprehensive approach)
            try {
                Write-Host "Method 2: Using comprehensive local filtering..." -ForegroundColor Yellow
                
                # Get all groups in the tenant, but use paging to handle large environments
                Write-Host "  - Retrieving groups in batches..." -ForegroundColor Yellow
                $allGroups = @()
                $pageSize = 100
                $skipToken = $null
                $foundGroups = 0
                $maxGroups = 2000 # Limit to avoid performance issues in very large tenants
                
                do {
                    $params = @{
                        'PageSize' = $pageSize
                    }
                    
                    if ($skipToken) {
                        $params['Skip'] = $skipToken
                    }
                    
                    $groupBatch = Get-MgGroup @params -All
                    $allGroups += $groupBatch
                    $foundGroups += $groupBatch.Count
                    
                    # For very large tenants, stop after retrieving maxGroups
                    if ($foundGroups -ge $maxGroups) {
                        Write-Host "  - Reached limit of $maxGroups groups, stopping retrieval" -ForegroundColor Yellow
                        break
                    }
                    
                    # Get the skipToken for the next page if available
                    $skipToken = $groupBatch.SkipToken
                } while ($skipToken)
                
                Write-Host "  - Retrieved $($allGroups.Count) total groups for local filtering" -ForegroundColor Green
                
                # Filter locally for groups with "Intune" in their name (case-insensitive)
                $localFilteredGroups = $allGroups | Where-Object { 
                    $_.DisplayName -match "Intune" 
                }
                
                Write-Host "  - Found $($localFilteredGroups.Count) groups with 'Intune' anywhere in name" -ForegroundColor Green
                
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
                            Write-Host "    - Added: $($localGroup.DisplayName)" -ForegroundColor Green
                        }
                    }
                    
                    Write-Host "  - Added $newGroupsCount additional groups using local filtering" -ForegroundColor Green
                }
            }
            catch {
                Write-Host "Error in second method of searching for groups with 'Intune' in their name: $_" -ForegroundColor Yellow
            }
            
            # Approach 3: Use a simpler query with minimal filtering if previous methods failed to find many groups
            if ($groups.Count -lt 10) {
                try {
                    Write-Host "Method 3: Using simple search as fallback..." -ForegroundColor Yellow
                    # Get groups with simpler filtering
                    $simpleGroups = Get-MgGroup -Top 999 -Property Id,DisplayName,Description,GroupTypes
                    
                    # Filter locally with simple string contains
                    $simpleFilteredGroups = $simpleGroups | Where-Object { 
                        $_.DisplayName -and $_.DisplayName.ToLower().Contains("intune") 
                    }
                    
                    Write-Host "  - Found $($simpleFilteredGroups.Count) groups with simple filtering" -ForegroundColor Green
                    
                    if ($simpleFilteredGroups.Count -gt 0) {
                        foreach ($simpleGroup in $simpleFilteredGroups) {
                            # Check if this group is already in our list
                            $existingGroup = $groups | Where-Object { $_.Id -eq $simpleGroup.Id }
                            if (-not $existingGroup) {
                                # Add a property to indicate this group was included due to naming
                                $simpleGroup | Add-Member -NotePropertyName "AssignedToIntunePolicy" -NotePropertyValue $false -Force
                                $groups += $simpleGroup
                                Write-Host "    - Added: $($simpleGroup.DisplayName)" -ForegroundColor Green
                            }
                        }
                    }
                }
                catch {
                    Write-Host "Error in third method of searching for groups: $_" -ForegroundColor Yellow
                }
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
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 0;
            color: #333;
            background-color: #f5f5f5;
        }
        .container {
            display: flex;
            flex-direction: row;
        }
        .sidebar {
            width: 250px;
            background-color: #0078d4;
            color: white;
            position: fixed;
            height: 100vh;
            overflow-y: auto;
            padding: 20px 0;
        }
        .sidebar h2 {
            padding: 0 20px;
            margin: 20px 0 10px 0;
            font-size: 18px;
            border-bottom: 1px solid rgba(255,255,255,0.2);
            padding-bottom: 10px;
        }
        .sidebar ul {
            list-style-type: none;
            padding: 0;
            margin: 0;
        }
        .sidebar ul li {
            padding: 8px 20px;
        }
        .sidebar ul li a {
            color: white;
            text-decoration: none;
            display: block;
        }
        .sidebar ul li:hover {
            background-color: rgba(255,255,255,0.1);
        }
        .content {
            margin-left: 250px;
            padding: 20px;
            width: calc(100% - 250px);
            box-sizing: border-box;
        }
        .content-inner {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
            border-radius: 5px;
        }
        h1 {
            color: #0078d4;
            border-bottom: 2px solid #0078d4;
            padding-bottom: 10px;
            margin-top: 0;
        }
        h2 {
            color: #0078d4;
            margin-top: 30px;
            border-bottom: 1px solid #ddd;
            padding-bottom: 5px;
        }
        h3 {
            color: #333;
            margin-top: 20px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #2c3e50;
            color: white;
            font-weight: bold;
            font-size: 12px;
            padding: 8px 10px;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        .timestamp {
            font-style: italic;
            color: #666;
            margin-bottom: 20px;
        }
        .section {
            margin-bottom: 30px;
            scroll-margin-top: 20px;
        }
        .policy-details {
            margin-left: 20px;
            margin-bottom: 20px;
        }
        .alert {
            background-color: #fff4e5;
            border-left: 4px solid #ff8c00;
            padding: 12px;
            margin-bottom: 15px;
            color: #663c00;
        }
        .collapsible {
            background-color: #f2f2f2;
            color: #666;
            cursor: pointer;
            padding: 8px 12px;
            width: 100%;
            border: none;
            text-align: left;
            outline: none;
            font-size: 13px;
            border-radius: 4px;
            margin: 3px 0;
            display: flex;
            justify-content: space-between;
            align-items: center;
            transition: background-color 0.3s;
            box-shadow: 0 1px 2px rgba(0,0,0,0.1);
        }
        .collapsible:hover {
            background-color: #e5e5e5;
        }
        .collapsible:before {
            content: "+";
            color: #666;
            font-weight: bold;
            font-size: 14px;
            margin-right: 8px;
        }
        .active {
            background-color: #e5e5e5;
        }
        .active:before {
            content: "-";
        }
        .collapsible-content {
            padding: 0;
            max-height: 0;
            overflow: hidden;
            transition: max-height 0.3s ease-out;
            background-color: #fafafa;
            border-radius: 0 0 4px 4px;
            margin-bottom: 8px;
            border: 1px solid #eee;
            border-top: none;
        }
        .policy-details {
            padding: 12px;
            margin: 0;
        }
        .policy-details ul {
            margin: 0;
            padding-left: 20px;
        }
        .policy-details li {
            margin-bottom: 4px;
            padding: 2px 0;
            font-size: 13px;
        }
        .policy-name {
            font-weight: bold;
            font-size: 12px;
            color: #2c3e50;
        }
        .company-name {
            color: #2c3e50;
            font-size: 14px;
            font-weight: bold;
            margin-bottom: 5px;
        }
        .assignment-cell {
            width: 100%;
            background-color: #f9f9f9;
            border-top: none;
        }
        .assignment-button {
            width: 100%;
            text-align: left;
            padding: 6px 10px;
            border: none;
            background-color: #f5f5f5;
            cursor: pointer;
            font-size: 12px;
            color: #777;
            transition: background-color 0.3s;
            border-radius: 3px;
            margin-top: 4px;
            margin-bottom: 4px;
        }
        .assignment-button:hover {
            background-color: #e5e5e5;
        }
        .assignment-icon {
            margin-right: 8px;
            font-style: normal;
        }
        .assignment-list {
            list-style-type: none;
            padding-left: 20px;
            margin-top: 4px;
            margin-bottom: 4px;
        }
        .assignment-item {
            margin-bottom: 4px;
            padding: 2px 0;
            font-size: 11px;
            color: #666;
        }
        .policy-row {
            border-left: 3px solid #3498db;
        }
        .collapsible-content {
            box-shadow: none;
            border: 1px solid #eee;
            border-radius: 3px;
        }
        .assignment-cell-inline {
            width: 180px;
            min-width: 180px;
            max-width: 250px;
            vertical-align: top;
            padding: 6px 8px;
            background-color: #f9f9f9;
        }
        .assignment-button-inline {
            padding: 4px 8px;
            font-size: 11px;
            color: #666;
            background-color: #f0f0f0;
            border-radius: 4px;
            width: 100%;
            text-align: center;
            margin: 0;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .assignment-button-inline:hover {
            background-color: #e6e6e6;
        }
        .assignment-button-inline:before {
            display: none;
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
                            <th>Assignments</th>
                        </tr>
"@

            foreach ($policy in $Policies[$policyType]) {
                # Get assignments early to include them inline
                $assignments = @()
                $assignmentSummary = "None"
                
                if ($IncludeAssignments) {
                    $assignments = Get-PolicyAssignments -Policy $policy -PolicyType $policyType -GroupIdsCollector ([ref]$global:IntuneAssignmentGroupIds)
                    
                    if ($assignments -and $assignments.Count -gt 0) {
                        $assignmentSummary = @"
<button class="collapsible assignment-button-inline">
    <i class="assignment-icon">👥</i> Assignments ($($assignments.Count))
</button>
<div class="collapsible-content">
    <ul class="assignment-list">
"@
                        foreach ($assignment in $assignments) {
                            try {
                                $targetGroupId = $null
                                $targetType = "Unknown Target Type"
                                
                                # Handle different types of assignments
                                if ($assignment.Target -is [string]) {
                                    # For string targets, just display as is
                                    $targetType = "Unknown: $($assignment.Target)"
                                }
                                elseif ($assignment.Target -and $assignment.Target.AdditionalProperties -and $assignment.Target.AdditionalProperties.ContainsKey('groupId')) {
                                    $targetGroupId = $assignment.Target.AdditionalProperties.groupId
                                }
                                elseif ($assignment.target -and $assignment.target.groupId) {
                                    $targetGroupId = $assignment.target.groupId
                                }
                                elseif ($assignment.Target -and $assignment.Target.AdditionalProperties -and $assignment.Target.AdditionalProperties.'@odata.type') {
                                    if ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.allDevicesAssignmentTarget') {
                                        $targetType = "All Devices"
                                    }
                                    elseif ($assignment.Target.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.allUsersAssignmentTarget') {
                                        $targetType = "All Users"
                                    }
                                }
                                # Additional checks for different target formats
                                elseif ($assignment.target -and $assignment.target.'@odata.type') {
                                    if ($assignment.target.'@odata.type' -eq '#microsoft.graph.allDevicesAssignmentTarget') {
                                        $targetType = "All Devices"
                                    }
                                    elseif ($assignment.target.'@odata.type' -eq '#microsoft.graph.allUsersAssignmentTarget') {
                                        $targetType = "All Users"
                                    }
                                }
                                # Direct property format
                                elseif ($assignment.target -and $assignment.target.deviceAndAppManagementAssignmentFilterType -eq 'none' -and 
                                       (-not $assignment.target.groupId) -and $assignment.target.deviceAndAppManagementAssignmentFilterId -eq $null) {
                                    if ($assignment.intent -eq 'required' -or $assignment.intent -eq 'available') {
                                        $targetType = "All Users"
                                    } elseif ($assignment.intent -eq 'excludeGroup') {
                                        $targetType = "Excluded: Group-based"
                                    } else {
                                        $targetType = "All ($($assignment.intent))"
                                    }
                                }
                                
                                if ($targetGroupId) {
                                    $groupName = Resolve-GroupName -GroupId $targetGroupId -Groups $Groups
                                    $assignmentSummary += "<li class='assignment-item'>$groupName</li>"
                                }
                                else {
                                    $assignmentSummary += "<li class='assignment-item'>$targetType</li>"
                                }
                            }
                            catch {
                                Write-Host "Error processing assignment display for policy $($policy.DisplayName): $_" -ForegroundColor Yellow
                                $assignmentSummary += "<li class='assignment-item'>Error processing assignment</li>"
                            }
                        }
                        
                        $assignmentSummary += @"
    </ul>
</div>
"@
                    }
                }
                
                $html += @"
                        <tr class="policy-row">
                            <td class="policy-name">$($policy.DisplayName)</td>
                            <td>$($policy.Description)</td>
                            <td>$($policy.CreatedDateTime)</td>
                            <td>$($policy.LastModifiedDateTime)</td>
                            <td class="assignment-cell-inline">$assignmentSummary</td>
                        </tr>
"@
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
                            <th>Assignments</th>
                        </tr>
"@

        foreach ($app in $Apps) {
            $appType = $app.AdditionalProperties.'@odata.type' -replace '#microsoft.graph.', ''
            
            # Get assignments early to include them inline
            $appAssignments = @()
            $assignmentSummary = "None"
            
            if ($IncludeAssignments) {
                $appAssignments = Get-AppAssignments -App $app -GroupIdsCollector ([ref]$global:IntuneAssignmentGroupIds)
                
                if ($appAssignments -and $appAssignments.Count -gt 0) {
                    $assignmentSummary = @"
<button class="collapsible assignment-button-inline">
    <i class="assignment-icon">👥</i> Assignments ($($appAssignments.Count))
</button>
<div class="collapsible-content">
    <ul class="assignment-list">
"@
                    foreach ($assignment in $appAssignments) {
                        try {
                            $targetGroupId = $assignment.target.groupId
                            $intent = $assignment.intent
                            $targetType = "Unknown Target Type"
                            
                            # Handle case where target or target.groupId is null or a string
                            if ($assignment.target -is [string]) {
                                $targetType = "Unknown: $($assignment.target)"
                            }
                            elseif ($assignment.target -and $assignment.target.'@odata.type') {
                                if ($assignment.target.'@odata.type' -eq '#microsoft.graph.allDevicesAssignmentTarget') {
                                    $targetType = "All Devices"
                                }
                                elseif ($assignment.target.'@odata.type' -eq '#microsoft.graph.allUsersAssignmentTarget') {
                                    $targetType = "All Users"
                                }
                            }
                            # Direct property format for all users/devices
                            elseif ($assignment.target -and $assignment.target.deviceAndAppManagementAssignmentFilterType -eq 'none' -and 
                                   (-not $assignment.target.groupId) -and $assignment.target.deviceAndAppManagementAssignmentFilterId -eq $null) {
                                if ($assignment.intent -eq 'required' -or $assignment.intent -eq 'available') {
                                    $targetType = "All Users"
                                } elseif ($assignment.intent -eq 'excludeGroup') {
                                    $targetType = "Excluded: Group-based"
                                } else {
                                    $targetType = "All ($($assignment.intent))"
                                }
                            }
                            
                            if ($targetGroupId) {
                                $groupName = Resolve-GroupName -GroupId $targetGroupId -Groups $Groups
                                $assignmentSummary += "<li class='assignment-item'>$groupName - Intent: $intent</li>"
                            }
                            else {
                                $assignmentSummary += "<li class='assignment-item'>$targetType - Intent: $intent</li>"
                            }
                        }
                        catch {
                            Write-Host "Error processing app assignment display for $($app.DisplayName): $_" -ForegroundColor Yellow
                            $assignmentSummary += "<li class='assignment-item'>Error processing assignment</li>"
                        }
                    }
                    
                    $assignmentSummary += @"
    </ul>
</div>
"@
                }
            }
            
            $html += @"
                        <tr class="policy-row">
                            <td class="policy-name">$($app.DisplayName)</td>
                            <td>$($app.Publisher)</td>
                            <td>$appType</td>
                            <td>$($app.CreatedDateTime)</td>
                            <td class="assignment-cell-inline">$assignmentSummary</td>
                        </tr>
"@
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
