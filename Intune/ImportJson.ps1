# Define parameters
param(
    [Parameter(Mandatory=$true)]
    [string]$FolderPath,
    
    [Parameter(Mandatory=$false)]
    [string]$DefaultDescription = "Configuration profile uploaded via PowerShell script",

    [Parameter(Mandatory=$false)]
    [string]$TenantId,

    [Parameter(Mandatory=$false)]
    [string]$ClientId,

    [Parameter(Mandatory=$false)]
    [string]$CertificateThumbprint
)

# Script to upload multiple JSON configuration files from a folder to Intune using Microsoft Graph PowerShell

# Check if Microsoft.Graph modules are installed and install if needed
$requiredModules = @(
    "Microsoft.Graph.Authentication", 
    "Microsoft.Graph.DeviceManagement",
    "Microsoft.Graph.DeviceManagement.Administration",
    "Microsoft.Graph.DeviceManagement.Enrollment"
)
foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "Installing $module module..." -ForegroundColor Yellow
        Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber
        Write-Host "$module module installed successfully" -ForegroundColor Green
    } else {
        Write-Host "$module module is already installed" -ForegroundColor Green
    }
}

# Import required modules
foreach ($module in $requiredModules) {
    Import-Module $module
}

# Connect to Microsoft Graph with necessary permissions
try {
    if ($TenantId -and $ClientId -and $CertificateThumbprint) {
        # Use certificate-based authentication if credentials are provided
        Connect-MgGraph -TenantId $TenantId -ClientId $ClientId -CertificateThumbprint $CertificateThumbprint
        Write-Host "Connected to Microsoft Graph using certificate authentication" -ForegroundColor Green
    } else {
        # Try interactive authentication with all necessary scopes
        Write-Host "Attempting interactive authentication..." -ForegroundColor Yellow
        Connect-MgGraph -Scopes @(
            "DeviceManagementConfiguration.ReadWrite.All",
            "DeviceManagementApps.ReadWrite.All",
            "DeviceManagementServiceConfig.ReadWrite.All"
        )
        Write-Host "Connected to Microsoft Graph using interactive authentication" -ForegroundColor Green
    }
}
catch {
    Write-Error "Failed to authenticate with Microsoft Graph: $_"
    Write-Host "If using interactive authentication, please ensure you're signed in to your Azure AD account." -ForegroundColor Yellow
    Write-Host "Alternatively, you can use certificate-based authentication by providing TenantId, ClientId, and CertificateThumbprint parameters." -ForegroundColor Yellow
    exit 1
}

# Validate folder exists
if (-not (Test-Path $FolderPath -PathType Container)) {
    Write-Error "Folder not found at path: $FolderPath"
    Write-Host "Please create the folder or specify a different path when running the script." -ForegroundColor Yellow
    Write-Host "Example: .\ImportJson.ps1 -FolderPath 'C:\Path\To\Your\JsonFiles'" -ForegroundColor Yellow
    Disconnect-MgGraph
    exit 1
}

# Get all JSON files in the specified folder
$jsonFiles = Get-ChildItem -Path $FolderPath -Filter "*.json"

if ($jsonFiles.Count -eq 0) {
    Write-Warning "No JSON files found in folder: $FolderPath"
    Disconnect-MgGraph
    exit 0
}

Write-Host "Found $($jsonFiles.Count) JSON files to process" -ForegroundColor Cyan

# Function to create policy based on type
function New-IntunePolicy {
    param (
        [Parameter(Mandatory=$true)]
        $PolicyData
    )

    $odataType = $PolicyData.'@odata.type'
    
    # Convert the policy data to JSON string and back to ensure proper type conversion
    $jsonString = $PolicyData | ConvertTo-Json -Depth 20
    $convertedPolicyData = $jsonString | ConvertFrom-Json
    
    # Determine the correct endpoint based on the policy type
    switch -Wildcard ($odataType) {
        "#microsoft.graph.*ManagedAppProtection" {
            Write-Host "Creating App Protection policy..." -ForegroundColor Cyan
            return Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceAppManagement/managedAppPolicies" -Body $jsonString
        }
        "#microsoft.graph.*CompliancePolicy" {
            Write-Host "Creating Compliance policy..." -ForegroundColor Cyan
            return Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceCompliancePolicies" -Body $jsonString
        }
        "#microsoft.graph.iosCompliancePolicy" {
            Write-Host "Creating iOS Compliance policy..." -ForegroundColor Cyan
            return Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceCompliancePolicies" -Body $jsonString
        }
        "#microsoft.graph.androidCompliancePolicy" {
            Write-Host "Creating Android Compliance policy..." -ForegroundColor Cyan
            return Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceCompliancePolicies" -Body $jsonString
        }
        "#microsoft.graph.androidWorkProfileCompliancePolicy" {
            Write-Host "Creating Android Work Profile Compliance policy..." -ForegroundColor Cyan
            return Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceCompliancePolicies" -Body $jsonString
        }
        "#microsoft.graph.windows*CompliancePolicy" {
            Write-Host "Creating Windows Compliance policy..." -ForegroundColor Cyan
            return Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceCompliancePolicies" -Body $jsonString
        }
        "#microsoft.graph.ios*" {
            Write-Host "Creating iOS Configuration policy..." -ForegroundColor Cyan
            return Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations" -Body $jsonString
        }
        "#microsoft.graph.android*" {
            Write-Host "Creating Android Configuration policy..." -ForegroundColor Cyan
            return Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations" -Body $jsonString
        }
        "#microsoft.graph.windows*" {
            Write-Host "Creating Windows Configuration policy..." -ForegroundColor Cyan
            return Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations" -Body $jsonString
        }
        default {
            Write-Host "Creating generic Device Configuration..." -ForegroundColor Cyan
            return Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations" -Body $jsonString
        }
    }
}

# Function to check if policy exists
function Get-ExistingPolicy {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DisplayName,
        
        [Parameter(Mandatory=$true)]
        [string]$ODataType
    )
    
    try {
        # Determine the correct endpoint based on the policy type
        switch -Wildcard ($ODataType) {
            "#microsoft.graph.*ManagedAppProtection" {
                $uri = "https://graph.microsoft.com/beta/deviceAppManagement/managedAppPolicies?`$filter=displayName eq '$DisplayName'"
            }
            "#microsoft.graph.*CompliancePolicy" {
                $uri = "https://graph.microsoft.com/beta/deviceManagement/deviceCompliancePolicies?`$filter=displayName eq '$DisplayName'"
            }
            default {
                $uri = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations?`$filter=displayName eq '$DisplayName'"
            }
        }
        
        $response = Invoke-MgGraphRequest -Method GET -Uri $uri
        if ($response.value.Count -gt 0) {
            return $response.value[0]
        }
    }
    catch {
        Write-Warning "Error checking for existing policy: $_"
    }
    
    return $null
}

# Process each JSON file
foreach ($jsonFile in $jsonFiles) {
    Write-Host "Processing file: $($jsonFile.Name)" -ForegroundColor Cyan
    
    try {
        # Read the JSON file content
        $jsonContent = Get-Content -Path $jsonFile.FullName -Raw
        
        # Validate JSON format
        $configData = $jsonContent | ConvertFrom-Json
        Write-Host "JSON file validated successfully" -ForegroundColor Green
        
        # The JSON file should contain all necessary configuration including @odata.type
        if (-not $configData.'@odata.type') {
            Write-Warning "File $($jsonFile.Name) does not contain '@odata.type' property. Skipping."
            continue
        }
        
        # Use filename (without extension) as profile name if not specified in JSON
        $configProfileName = if ($configData.displayName) { 
            $configData.displayName 
        } else { 
            $jsonFile.BaseName 
        }
        
        # Use default description if not specified in JSON
        $description = if ($configData.description) { 
            $configData.description 
        } else { 
            $DefaultDescription 
        }
        
        # Add or update display name and description
        $configData | Add-Member -NotePropertyName 'displayName' -NotePropertyValue $configProfileName -Force
        $configData | Add-Member -NotePropertyName 'description' -NotePropertyValue $description -Force
        
        # Check if policy already exists
        $existingPolicy = Get-ExistingPolicy -DisplayName $configProfileName -ODataType $configData.'@odata.type'
        
        if ($existingPolicy) {
            Write-Host "Policy '$configProfileName' already exists with ID: $($existingPolicy.id). Skipping." -ForegroundColor Yellow
            Write-Host "------------------------" -ForegroundColor Cyan
            continue
        }
        
        Write-Host "Creating policy: $configProfileName" -ForegroundColor Cyan
        
        # Create the policy using the appropriate command based on type
        $createdProfile = New-IntunePolicy -PolicyData $configData
        
        Write-Host "Policy created with ID: $($createdProfile.id)" -ForegroundColor Green
        
        # Check if assignment information is included in the JSON
        if ($configData.assignments) {
            Write-Host "Processing assignments from JSON file" -ForegroundColor Cyan
            
            foreach ($assignment in $configData.assignments) {
                $assignmentBody = @{
                    "@odata.type" = "#microsoft.graph.deviceConfigurationGroupAssignment"
                    groupId = $assignment.groupId
                    targetType = $assignment.targetType
                }
                
                # Convert assignment body to JSON
                $assignmentJson = $assignmentBody | ConvertTo-Json
                
                # Create the assignment based on policy type
                switch -Wildcard ($configData.'@odata.type') {
                    "#microsoft.graph.*CompliancePolicy" {
                        $uri = "https://graph.microsoft.com/beta/deviceManagement/deviceCompliancePolicies/$($createdProfile.id)/assignments"
                    }
                    "#microsoft.graph.*ProtectionPolicy" {
                        $uri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileAppConfigurations/$($createdProfile.id)/assignments"
                    }
                    default {
                        $uri = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/$($createdProfile.id)/assignments"
                    }
                }
                
                Invoke-MgGraphRequest -Method POST -Uri $uri -Body $assignmentJson
                Write-Host "Policy assigned to group: $($assignment.groupId)" -ForegroundColor Green
            }
        }
        
        Write-Host "Policy '$configProfileName' uploaded successfully" -ForegroundColor Green
        Write-Host "------------------------" -ForegroundColor Cyan
    }
    catch {
        Write-Host "Error processing file $($jsonFile.Name): $_" -ForegroundColor Red
        Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
        Write-Host "------------------------" -ForegroundColor Cyan
    }
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph
Write-Host "All JSON files processed. Disconnected from Microsoft Graph." -ForegroundColor Cyan