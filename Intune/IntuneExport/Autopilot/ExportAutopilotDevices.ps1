# Script to retrieve Windows Autopilot device information from Intune using Microsoft Graph API

# Install required modules if not already installed
if (-not (Get-Module -Name Microsoft.Graph.Intune -ListAvailable)) {
    Install-Module -Name Microsoft.Graph.Intune -Scope CurrentUser -Force
}

if (-not (Get-Module -Name Microsoft.Graph.Authentication -ListAvailable)) {
    Install-Module -Name Microsoft.Graph.Authentication -Scope CurrentUser -Force
}

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "DeviceManagementServiceConfig.Read.All", "Device.Read.All"

# Function to get all Autopilot devices
function Get-AutopilotDevices {
    $graphApiVersion = "beta"
    $resource = "deviceManagement/windowsAutopilotDeviceIdentities"
    $uri = "https://graph.microsoft.com/$graphApiVersion/$resource"
    
    try {
        $autopilotDevices = Invoke-MgGraphRequest -Uri $uri -Method Get
        return $autopilotDevices.value
    }
    catch {
        Write-Error "Error retrieving Autopilot devices: $_"
        return $null
    }
}

# Function to get Intune device details
function Get-IntuneDeviceDetails {
    param (
        [Parameter(Mandatory = $true)]
        [string]$serialNumber
    )
    
    $graphApiVersion = "beta"
    $resource = "deviceManagement/managedDevices"
    $filter = "?`$filter=serialNumber eq '$serialNumber'"
    $uri = "https://graph.microsoft.com/$graphApiVersion/$resource$filter"
    
    try {
        $intuneDevice = Invoke-MgGraphRequest -Uri $uri -Method Get
        return $intuneDevice.value
    }
    catch {
        Write-Warning "Could not find Intune device with serial number: $serialNumber"
        return $null
    }
}

# Get all Autopilot devices
$autopilotDevices = Get-AutopilotDevices

if ($autopilotDevices) {
    # Create an array to store the combined information
    $combinedDeviceInfo = @()
    
    foreach ($device in $autopilotDevices) {
        # Get corresponding Intune device information
        $intuneDevice = Get-IntuneDeviceDetails -serialNumber $device.serialNumber
        
        # Create a custom object with combined information
        $deviceInfo = [PSCustomObject]@{
            AutopilotDeviceId = $device.id
            SerialNumber = $device.serialNumber
            Model = $device.model
            Manufacturer = $device.manufacturer
            ProductKey = $device.productKey
            GroupTag = $device.groupTag
            PurchaseOrderId = $device.purchaseOrderId
            EnrollmentState = $device.enrollmentState
            LastContactedDateTime = $device.lastContactedDateTime
            IntuneDeviceName = if ($intuneDevice) { $intuneDevice.deviceName } else { "Not enrolled in Intune" }
            IntuneDeviceId = if ($intuneDevice) { $intuneDevice.id } else { "N/A" }
            ManagedDeviceOwnerType = if ($intuneDevice) { $intuneDevice.managedDeviceOwnerType } else { "N/A" }
            EnrolledDateTime = if ($intuneDevice) { $intuneDevice.enrolledDateTime } else { "N/A" }
            LastSyncDateTime = if ($intuneDevice) { $intuneDevice.lastSyncDateTime } else { "N/A" }
            OSVersion = if ($intuneDevice) { $intuneDevice.osVersion } else { "N/A" }
            ComplianceState = if ($intuneDevice) { $intuneDevice.complianceState } else { "N/A" }
        }
        
        $combinedDeviceInfo += $deviceInfo
    }
    
    # Display the results
    $combinedDeviceInfo | Format-Table -AutoSize
    
    # Export to CSV (optional)
    $exportPath = "$env:USERPROFILE\Desktop\AutopilotDevices_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $combinedDeviceInfo | Export-Csv -Path $exportPath -NoTypeInformation
    Write-Host "Device information exported to: $exportPath" -ForegroundColor Green
}
else {
    Write-Warning "No Autopilot devices found."
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph
