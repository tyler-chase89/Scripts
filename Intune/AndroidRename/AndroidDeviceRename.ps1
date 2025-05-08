# Script to rename Android devices in Intune based on device group membership and serial number
# Requires Microsoft.Graph modules

# Import required modules
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.DeviceManagement
Import-Module Microsoft.Graph.Groups
Import-Module Microsoft.Graph.DirectoryObjects

# Connect to Microsoft Graph with required scopes
Connect-MgGraph -Scopes @(
    "DeviceManagementManagedDevices.ReadWrite.All",
    "GroupMember.Read.All",
    "Directory.Read.All",
    "Device.Read.All"
)

# Define which group is for which device type
$groupTypeMappings = @{
    "Intune - User Mobile Devices" = "USER"
    "Intune - ADC Dining Tablets" = "ADC-DIN"
    "Intune - ADC Inventory Tablets" = "ADC-INV"
}

# Define naming patterns
$namingPatterns = @{
    "USER" = "USER-{0}"
    "ADC-DIN" = "ADC-DIN-{0}"
    "ADC-INV" = "ADC-INV-{0}"
}

# Get all Android devices from Intune
Write-Host "Retrieving Android devices from Intune..." -ForegroundColor Cyan
$androidDevices = Get-MgDeviceManagementManagedDevice -Filter "operatingSystem eq 'Android'"
Write-Host "Found $($androidDevices.Count) Android devices" -ForegroundColor Green

# Get all Intune device groups we care about
Write-Host "Retrieving target Intune device groups..." -ForegroundColor Cyan
$intuneGroups = @()
foreach ($groupName in $groupTypeMappings.Keys) {
    try {
        $group = Get-MgGroup -Filter "displayName eq '$groupName'" -ErrorAction Stop
        if ($group) {
            Write-Host "Found group: $groupName" -ForegroundColor Green
            $intuneGroups += [PSCustomObject]@{
                Id = $group.Id
                DisplayName = $group.DisplayName
                DeviceType = $groupTypeMappings[$group.DisplayName]
            }
        }
    }
    catch {
        Write-Host ("Error finding group " + $groupName + ": " + $_) -ForegroundColor Red
    }
}

# Create a map for device group memberships
Write-Host "Building device group membership map..." -ForegroundColor Cyan
$deviceGroupMap = @{}

# Map Intune devices to Azure AD devices
$azureADDeviceMap = @{}
foreach ($device in $androidDevices) {
    if (-not [string]::IsNullOrEmpty($device.AzureADDeviceId)) {
        $azureADDeviceMap[$device.AzureADDeviceId] = @{
            "IntuneDevice" = $device
            "ObjectId" = $null
        }
    }
}

# Get Azure AD devices and match them to Intune devices
$allAzureADDevices = Get-MgDevice -All
$matchCount = 0
foreach ($azureADDevice in $allAzureADDevices) {
    if ($azureADDeviceMap.ContainsKey($azureADDevice.DeviceId)) {
        $azureADDeviceMap[$azureADDevice.DeviceId]["ObjectId"] = $azureADDevice.Id
        $matchCount++
    }
}
Write-Host "Matched $matchCount Intune devices to Azure AD devices" -ForegroundColor Green

# Get group members for each target group
Write-Host "Retrieving group memberships..." -ForegroundColor Cyan
$groupMembers = @{}
foreach ($group in $intuneGroups) {
    try {
        $members = Get-MgGroupMember -GroupId $group.Id -All
        $groupMembers[$group.Id] = $members
        Write-Host "  Group $($group.DisplayName): $($members.Count) members" -ForegroundColor Green
    }
    catch {
        Write-Host "Error getting members for group $($group.DisplayName)" -ForegroundColor Red
        $groupMembers[$group.Id] = @()
    }
}

# Check each device's group memberships
foreach ($azureDeviceId in $azureADDeviceMap.Keys) {
    $deviceInfo = $azureADDeviceMap[$azureDeviceId]
    $objectId = $deviceInfo["ObjectId"]
    $intuneDevice = $deviceInfo["IntuneDevice"]
    
    if (-not $objectId) { continue }
    
    # Check group membership from the groups side
    foreach ($group in $intuneGroups) {
        $groupId = $group.Id
        $members = $groupMembers[$groupId]
        
        # Check if device is in this group
        $isMember = $members | Where-Object { $_.Id -eq $objectId }
        
        if ($isMember) {
            # Add to device group map
            if (-not $deviceGroupMap.ContainsKey($azureDeviceId)) {
                $deviceGroupMap[$azureDeviceId] = @()
            }
            
            # Avoid duplicates
            $existingGroup = $deviceGroupMap[$azureDeviceId] | Where-Object { $_.Id -eq $groupId } | Select-Object -First 1
            if (-not $existingGroup) {
                $deviceGroupMap[$azureDeviceId] += $group
            }
        }
    }
    
    # If not found in any group, try direct memberOf query
    if (-not $deviceGroupMap.ContainsKey($azureDeviceId) -or $deviceGroupMap[$azureDeviceId].Count -eq 0) {
        try {
            $memberOfGroups = Get-MgDeviceMemberOf -DeviceId $objectId -All -ErrorAction SilentlyContinue
            
            if ($memberOfGroups -and $memberOfGroups.Count -gt 0) {
                if (-not $deviceGroupMap.ContainsKey($azureDeviceId)) {
                    $deviceGroupMap[$azureDeviceId] = @()
                }
                
                foreach ($memberGroup in $memberOfGroups) {
                    $groupId = $memberGroup.Id
                    $matchedGroup = $intuneGroups | Where-Object { $_.Id -eq $groupId } | Select-Object -First 1
                    
                    if ($matchedGroup) {
                        # Avoid duplicates
                        $existingGroup = $deviceGroupMap[$azureDeviceId] | Where-Object { $_.Id -eq $groupId } | Select-Object -First 1
                        if (-not $existingGroup) {
                            $deviceGroupMap[$azureDeviceId] += $matchedGroup
                        }
                    }
                }
            }
        }
        catch {
            # Continue if error looking up memberships
        }
    }
}

# Statistics tracking
$devicesByPattern = @{
    "USER" = 0
    "ADC-DIN" = 0
    "ADC-INV" = 0
    "Skipped" = 0
}

# Process each device for renaming
$processedDevices = @()
foreach ($device in $androidDevices) {
    $newDeviceName = $null
    $serialNumber = $device.SerialNumber
    $azureDeviceId = $device.AzureADDeviceId
    $userId = $device.UserId
    $managedDeviceOwnerType = $device.ManagedDeviceOwnerType
    $deviceModel = $device.Model
    
    # Skip devices with no serial number
    if ([string]::IsNullOrEmpty($serialNumber)) {
        Write-Host "Skipping device $($device.DeviceName) - No serial number found" -ForegroundColor Yellow
        $devicesByPattern["Skipped"]++
        continue
    }
    
    # Log device details
    Write-Host "Processing device: $($device.DeviceName)" -ForegroundColor Cyan
    
    # Get group memberships
    $deviceGroups = @()
    $membershipInfo = ""
    
    if (-not [string]::IsNullOrEmpty($azureDeviceId) -and $deviceGroupMap.ContainsKey($azureDeviceId)) {
        $deviceGroups = $deviceGroupMap[$azureDeviceId]
        Write-Host "  Group memberships:" -ForegroundColor Green
        foreach ($group in $deviceGroups) {
            Write-Host "    - $($group.DisplayName)" -ForegroundColor Green
            $membershipInfo += "$($group.DisplayName); "
        }
    }
    else {
        Write-Host "  No group memberships found" -ForegroundColor Yellow
        $membershipInfo = "No group memberships; "
    }
    
    # Determine device type using multi-level strategy
    $deviceType = $null
    $assignmentReason = ""
    
    # 1. Check existing naming pattern first
    if ($device.DeviceName -like "ADC-DIN-*") {
        $deviceType = "ADC-DIN"
        $assignmentReason = "Existing name matches Dining Tablets pattern"
    }
    elseif ($device.DeviceName -like "ADC-INV-*") {
        $deviceType = "ADC-INV"
        $assignmentReason = "Existing name matches Inventory Tablets pattern"
    }
    elseif ($device.DeviceName -like "USER-*") {
        $deviceType = "USER"
        $assignmentReason = "Existing name matches User pattern"
    }
    # 2. Check direct group membership
    elseif ($deviceGroups.Count -gt 0) {
        # If device is in multiple groups, use priority order: Dining, Inventory, User
        $deviceTypesByPriority = @("ADC-DIN", "ADC-INV", "USER")
        
        foreach ($priorityType in $deviceTypesByPriority) {
            $matchingGroup = $deviceGroups | Where-Object { $_.DeviceType -eq $priorityType } | Select-Object -First 1
            
            if ($matchingGroup) {
                $deviceType = $priorityType
                $assignmentReason = "Device is member of $($matchingGroup.DisplayName) group"
                break
            }
        }
        
        # If no prioritized match, just use the first group found
        if (-not $deviceType) {
            $deviceType = $deviceGroups[0].DeviceType
            $assignmentReason = "Device is member of $($deviceGroups[0].DisplayName) group"
        }
    }
    # 3. Check if it's a tablet based on model/name
    elseif ($device.Model -like "*Tab*" -or 
            $device.Model -like "*SM-T*" -or 
            $device.DeviceName -like "*Tab*" -or
            $device.DeviceName -like "*Dining*" -or 
            $device.DeviceName -like "*Restaurant*") {
        $deviceType = "ADC-DIN"
        $assignmentReason = "Appears to be a dining tablet based on model/name"
    }
    elseif ($device.DeviceName -like "*Inventory*" -or 
            $device.DeviceName -like "*Warehouse*" -or 
            $device.DeviceName -like "*Stock*") {
        $deviceType = "ADC-INV"
        $assignmentReason = "Appears to be an inventory tablet based on name"
    }
    # 4. Fall back to ownership type and user ID
    elseif (-not [string]::IsNullOrEmpty($userId)) {
        $deviceType = "USER"
        $assignmentReason = "Has User ID assigned"
    }
    elseif ($managedDeviceOwnerType -eq "company" -or $managedDeviceOwnerType -eq "Company") {
        $deviceType = "USER"
        $assignmentReason = "Company-owned device without tablet indicators"
    }
    
    # Determine new device name from the device type
    if ($deviceType -and $namingPatterns.ContainsKey($deviceType)) {
        $newDeviceName = $namingPatterns[$deviceType] -f $serialNumber
        Write-Host "  Device type: $deviceType ($assignmentReason)" -ForegroundColor Cyan
        
        # Update pattern count
        $devicesByPattern[$deviceType]++
        
        # Store processed device info for summary
        $processedDevices += [PSCustomObject]@{
            DeviceName = $device.DeviceName
            NewName = $newDeviceName
            DeviceType = $deviceType
            AssignmentReason = $assignmentReason
            GroupMemberships = $membershipInfo
        }
    }
    else {
        Write-Host "  Skipping - Unable to determine appropriate device type" -ForegroundColor Yellow
        $devicesByPattern["Skipped"]++
        
        # Store skipped device for summary
        $processedDevices += [PSCustomObject]@{
            DeviceName = $device.DeviceName
            NewName = "SKIPPED"
            DeviceType = "N/A"
            AssignmentReason = "No device type determined"
            GroupMemberships = $membershipInfo
        }
        
        continue
    }
    
    # Update device name if needed
    if ($newDeviceName -and ($device.DeviceName -ne $newDeviceName)) {
        try {
            Write-Host "  Renaming to $newDeviceName..." -ForegroundColor Cyan
            
            # Update only the ManagedDeviceName (management name) since displayName cannot be reliably changed for Android
            try {
                Update-MgDeviceManagementManagedDevice -ManagedDeviceId $device.Id -ManagedDeviceName $newDeviceName -ErrorAction Stop
                Write-Host "  Successfully updated management name to $newDeviceName" -ForegroundColor Green
            }
            catch {
                Write-Host "  Failed to update management name: $_" -ForegroundColor Red
            }
            
            # Verify the update
            try {
                Start-Sleep -Seconds 2  # Brief pause to allow changes to propagate
                $updatedDevice = Get-MgDeviceManagementManagedDevice -ManagedDeviceId $device.Id -ErrorAction Stop
                
                if ($updatedDevice.ManagedDeviceName -eq $newDeviceName) {
                    Write-Host "  Success: Management name updated to $newDeviceName" -ForegroundColor Green
                }
                else {
                    Write-Host "  Warning: Management name update may not have succeeded" -ForegroundColor Yellow
                    Write-Host "  Current management name: $($updatedDevice.ManagedDeviceName)" -ForegroundColor Yellow
                }
                
                # Always show this information for clarity
                Write-Host "  Note: The device name shown in Intune lists ($($updatedDevice.DeviceName)) cannot be changed for Android devices" -ForegroundColor Gray
            }
            catch {
                Write-Host "  Could not verify name update: $_" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "  Error in device rename process: $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host "  Device already has the correct name" -ForegroundColor Gray
    }
}

# Display summary statistics
Write-Host "`n===== DEVICE RENAMING SUMMARY =====" -ForegroundColor Green
Write-Host "Total devices processed: $($androidDevices.Count)" -ForegroundColor Green
Write-Host "Devices assigned USER pattern: $($devicesByPattern["USER"])" -ForegroundColor Cyan
Write-Host "Devices assigned ADC-DIN pattern: $($devicesByPattern["ADC-DIN"])" -ForegroundColor Cyan
Write-Host "Devices assigned ADC-INV pattern: $($devicesByPattern["ADC-INV"])" -ForegroundColor Cyan
Write-Host "Devices skipped: $($devicesByPattern["Skipped"])" -ForegroundColor Yellow

# Display detailed device info in a table
Write-Host "`n===== DETAILED DEVICE INFORMATION =====" -ForegroundColor Green
$processedDevices | Format-Table -AutoSize -Property DeviceName, NewName, DeviceType, AssignmentReason, GroupMemberships

# Disconnect from Microsoft Graph
Disconnect-MgGraph
