# Test script to verify renaming functionality with a single device
# Run this script to test device renaming in isolation

# Import required modules
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.DeviceManagement

# Connect to Microsoft Graph with required scopes
Connect-MgGraph -Scopes @(
    "DeviceManagementManagedDevices.ReadWrite.All"
)

# This is where you'll paste a specific device ID to test
$deviceId = "e4b77db4-f902-47ca-9fe4-dd704ed75625"  # Replace with a real device ID from your environment

# This is where you'll enter a test device name
$newDeviceName = "ADC-INV-R92X61JQL7P"  # Replace with your test device name

# Validate inputs
if ([string]::IsNullOrEmpty($deviceId)) {
    Write-Host "Please edit this script and enter a valid device ID to test" -ForegroundColor Red
    exit
}

# Fetch the device to verify it exists
try {
    $device = Get-MgDeviceManagementManagedDevice -ManagedDeviceId $deviceId
    Write-Host "Found device: $($device.DeviceName) (ID: $($device.Id))" -ForegroundColor Green
}
catch {
    Write-Host "Error retrieving device with ID $deviceId : $_" -ForegroundColor Red
    exit
}

# Try to rename the device
try {
    Write-Host "Attempting to rename device to $newDeviceName..." -ForegroundColor Cyan
    
    # First, try using the ManagedDeviceName parameter directly
    try {
        Write-Host "Method 1: Using Update-MgDeviceManagementManagedDevice with ManagedDeviceName parameter" -ForegroundColor Gray
        Update-MgDeviceManagementManagedDevice -ManagedDeviceId $deviceId -ManagedDeviceName $newDeviceName -ErrorAction Stop
        Write-Host "  Successfully updated managedDeviceName" -ForegroundColor Green
    }
    catch {
        Write-Host "  Failed to update managedDeviceName: $_" -ForegroundColor Red
    }
    
    # Second, try updating display name through AdditionalProperties
    try {
        Write-Host "Method 2: Using Update-MgDeviceManagementManagedDevice with AdditionalProperties" -ForegroundColor Gray
        $params = @{
            AdditionalProperties = @{
                "@odata.type" = "#microsoft.graph.managedDevice"
                "displayName" = $newDeviceName
            }
        }
        Update-MgDeviceManagementManagedDevice -ManagedDeviceId $deviceId -BodyParameter $params -ErrorAction Stop
        Write-Host "  Successfully updated displayName" -ForegroundColor Green
    }
    catch {
        Write-Host "  Failed to update displayName: $_" -ForegroundColor Red
    }
    
    # Third, try using the BodyParameter with both properties
    try {
        Write-Host "Method 3: Using Update-MgDeviceManagementManagedDevice with both properties in BodyParameter" -ForegroundColor Gray
        $params = @{
            ManagedDeviceName = $newDeviceName
            AdditionalProperties = @{
                "@odata.type" = "#microsoft.graph.managedDevice"
                "displayName" = $newDeviceName
            }
        }
        Update-MgDeviceManagementManagedDevice -ManagedDeviceId $deviceId -BodyParameter $params -ErrorAction Stop
        Write-Host "  Successfully updated both properties" -ForegroundColor Green
    }
    catch {
        Write-Host "  Failed to update both properties: $_" -ForegroundColor Red
    }
    
    # Wait a moment for changes to propagate
    Start-Sleep -Seconds 5
    
    # Verify the changes
    $updatedDevice = Get-MgDeviceManagementManagedDevice -ManagedDeviceId $deviceId
    
    Write-Host "`nDevice details after update attempts:" -ForegroundColor Cyan
    Write-Host "  Device ID:         $($updatedDevice.Id)" -ForegroundColor White
    Write-Host "  Old Device Name:   $($device.DeviceName)" -ForegroundColor White
    Write-Host "  Current Dev Name:  $($updatedDevice.DeviceName)" -ForegroundColor White
    Write-Host "  Target Name:       $newDeviceName" -ForegroundColor White
    Write-Host "  Managed Dev Name:  $($updatedDevice.ManagedDeviceName)" -ForegroundColor White
    
    if ($updatedDevice.DeviceName -eq $newDeviceName) {
        Write-Host "`nSUCCESS: Device name was updated correctly!" -ForegroundColor Green
    }
    else {
        Write-Host "`nWARNING: Device name doesn't match the target name." -ForegroundColor Yellow
        Write-Host "The API calls completed, but the name didn't update as expected." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph

Write-Host "`nTest completed. Check the device in Intune to verify if the name was updated." -ForegroundColor Cyan 