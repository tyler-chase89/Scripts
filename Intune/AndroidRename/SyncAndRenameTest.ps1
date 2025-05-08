# Simplified test script for Android device management name updates
# Run this script to test management name updates on a single device

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
    Write-Host "Current details:" -ForegroundColor Cyan
    Write-Host "  DeviceName: $($device.DeviceName)" -ForegroundColor White
    Write-Host "  ManagedDeviceName: $($device.ManagedDeviceName)" -ForegroundColor White
    Write-Host "  Model: $($device.Model)" -ForegroundColor White
    Write-Host "  OS: $($device.OperatingSystem) $($device.OsVersion)" -ForegroundColor White
}
catch {
    Write-Host "Error retrieving device with ID $deviceId : $_" -ForegroundColor Red
    exit
}

# Attempt to update the management name
Write-Host "`nAttempting to update management name to $newDeviceName..." -ForegroundColor Cyan

try {
    # Update only the management name (ManagedDeviceName)
    Update-MgDeviceManagementManagedDevice -ManagedDeviceId $deviceId -ManagedDeviceName $newDeviceName
    Write-Host "Update command completed successfully." -ForegroundColor Green
}
catch {
    Write-Host "Failed to update management name: $_" -ForegroundColor Red
    Disconnect-MgGraph
    exit
}

# Brief pause to allow changes to propagate
Write-Host "Waiting 5 seconds for changes to propagate..." -ForegroundColor Gray
Start-Sleep -Seconds 5

# Verify the change
$updatedDevice = Get-MgDeviceManagementManagedDevice -ManagedDeviceId $deviceId
Write-Host "`nDevice details after update:" -ForegroundColor Cyan
Write-Host "  Original DeviceName:        $($device.DeviceName)" -ForegroundColor White
Write-Host "  Current DeviceName:         $($updatedDevice.DeviceName)" -ForegroundColor White
Write-Host "  Original Management Name:   $($device.ManagedDeviceName)" -ForegroundColor White
Write-Host "  Current Management Name:    $($updatedDevice.ManagedDeviceName)" -ForegroundColor White
Write-Host "  Target Name:                $newDeviceName" -ForegroundColor White

# Check if management name was updated
if ($updatedDevice.ManagedDeviceName -eq $newDeviceName) {
    Write-Host "`nSUCCESS: Management name was updated to $newDeviceName" -ForegroundColor Green
}
else {
    Write-Host "`nWARNING: Management name was not updated as expected" -ForegroundColor Yellow
    Write-Host "Current value: $($updatedDevice.ManagedDeviceName)" -ForegroundColor Yellow
}

# Always show this note about Android limitations
Write-Host "`nNOTE: The device name shown in Intune lists ($($updatedDevice.DeviceName)) cannot be changed for Android devices." -ForegroundColor Yellow
Write-Host "This is a limitation of how Android devices interact with Intune." -ForegroundColor Yellow

# Disconnect from Microsoft Graph
Disconnect-MgGraph

Write-Host "`nTest completed." -ForegroundColor Cyan 