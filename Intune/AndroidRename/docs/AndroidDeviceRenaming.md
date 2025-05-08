# Android Device Management Name Updates in Intune

## Overview
This documentation explains the approach for updating management names of Android devices in Intune, taking into account the platform limitations.

## Android Device Naming Limitation
**Important**: For Android devices in Intune, only the "Management Name" (`ManagedDeviceName`) can be reliably changed. The primary device name (`displayName`) shown in the Intune device list is controlled by the device itself or the Android management system and cannot be directly changed through the Intune API.

This differs from Windows devices, where both name properties can be modified through Intune.

## Simplified Solution Approach

The simplified approach focuses only on updating the Management Name:

```powershell
# Update only the management name (ManagedDeviceName)
Update-MgDeviceManagementManagedDevice -ManagedDeviceId $device.Id -ManagedDeviceName $newDeviceName
```

This ensures that the management name is properly updated while avoiding unsuccessful attempts to change the primary device name displayed in Intune lists.

## Script Functionality

The scripts perform the following functions:

1. **Identify device type**: Categorize devices for appropriate naming pattern application
   - USER: For user-assigned devices
   - ADC-DIN: For dining tablets 
   - ADC-INV: For inventory tablets

2. **Apply naming pattern**: Generate appropriate name using serial number
   - Example: `USER-{SerialNumber}` or `ADC-INV-{SerialNumber}`

3. **Update management name**: Update only the Intune Management Name property

4. **Verify update**: Confirm the management name was successfully updated

## Testing and Verification

The `SyncAndRenameTest.ps1` script can be used to test the management name update for a single device:

1. Edit the script to provide a specific device ID and desired name
2. Run the script to update only the management name
3. The script will verify and report if the update was successful

## Important Notes

1. **Display Name Limitation**: The device name shown in Intune device lists will not change. This is a limitation of how Android devices interact with Intune.

2. **Management Name Access**: The updated management name may be visible in detailed device views or reports but not in the main device list.

3. **Permissions Required**: Ensure your Microsoft Graph connection has the `DeviceManagementManagedDevices.ReadWrite.All` permission.

## References

- [Microsoft Graph API documentation for managed devices](https://learn.microsoft.com/en-us/graph/api/resources/intune-devices-manageddevice)
- [Android device management in Intune](https://learn.microsoft.com/en-us/mem/intune/fundamentals/what-is-device-management#android-device-management) 