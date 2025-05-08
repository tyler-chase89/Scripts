# App Configuration Policies in Intune

This document explains the different types of App Configuration Policies in Microsoft Intune and how they are handled in the Export-IntuneToHtmlReport script.

## Types of App Configuration Policies

Microsoft Intune supports several types of App Configuration Policies:

1. **Managed Device App Configuration Policies**
   - For apps running on managed devices (MDM-enrolled)
   - URL: `https://graph.microsoft.com/beta/deviceAppManagement/mobileAppConfigurations`
   - Retrieved using: `Get-MgDeviceAppManagementMobileAppConfiguration`

2. **Managed App Configuration Policies (Targeted)**
   - For apps under app protection policies (MAM) without device enrollment
   - URL: `https://graph.microsoft.com/beta/deviceAppManagement/targetedManagedAppConfigurations`
   - Retrieved using custom API request

3. **iOS App Provisioning Profiles**
   - For provisioning iOS apps
   - URL: `https://graph.microsoft.com/beta/deviceAppManagement/iosAppProvisioningProfiles`
   - Retrieved using custom API request

## Script Enhancements

The Export-IntuneToHtmlReport script has been enhanced to detect all types of app configuration policies:

### Added in Get-IntunePolicies function:

```powershell
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
```

### Updated in Get-PolicyAssignments function:

Added support for retrieving assignments for the new policy types:

```powershell
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
```

## Troubleshooting

If app configuration policies are still not detected after the enhancements:

1. **Check Permissions**: Ensure your Microsoft Graph API permissions include:
   - `DeviceManagementConfiguration.Read.All`
   - `DeviceManagementApps.Read.All`

2. **Review Console Output**: Look for errors or warnings in the PowerShell console output.

3. **API Version**: The script uses Beta API endpoints which may change. If issues persist, check the latest Microsoft Graph API documentation.

4. **Known Limitations**: Some policies may only be visible to Global Administrators or Intune Administrators.

## Further Reading

- [Microsoft Intune App Configuration Policies](https://learn.microsoft.com/en-us/mem/intune/apps/app-configuration-policies-overview)
- [Microsoft Graph API Reference](https://learn.microsoft.com/en-us/graph/api/resources/intune-graph-overview) 