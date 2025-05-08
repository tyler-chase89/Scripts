# Configuration
$tenant_id = "e24be7b2-dbc8-47ef-8071-593408b48c9e" #Read-Host " "
$logon_title = "Login"
$logon_message = "This computer system is managed by Acme, Inc. Access is hereby granted for authorized use only. By using this system, you acknowledge notice and acceptance of the Acme Acceptable Use Policy."
$intune_policy_name = "CIS Baseline Microsoft Intune for Windows 11 v3.0.1 (L1+L2)"
$intune_policy_description = "Primary CIS Baseline Policy implemented using OMAURI."

# End Config
############

if ($tenant_id -eq "") {
  Write-Host "Please configure your Azure tenant id."
  return 1
}

$module = Get-Module -ListAvailable -Name Microsoft.Graph.DeviceManagement
if ($module) {
    if ($module.Version.major -lt 2 -or $module.Version.minor -lt 26 -or $module.Version.Build -lt 1) {
        write-host -ForegroundColor Yellow -BackgroundColor Black "Microsoft.Graph.DeviceManagement module must be updated..." 
        Update-Module Microsoft.Graph.DeviceManagement -force
    }
} 
else {
    Write-Host -ForegroundColor Yellow -BackgroundColor Black "The Microsoft.Graph.DeviceManagement module is not currently installed, but is required."
    Write-Host -ForegroundColor Yellow -BackgroundColor Black "Module will now be installed."
    Install-Module Microsoft.Graph.DeviceManagement -Scope CurrentUser -Repository PSGallery -force
}

Write-Host -ForegroundColor Cyan -BackgroundColor Black "Loading Microsoft.Graph.DeviceManagement Module..."
Import-Module Microsoft.Graph.DeviceManagement

Write-Host "Loading configuration..."
$params = @{
  # Windows 10 is still referenced in the odata.type for now
  "@odata.type" = "#microsoft.graph.windows10CustomConfiguration"
  supportsScopeTags = $true
  deviceManagementApplicabilityRuleOsEdition = $null
  deviceManagementApplicabilityRuleOsVersion = $null
  deviceManagementApplicabilityRuleDeviceMode = $null
  description = $intune_policy_description
  displayName = $intune_policy_name
  version = 20250312
  omaSettings = @(
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "1.1 (L1) Ensure 'Allow Cortana above lock screen' is set to 'Blocked'"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/AboveLock/AllowCortanaAboveLock"
        "value" = 0
    },
    # 3.1.3.1 (L1) Ensure 'Enable screen saver (User)' is set to 'Enabled' - NO OMAURI
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.1.3.2 (L1) Ensure 'Prevent enabling lock screen camera' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/DeviceLock/PreventEnablingLockScreenCamera"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.1.3.3 (L1) Ensure 'Prevent enabling lock screen slide show' is set to 'Enabled' (Automated)"
        "description" = "Opposed. We will allow slideshows."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/DeviceLock/PreventLockScreenSlideShow"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.4.1 (L1) Ensure 'Apply UAC restrictions to local accounts on network logons' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/MSSecurityGuide/ApplyUACRestrictionsToLocalAccountsOnNetworkLogon"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.4.2 (L1) Ensure 'Configure SMB v1 client driver' is set to 'Enabled: Disable driver (recommended)' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/MSSecurityGuide/ConfigureSMBV1ClientDriver"
        "value" = "<enabled/><data id=`"Pol_SecGuide_SMB1ClientDriver`" value=`"4`" />"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.4.3 (L1) Ensure 'Configure SMB v1 server' is set to 'Disabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/MSSecurityGuide/ConfigureSMBV1Server"
        "value" = "<disabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.4.4 (L1) Ensure 'Enable Structured Exception Handling Overwrite Protection (SEHOP)' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/MSSecurityGuide/EnableStructuredExceptionHandlingOverwriteProtection"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.4.5 (L1) Ensure 'WDigest Authentication' is set to 'Disabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/MSSecurityGuide/WDigestAuthentication"
        "value" = "<disabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.5.1 (L1) Ensure 'MSS: (AutoAdminLogon) Enable Automatic Logon (not recommended)' is set to 'Disabled' (Automated)"
        "description" = "Implemented. Windows Autopilot Warning: Windows Autopilot pre-provisioning doesn't work when this GPO policy settings is enabled. An exception to this recommendation will be needed if Windows AutoPilot is used."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_MSS-legacy/Pol_MSS_AutoAdminLogon"
        "value" = "<disabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.5.2 (L1) Ensure 'MSS: (DisableIPSourceRouting IPv6) IP source routing protection level (protects against packet spoofing)' is set to 'Enabled: Highest protection, source routing is completely disabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/MSSLegacy/IPv6SourceRoutingProtectionLevel"
        "value" = "<enabled/><data id=`"DisableIPSourceRoutingIPv6`" value=`"2`" />"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.5.3 (L1) Ensure 'MSS: (DisableIPSourceRouting) IP source routing protection level (protects against packet spoofing)' is set to 'Enabled: Highest protection, source routing is completely disabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/MSSLegacy/IPSourceRoutingProtectionLevel"
        "value" = "<enabled/><data id=`"DisableIPSourceRouting`" value=`"2`" />"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.5.4 (L2) Ensure 'MSS: (DisableSavePassword) Prevent the dial-up password from being saved' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_MSS-legacy/Pol_MSS_DisableSavePassword"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.5.5 (L1) Ensure 'MSS: (EnableICMPRedirect) Allow ICMP redirects to override OSPF generated routes' is set to 'Disabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/MSSLegacy/AllowICMPRedirectsToOverrideOSPFGeneratedRoutes"
        "value" = "<disabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.5.6 (L2) Ensure 'MSS: (KeepAliveTime) How often keep-alive packets are sent in milliseconds' is set to 'Enabled: 300,000 or 5 minutes (recommended)' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_MSS-legacy/Pol_MSS_KeepAliveTime"
        "value" = "<enabled/><data id=`"KeepAliveTime`" value=`"300000`"/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.5.7 (L1) Ensure 'MSS: (NoNameReleaseOnDemand) Allow the computer to ignore NetBIOS name release requests except from WINS servers' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/MSSLegacy/AllowTheComputerToIgnoreNetBIOSNameReleaseRequestsExceptFromWINSServers"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.5.8 (L2) Ensure 'MSS: (PerformRouterDiscovery) Allow IRDP to detect and configure Default Gateway addresses (could lead to DoS)' is set to 'Disabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_MSS-legacy/Pol_MSS_PerformRouterDiscovery"
        "value" = "<disabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.5.9 (L1) Ensure 'MSS: (SafeDllSearchMode) Enable Safe DLL search mode (recommended)' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_MSS-legacy/Pol_MSS_SafeDllSearchMode"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.5.10 (L1) Ensure 'MSS: (ScreenSaverGracePeriod) The time in seconds before the screen saver grace period expires (0 recommended)' is set to 'Enabled: 5 or fewer seconds' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_MSS-legacy/Pol_MSS_ScreenSaverGracePeriod"
        "value" = "<enabled/><data id=`"ScreenSaverGracePeriod`" value=`"5`"/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.5.11 (L2) Ensure 'MSS: (TcpMaxDataRetransmissions IPv6) How many times unacknowledged data is retransmitted' is set to 'Enabled: 3' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_MSS-legacy/Pol_MSS_TcpMaxDataRetransmissionsIPv6"
        "value" = "<enabled/><data id=`"TcpMaxDataRetransmissions`" value=`"3`"/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.5.12 (L2) Ensure 'MSS: (TcpMaxDataRetransmissions) How many times unacknowledged data is retransmitted' is set to 'Enabled: 3' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_MSS-legacy/Pol_MSS_TcpMaxDataRetransmissions"
        "value" = "<enabled/><data id=`"TcpMaxDataRetransmissions`" value=`"3`"/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.5.13 (L1) Ensure 'MSS: (WarningLevel) Percentage threshold for the security event log at which the system will generate a warning' is set to 'Enabled: 90% or less' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_MSS-legacy/Pol_MSS_WarningLevel"
        "value" = "<enabled/><data id=`"WarningLevel`" value=`"90`"/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.6.4.1 (L1) Ensure 'Turn off multicast name resolution' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_DnsClient/Turn_Off_Multicast"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.6.8.1 (L2) Ensure 'Turn on Mapper I/O (LLTDIO) driver' is set to 'Disabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_LinkLayerTopologyDiscovery/LLTD_EnableLLTDIO"
        "value" = "<disabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.6.8.2 (L2) Ensure 'Turn on Responder (RSPNDR) driver' is set to 'Disabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_LinkLayerTopologyDiscovery/LLTD_EnableRspndr"
        "value" = "<disabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.6.9.1 (L1) Ensure 'Prohibit installation and configuration of Network Bridge on your DNS domain network' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Connectivity/ProhibitInstallationAndConfigurationOfNetworkBridge"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.6.9.2 (L1) Ensure 'Prohibit use of Internet Connection Sharing on your DNS domain network' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_NetworkConnections/NC_ShowSharedAccessUI"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.6.9.3 (L1) Ensure 'Require domain users to elevate when setting a network's location' is set to 'Enabled' (Automated)"
        "description" = "Implemented."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_NetworkConnections/NC_StdDomainUserSetLocation"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.6.11.1 (L1) Ensure 'Hardened UNC Paths' is set to 'Enabled, with `"Require Mutual Authentication`" and `"Require Integrity`" set for all NETLOGON and SYSVOL shares' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Connectivity/HardenedUNCPaths"
        "value" = "<enabled/><data id=`"Pol_HardenedPaths`" value=`"\\*\NETLOGON$([char]0xF000)RequireMutualAuthentication=1,RequireIntegrity=1$([char]0xF000)\\*\SYSVOL$([char]0xF000)RequireMutualAuthentication=1,RequireIntegrity=1`"/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.6.17.1 (L2) Ensure 'Configuration of wireless settings using Windows Connect Now' is set to 'Disabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_WindowsConnectNow/WCN_EnableRegistrar"
        "value" = "<disabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.6.17.2 (L2) Ensure 'Prohibit access of the Windows Connect Now wizards' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_WindowsConnectNow/WCN_DisableWcnUi_2"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.6.18.1 (L1) Ensure 'Minimize the number of simultaneous connections to the Internet or a Windows Domain' is set to 'Enabled: 3 = Prevent Wi-Fi when on Ethernet' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_WCM/WCM_MinimizeConnections"
        "value" = "<enabled/><data id=`"WCM_MinimizeConnections_Options`" value=`"3`"/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.6.18.2 (L1) Ensure 'Prohibit connection to non-domain networks when connected to domain authenticated network' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/WindowsConnectionManager/ProhitConnectionToNonDomainNetworksWhenConnectedToDomainAuthenticatedNetwork"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "3.6.19.1-1 (L1) Ensure 'Require PIN pairing' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/WirelessDisplay/RequirePinForPairing"
        "value" = 2
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.6.19.1-2 (L1) Ensure 'Require PIN pairing' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_wlansvc/SetPINEnforced"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.7.1 (L1) Ensure 'Allow Print Spooler to accept client connections' is set to 'Disabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_Printing2/RegisterSpoolerRemoteRpcEndPoint"
        "value" = "<disabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.7.2 and 3.7.3 (L1) Ensure 'Point and Print Restrictions: When installing drivers for a new connection' is set to 'Enabled: Show warning and elevation prompt' (L1) Ensure 'Point and Print Restrictions: When updating drivers for an existing connection' is set to 'Enabled: Show warning and elevation prompt' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Printers/PointAndPrintRestrictions"
        "value" = "<enabled/>`n<data id=`"PointAndPrint_TrustedServers_Chk`" value=`"false`"/>`n<data id=`"PointAndPrint_TrustedServers_Edit`" value=`"`"/>`n<data id=`"PointAndPrint_TrustedForest_Chk`" value=`"false`"/>`n<data id=`"PointAndPrint_NoWarningNoElevationOnInstall_Enum`" value=`"0`"/>`n<data id=`"PointAndPrint_NoWarningNoElevationOnUpdate_Enum`" value=`"0`"/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "3.9.1.1 (L1) Ensure 'Turn off toast notifications on the lock screen' is set to 'Blocked' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/AboveLock/AllowToasts"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.4.1 (L1) Ensure 'Include command line in process creation events' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_AuditSettings/IncludeCmdLine"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.5.1 (L1) Ensure 'Encryption Oracle Remediation' is set to 'Enabled: Force Updated Clients' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_CredSsp/AllowEncryptionOracle"
        "value" = "<enabled/>`n<data id=`"AllowEncryptionOracleDrop`" value=`"0`"/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.5.2 (L1) Ensure 'Remote host allows delegation of non-exportable credentials' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/CredentialsDelegation/RemoteHostAllowsDelegationOfNonExportableCredentials"
        "value" = "<enabled/>"
    },
    # 3.10.9.1.1 to 3.10.9.1.6 are implemented in the Bitlocker policy
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.9.2 (L1) Ensure 'Prevent device metadata retrieval from the Internet' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/DeviceInstallation/PreventDeviceMetadataFromNetwork"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.13.1 (L1) Ensure 'Boot-Start Driver Initialization Policy' is set to 'Enabled: Good, unknown and bad but critical' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/System/BootStartDriverInitialization"
        "value" = "<enabled/>`n<data id=`"SelectDriverLoadPolicy`" value=`"3`"/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.19.1 and 3.10.19.2 (L1) Ensure 'Configure registry policy processing: Do not apply during periodic background processing' is set to 'Enabled: FALSE' 3.10.19.2 (L1) Ensure 'Configure registry policy processing: Process even if the Group Policy objects have not changed' is set to 'Enabled: TRUE' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_GroupPolicy/CSE_Registry"
        "value" = "<enabled/>`n<data id=`"CSE_NOBACKGROUND10`" value=`"false`"/>`n<data id=`"CSE_NOCHANGES10`" value=`"true`"/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.19.3 and 3.10.19.4 (L1) Ensure 'Configure security policy processing: Do not apply during periodic background processing' is set to 'Enabled: FALSE' (L1) Ensure 'Configure security policy processing: Process even if the Group Policy objects have not changed' is set to 'Enabled: TRUE' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_GroupPolicy/CSE_Security"
        "value" = "<enabled/>`n<data id=`"CSE_NOBACKGROUND11`" value=`"false`"/>`n<data id=`"CSE_NOCHANGES11`" value=`"true`"/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.19.5 (L1) Ensure 'Continue experiences on this device' is set to 'Disabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_GroupPolicy/EnableCDP"
        "value" = "<disabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.19.6 (L1) Ensure 'Turn off background refresh of Group Policy' is set to 'Disabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_GroupPolicy/DisableBackgroundPolicy"
        "value" = "<disabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.20.1.1 (L2) Ensure 'Turn off access to the Store' is set to 'Enabled'"
        "description" = "Implemented. Using store is ok, but not when using the Open With context menu."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_ICM/ShellNoUseStoreOpenWith_2"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.20.1.2 (L1) Ensure 'Turn off downloading of print drivers over HTTP' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Connectivity/DisableDownloadingOfPrintDriversOverHTTP"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.20.1.3 (L2) Ensure 'Turn off Help Experience Improvement Program' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./User/Vendor/MSFT/Policy/Config/ADMX_HelpAndSupport/HPImplicitFeedback"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.20.1.4 (L2) Ensure 'Turn off Internet Connection Wizard if URL connection is referring to Microsoft.com' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_ICM/NC_ExitOnISP"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.20.1.5 (L1) Ensure 'Turn off Internet download for Web publishing and online ordering wizards' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Connectivity/DisableInternetDownloadForWebPublishingAndOnlineOrderingWizards"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.20.1.6 (L2) Ensure 'Turn off printing over HTTP' is set to 'Enabled' (Automated)"
        "description" = "Opposed. Using HTTPS print is a more secure method than LPT and other printing services because it allows authentication. This policy controls HTTP and HTTPS."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Connectivity/DiablePrintingOverHTTP"
        "value" = "<disabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.20.1.7 (L2) Ensure 'Turn off Registration if URL connection is referring to Microsoft.com' is set to 'Enabled' (Automated)"
        "description" = "Implemented."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_ICM/NC_NoRegistration"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.20.1.8 (L2) Ensure 'Turn off Search Companion content file updates' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_ICM/SearchCompanion_DisableFileUpdates"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.20.1.9 (L2) Ensure 'Turn off the `"Order Prints`" picture task' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_ICM/ShellRemoveOrderPrints_2"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.20.1.10 (L2) Ensure 'Turn off the `"Publish to Web`" task for files and folders' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_ICM/ShellRemovePublishToWeb_2"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.20.1.11 (L2) Ensure 'Turn off the Windows Messenger Customer Experience Improvement Program' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_ICM/WinMSG_NoInstrumentation_2"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.20.1.12 (L2) Ensure 'Turn off Windows Customer Experience Improvement Program' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_ICM/CEIPEnable"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.20.1.13 (L2) Ensure 'Turn off Windows Error Reporting' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_ICM/PCH_DoNotReport"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.23.1 (L2) Ensure 'Support device authentication using certificate' is set to 'Enabled: Automatic' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_Kerberos/DevicePKInitEnabled"
        "value" = "<enabled/>`n<data id=`"DevicePKInitBehavior`" value=`"0`"/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.24.1 (L2) Ensure 'Disallow copying of user input methods to the system account for sign-in' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_Globalization/BlockUserInputMethodsForSignIn"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.25.1 (L1) Ensure 'Block user from showing account details on sign-in' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_Logon/BlockUserFromShowingAccountDetailsOnSignin"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.25.2 (L1) Ensure 'Do not display network selection UI' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/WindowsLogon/DontDisplayNetworkSelectionUI"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.25.3 (L1) Ensure 'Do not enumerate connected users on domain-joined computers' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_Logon/DontEnumerateConnectedUsers"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.25.4 (L1) Ensure 'Enumerate local users on domain-joined computers' is set to 'Disabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/WindowsLogon/EnumerateLocalUsersOnDomainJoinedComputers"
        "value" = "<disabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.25.5 (L1) Ensure 'Turn off app notifications on the lock screen' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/WindowsLogon/DisableLockScreenAppNotifications"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.25.6 (L1) Ensure 'Turn off picture password sign-in' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/CredentialProviders/BlockPicturePassword"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.25.7 (L1) Ensure 'Turn on convenience PIN sign-in' is set to 'Disabled' (Automated)"
        "description" = "Implemented. Note that this does NOT disable Windows Hello for Business."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/CredentialProviders/AllowPINLogon"
        "value" = "<disabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.28.5.1 (L1) Ensure 'Allow network connectivity during connected-standby (on battery)' is set to 'Disabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_Power/DCConnectivityInStandby_2"
        "value" = "<disabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.28.5.2 (L1) Ensure 'Allow network connectivity during connected-standby (plugged in)' is set to 'Disabled' (Automated)"
        "description" = "Opposed. Allowing connection while in approved location enables remote management and there is no effect on battery life."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_Power/ACConnectivityInStandby_2"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.28.5.3 (BL) Ensure 'Allow standby states (S1-S3) when sleeping (on battery)' is set to 'Disabled' (Automated)"
        "description" = "Opposed. Users utilize sleep often. The risk associated with dumping memory is accepted."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Power/AllowStandbyStatesWhenSleepingOnBattery"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.28.5.4 (BL) Ensure 'Allow standby states (S1-S3) when sleeping (plugged in)' is set to 'Disabled' (Automated)"
        "description" = "Opposed"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Power/AllowStandbyWhenSleepingPluggedIn"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.28.5.5 (L1) Ensure 'Require a password when a computer wakes (on battery)' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Power/RequirePasswordWhenComputerWakesOnBattery"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.28.5.6 (L1) Ensure 'Require a password when a computer wakes (plugged in)' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Power/RequirePasswordWhenComputerWakesPluggedIn"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.29.1 (L1) Ensure 'Configure Offer Remote Assistance' is set to 'Disabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/RemoteAssistance/UnsolicitedRemoteAssistance"
        "value" = "<disabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.29.2 (L1) Ensure 'Configure Solicited Remote Assistance' is set to 'Disabled'"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/RemoteAssistance/SolicitedRemoteAssistance"
        "value" = "<disabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.30.1 (L1) Ensure 'Enable RPC Endpoint Mapper Client Authentication' is set to 'Enabled' (Automated)"
        "description" = "Implemented. Safe on Workstations."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/RemoteProcedureCall/RPCEndpointMapperClientAuthentication"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.30.2 (L1) Ensure 'Restrict Unauthenticated RPC clients' is set to 'Enabled: Authenticated' (Automated)"
        "description" = "Implemented. Should be safe for workstations."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/RemoteProcedureCall/RestrictUnauthenticatedRPCClients"
        "value" = "<enabled/>`n<data id=`"RpcRestrictRemoteClientsList`" value=`"1`"/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.38.5.1 (L2) Ensure 'Microsoft Support Diagnostic Tool: Turn on MSDT interactive communication with support provider' is set to 'Disabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_MSDT/MsdtSupportProvider"
        "value" = "<disabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.42.1.1 (L2) Ensure 'Enable Windows NTP Client' is set to 'Enabled' (Automated)"
        "description" = "Implemented. Dont disable."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_W32Time/W32TIME_POLICY_ENABLE_NTPCLIENT"
        "value" = "<enabled/>"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "3.10.42.1.2 (L2) Ensure 'Enable Windows NTP Server' is set to 'Disabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_W32Time/W32TIME_POLICY_ENABLE_NTPSERVER"
        "value" = "<disabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.3.1 (L1) Ensure 'Allow Microsoft accounts to be optional' is set to 'Enabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/AppRuntime/AllowMicrosoftAccountsToBeOptional"
          "value" = "<enabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.3.2 (L2) Ensure 'Block launching Universal Windows apps with Windows Runtime API access from hosted content.' is set to 'Enabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_AppXRuntime/AppxRuntimeBlockHostedAppAccessWinRT"
          "value" = "<enabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.5.1 (L1) Ensure 'Do not preserve zone information in file attachments' is set to 'Disabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./User/Vendor/MSFT/Policy/Config/AttachmentManager/DoNotPreserveZoneInformation"
          "value" = "<disabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.5.2 (L1) Ensure 'Notify antivirus programs when opening attachments' is set to 'Enabled'"
          "description" = "Implemented"
          "omaUri" = "./User/Vendor/MSFT/Policy/Config/AttachmentManager/NotifyAntivirusPrograms"
          "value" = "<enabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.6.1 (L1) Ensure 'Disallow Autoplay for non-volume devices' is set to 'Enabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Autoplay/DisallowAutoplayForNonVolumeDevices"
          "value" = "<enabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.6.2 (L1) Ensure 'Set the default behavior for AutoRun' is set to 'Enabled: Do not execute any autorun commands' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Autoplay/SetDefaultAutoRunBehavior"
          "value" = "<enabled/><data id=`"NoAutorun_Dropdown`" value=`"1`"/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.6.3 (L1) Ensure 'Turn off Autoplay' is set to 'Enabled: All drives' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Autoplay/TurnOffAutoPlay"
          "value" = "<enabled/>`n<data id=`"Autorun_Box`" value=`"255`"/>"
    },
    # 3.11.7.1.1 to 3.11.7.3.2 are implemented in Bitlocker Policy
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.8.1 (L1) Ensure 'Do not display the password reveal button' is set to 'Enabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/CredentialsUI/DisablePasswordReveal"
          "value" = "<enabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.8.2(L1) Ensure 'Enumerate administrator accounts on elevation' is set to 'Disabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/CredentialsUI/EnumerateAdministrators"
          "value" = "<disabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.8.3 (L1) Ensure 'Prevent the use of security questions for local accounts' is set to 'Enabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_CredUI/NoLocalPasswordResetQuestions"
          "value" = "<enabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.15.1.1 (L1) Ensure 'Application: Control Event Log behavior when the log file reaches its maximum size' is set to 'Disabled'(Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/EventLogService/ControlEventLogBehavior"
          "value" = "<disabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.15.1.2 (L1) Ensure 'Application: Specify the maximum log file size (KB)' is set to 'Enabled: 32,768 or greater'(Automated)"
          "description" = "Implemented. 100MB"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/EventLogService/SpecifyMaximumFileSizeApplicationLog"
          "value" = "<enabled/>`n<data id=`"Channel_LogMaxSize`" value=`"102400`"/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.15.2.1 (L1) Ensure 'Security: Control Event Log behavior when the log file reaches its maximum size' is set to 'Disabled'(Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_EventLog/Channel_Log_Retention_2"
          "value" = "<disabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.15.2.2 (L1) Ensure 'Security: Specify the maximum log file size (KB)' is set to 'Enabled: 196,608 or greater'(Automated)"
          "description" = "Implemented. 2GB"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/EventLogService/SpecifyMaximumFileSizeSecurityLog"
          "value" = "<enabled/><data id=`"Channel_LogMaxSize`" value=`"2097152`"/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.15.3.1 (L1) Ensure 'Setup: Control Event Log behavior when the log file reaches its maximum size' is set to 'Disabled'(Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_EventLog/Channel_Log_Retention_3"
          "value" = "<disabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.15.3.2 (L1) Ensure 'Setup: Specify the maximum log file size (KB)' is set to 'Enabled: 32,768 or greater' (Automated)"
          "description" = "Implemented. 100MB"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_EventLog/Channel_LogMaxSize_3"
          "value" = "<enabled/><data id=`"Channel_LogMaxSize`" value=`"102400`"/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.15.4.1 (L1) Ensure 'System: Control Event Log behavior when the log file reaches its maximum size' is set to 'Disabled'"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_EventLog/Channel_Log_Retention_4"
          "value" = "<disabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.15.4.2 (L1) Ensure 'System: Specify the maximum log file size (KB)' is set to 'Enabled: 32,768 or greater'"
          "description" = "Implemented. 200MB"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/EventLogService/SpecifyMaximumFileSizeSystemLog"
          "value" = "<enabled/><data id=`"Channel_LogMaxSize`" value=`"204800`"/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingInteger"
          "displayName" = "3.11.18.1-1 (L1) Ensure 'Configure Windows Defender SmartScreen' is set to 'Enabled: Warn and prevent bypass' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/SmartScreen/EnableSmartScreenInShell"
          "value" = 1
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingInteger"
          "displayName" = "3.11.18.1-2 (L1) Ensure 'Configure Windows Defender SmartScreen' is set to 'Enabled: Warn and prevent bypass' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/SmartScreen/PreventOverrideForFilesInShell"
          "value" = 1
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingInteger"
          "displayName" = "3.11.18.1-3 (L1) Ensure 'Configure Windows Defender SmartScreen' is set to 'Enabled: Warn and prevent bypass' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Browser/AllowSmartScreen"
          "value" = 1
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingInteger"
          "displayName" = "3.11.18.1-4 (L1) Ensure 'Configure Windows Defender SmartScreen' is set to 'Enabled: Warn and prevent bypass' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Browser/PreventSmartScreenPromptOverride"
          "value" = 1
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingInteger"
          "displayName" = "3.11.18.1-5 (L1) Ensure 'Configure Windows Defender SmartScreen' is set to 'Enabled: Warn and prevent bypass' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Browser/PreventSmartScreenPromptOverrideForFiles"
          "value" = 1
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.18.1-6 (L1) Ensure 'Configure Windows Defender SmartScreen' is set to 'Enabled: Warn and prevent bypass' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_WindowsExplorer/EnableSmartScreen"
          "value" = "<enabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.18.2 (L1) Ensure 'Turn off Data Execution Prevention for Explorer' is set to 'Disabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/FileExplorer/TurnOffDataExecutionPreventionForExplorer"
          "value" = "<disabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.18.3 (L1) Ensure 'Turn off heap termination on corruption' is set to 'Disabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/FileExplorer/TurnOffHeapTerminationOnCorruption"
          "value" = "<disabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.18.4 (L1) Ensure 'Turn off shell protocol protected mode' is set to 'Disabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_WindowsExplorer/ShellProtocolProtectedModeTitle_2"
          "value" = "<disabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.20.1 (L1) Ensure 'Prevent the computer from joining a homegroup' is set to 'Enabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_Sharing/DisableHomeGroup"
          "value" = "<enabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.27.1 (L1) Ensure 'Block all consumer Microsoft account user authentication' is set to 'Enabled'' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_MSAPolicy/MicrosoftAccount_DisableUserAuth"
          "value" = "<enabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.28.3.1 (L1) Ensure 'Configure local setting override for reporting to Microsoft MAPS' is set to 'Disabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_MicrosoftDefenderAntivirus/Spynet_LocalSettingOverrideSpynetReporting"
          "value" = "<disabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.28.3.2 (L2) Ensure 'Join Microsoft MAPS' is set to 'Disabled' (Automated)"
          "description" = "Opposed. Set to Advanced (2) for better AV protection"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_MicrosoftDefenderAntivirus/SpynetReporting"
          "value" = "<enabled/>`n<data id=`"SpynetReporting`" value=`"2`"/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.28.10.1 (L2) Ensure 'Configure Watson events' is set to 'Disabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_MicrosoftDefenderAntivirus/Reporting_DisablegenericrePorts"
          "value" = "<disabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.28.11 (L1) Ensure 'Turn off Microsoft Defender Antivirus' is set to 'Disabled'"
          "description" = "Implemented. Caution: Make sure not using an alternative AV"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_MicrosoftDefenderAntivirus/DisableAntiSpywareDefender"
          "value" = "<disabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.31.1 (L1) Ensure 'Prevent users from sharing files within their profile.' is set to 'Enabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./User/Vendor/MSFT/Policy/Config/ADMX_Sharing/NoInplaceSharing"
          "value" = "<enabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.35.1 (L2) Ensure 'Turn off Push To Install service' is set to 'Enabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_PushToInstall/DisablePushToInstall"
          "value" = "<enabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.36.3.2 (L1) Ensure 'Do not allow passwords to be saved' is set to 'Enabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/RemoteDesktopServices/DoNotAllowPasswordSaving"
          "value" = "<enabled/>"
    },
    # Remote Desktop Protocol configurations for remoting into machines
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.36.4.2.1 (L2) Ensure 'Allow users to connect remotely by using Remote Desktop Services' is set to 'Disabled' (Automated)"
          "description" = "Implemented. RDP not allowed"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/RemoteDesktopServices/AllowUsersToConnectRemotely"
          "value" = "<disabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.36.4.3.1 (L2) Ensure 'Do not allow COM port redirection' is set to 'Enabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_TerminalServer/TS_CLIENT_COM"
          "value" = "<enabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.36.4.3.2 (L1) Ensure 'Do not allow drive redirection' is set to 'Enabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/RemoteDesktopServices/DoNotAllowDriveRedirection"
          "value" = "<enabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.36.4.3.3 (L2) Ensure 'Do not allow LPT port redirection' is set to 'Enabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_TerminalServer/TS_CLIENT_LPT"
          "value" = "<enabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.36.4.3.4 (L2) Ensure 'Do not allow supported Plug and Play device redirection' is set to 'Enabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_TerminalServer/TS_CLIENT_PNP"
          "value" = "<enabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.36.4.9.1 (L1) Ensure 'Always prompt for password upon connection' is set to 'Enabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/RemoteDesktopServices/PromptForPasswordUponConnection"
          "value" = "<enabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.36.4.9.2 (L1) Ensure 'Require secure RPC communication' is set to 'Enabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/RemoteDesktopServices/RequireSecureRPCCommunication"
          "value" = "<enabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.36.4.9.3 (L1) Ensure 'Require use of specific security layer for remote (RDP) connections' is set to 'Enabled: SSL' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_TerminalServer/TS_SECURITY_LAYER_POLICY"
          "value" = "<enabled/>`n<data id=`"TS_SECURITY_LAYER`" value=`"2`"/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.36.4.9.4 (L1) Ensure 'Require user authentication for remote connections by using Network Level Authentication' is set to 'Enabled' (Automated)"
          "description" = "Opposed. When using Hello Pin, NLA won't work. RDP will only be allowed through an MFA enabled RMM gateway which will achieve similar security as NLA without breaking RDP. RDP is disabled for most devices by policy, also."
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_TerminalServer/TS_USER_AUTHENTICATION_POLICY"
          "value" = "<disabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.36.4.9.5 (L1) Ensure 'Set client connection encryption level' is set to 'Enabled: High Level' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/RemoteDesktopServices/ClientConnectionEncryptionLevel"
          "value" = "<enabled/>`n<data id=`"TS_ENCRYPTION_LEVEL`" value=`"3`"/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.36.4.10.1 (L2) Ensure 'Set time limit for active but idle Remote Desktop Services sessions' is set to 'Enabled: 15 minutes or less, but not Never (0)' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_TerminalServer/TS_SESSIONS_Idle_Limit_2"
          "value" = "<enabled/>`n<data id=`"TS_SESSIONS_IdleLimitText`" value=`"900000`"/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.36.4.10.2 (L2) Ensure 'Set time limit for disconnected sessions' is set to 'Enabled: 1 minute' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_TerminalServer/TS_SESSIONS_Disconnected_Timeout_2"
          "value" = "<enabled/>`n<data id=`"TS_SESSIONS_EndDisconnected`" value=`"60000`"/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.36.4.11.1 (L1) Ensure 'Do not delete temp folders upon exit' is set to 'Disabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_TerminalServer/TS_TEMP_DELETE"
          "value" = "<disabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.37.1 (L1) Ensure 'Prevent downloading of enclosures' is set to 'Enabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/InternetExplorer/DisableEnclosureDownloading"
          "value" = "<enabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.42.1 (L1) Ensure 'Turn off the offer to update to the latest version of Windows' is set to 'Enabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_WindowsStore/DisableOSUpgrade_2"
          "value" = "<enabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.42.2 (L2) Ensure 'Turn off the Store application' is set to 'Enabled' (Automated)"
          "description" = "Opposed. Store will be available. Using store is better than using downloaded apps."
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_WindowsStore/RemoveWindowsStore_2"
          "value" = "<disabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.49.1 (L2) Ensure 'Prevent Internet Explorer security prompt for Windows Installer scripts' is set to 'Disabled'"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_MSI/SafeForScripting"
          "value" = "<disabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.50.1 (L1) Ensure 'Sign-in and lock last interactive user automatically after a restart' is set to 'Disabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/WindowsLogon/AllowAutomaticRestartSignOn"
          "value" = "<disabled/>"
    },

    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.52.1.1 (L2) Ensure 'Prevent Codec Download (User)' is set to 'Enabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./User/Vendor/MSFT/Policy/Config/ADMX_WindowsMediaPlayer/PolicyCodecUpdate"
          "value" = "<enabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.54.1 (L1) Ensure 'Turn on PowerShell Script Block Logging' is set to 'Enabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/WindowsPowerShell/TurnOnPowerShellScriptBlockLogging"
          "value" = "<enabled/>`n<data id=`"EnableScriptBlockInvocationLogging`" value=`"true`"/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.54.2 (L1) Ensure 'Turn on PowerShell Transcription' is set to 'Enabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ADMX_PowerShellExecutionPolicy/EnableTranscripting"
          "value" = "<enabled/><data id=`"OutputDirectory`" value=`"`"/>`n<data id=`"EnableInvocationHeader`" value=`"false`"/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.55.1.1 (L1) Ensure 'Allow Basic authentication' is set to 'Disabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/RemoteManagement/AllowBasicAuthentication_Client"
          "value" = "<disabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.55.1.2 (L1) Ensure 'Allow unencrypted traffic' is set to 'Disabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/RemoteManagement/AllowUnencryptedTraffic_Client"
          "value" = "<disabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.55.1.3 (L1) Ensure 'Disallow Digest authentication' is set to 'Enabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/RemoteManagement/DisallowDigestAuthentication"
          "value" = "<enabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.55.2.1 (L1) Ensure 'Allow Basic authentication' is set to 'Disabled' (Server) (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/RemoteManagement/AllowBasicAuthentication_Service"
          "value" = "<disabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.55.2.2 (L2) Ensure 'Allow remote server management through WinRM' is set to 'Disabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/RemoteManagement/AllowRemoteServerManagement"
          "value" = "<disabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.55.2.3 (L1) Ensure 'Allow unencrypted traffic' is set to 'Disabled' (Server) (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/RemoteManagement/AllowUnencryptedTraffic_Service"
          "value" = "<disabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.55.2.4 (L1) Ensure 'Disallow WinRM from storing RunAs credentials' is set to 'Enabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/RemoteManagement/DisallowStoringOfRunAsCredentials"
          "value" = "<enabled/>"
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingString"
          "displayName" = "3.11.56.1 (L2) Ensure 'Allow Remote Shell Access' is set to 'Disabled' (Automated)"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/RemoteShell/AllowRemoteShellAccess"
          "value" = "<disabled/>"
    },

    # This configuration is applied successfully, but Tenable audit reports it was not set.
    @{
          "@odata.type" = "#microsoft.graph.omaSettingInteger"
          "displayName" = "5.1 (L1) Ensure 'Account Logon Audit Credential Validation' is set to 'Success and Failure'"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Audit/AccountLogon_AuditCredentialValidation"
          "value" = 3
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingInteger"
          "displayName" = "5.2 (L1) Ensure 'Account Logon Logoff Audit Account Lockout' is set to include 'Failure'"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Audit/AccountLogonLogoff_AuditAccountLockout"
          "value" = 2
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingInteger"
          "displayName" = "5.3 (L1) Ensure 'Account Logon Logoff Audit Group Membership' is set to include 'Success'"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Audit/AccountLogonLogoff_AuditGroupMembership"
          "value" = 1
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingInteger"
          "displayName" = "5.4 (L1) Ensure 'Account Logon Logoff Audit Logoff' is set to include 'Success'"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Audit/AccountLogonLogoff_AuditLogoff"
          "value" = 1 # Windows Default Setting and CIS Recommended Setting
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingInteger"
          "displayName" = "5.5 (L1) Ensure 'Account Logon Logoff Audit Logon' is set to 'Success and Failure'"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Audit/AccountLogonLogoff_AuditLogon"
          "value" = 3
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingInteger"
          "displayName" = "5.6 (L1) Ensure 'Account Management Audit Application Group Management' is set to 'Success and Failure'"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Audit/AccountManagement_AuditApplicationGroupManagement"
          "value" = 3
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingInteger"
          "displayName" = "5.7 (L1) Ensure 'Audit Authentication Policy Change' is set to include 'Success'"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Audit/PolicyChange_AuditAuthenticationPolicyChange"
          "value" = 1 # Windows Default Setting and CIS Recommended Setting
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingInteger"
          "displayName" = "5.8 (L1) Ensure 'Audit Authorization Policy Change' is set to include 'Success'"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Audit/PolicyChange_AuditAuthorizationPolicyChange"
          "value" = 1
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingInteger"
          "displayName" = "5.10 (L1) Ensure 'Audit File Share Access' is set to 'Success and Failure'"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Audit/ObjectAccess_AuditFileShare"
          "value" = 3
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingInteger"
          "displayName" = "5.11 (L1) Ensure 'Audit Other Logon Logoff Events' is set to 'Success and Failure'"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Audit/AccountLogonLogoff_AuditOtherLogonLogoffEvents"
          "value" = 3
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingInteger"
          "displayName" = "5.12 (L1) Ensure 'Audit Security Group Management' is set to include 'Success'"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Audit/AccountManagement_AuditSecurityGroupManagement"
          "value" = 1 # Windows Default Setting and CIS Recommended Setting
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingInteger"
          "displayName" = "5.13 (L1) Ensure 'Audit Security System Extension' is set to include 'Success'"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Audit/System_AuditSecuritySystemExtension"
          "value" = 1
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingInteger"
          "displayName" = "5.14 (L1) Ensure 'Audit Special Logon' is set to include 'Success'"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Audit/AccountLogonLogoff_AuditSpecialLogon"
          "value" = 1 # Windows Default Setting and CIS Recommended Setting
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingInteger"
          "displayName" = "5.15 (L1) Ensure 'Audit User Account Management' is set to 'Success and Failure'"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Audit/AccountManagement_AuditUserAccountManagement"
          "value" = 3
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingInteger"
          "displayName" = "5.16 (L1) Ensure 'Detailed Tracking Audit PNP Activity' is set to include 'Success'"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Audit/DetailedTracking_AuditPNPActivity"
          "value" = 1
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingInteger"
          "displayName" = "5.17 (L1) Ensure 'Detailed Tracking Audit Process Creation' is set to include 'Success'"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Audit/DetailedTracking_AuditProcessCreation"
          "value" = 1
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingInteger"
          "displayName" = "5.18 (L1) Ensure 'Object Access Audit Detailed File Share' is set to include 'Failure'"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Audit/ObjectAccess_AuditDetailedFileShare"
          "value" = 2
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingInteger"
          "displayName" = "5.19 (L1) Ensure 'Object Access Audit Other Object Access Events' is set to 'Success and Failure'"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Audit/ObjectAccess_AuditOtherObjectAccessEvents"
          "value" = 3
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingInteger"
          "displayName" = "5.20 (L1) Ensure 'Object Access Audit Removable Storage' is set to 'Success and Failure'"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Audit/ObjectAccess_AuditRemovableStorage"
          "value" = 3
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingInteger"
          "displayName" = "5.21 (L1) Ensure 'Policy Change Audit MPSSVC Rule Level Policy Change' is set to 'Success and Failure'"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Audit/PolicyChange_AuditMPSSVCRuleLevelPolicyChange"
          "value" = 3
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingInteger"
          "displayName" = "5.22 (L1) Ensure 'Policy Change Audit Other Policy Change Events' is set to include 'Failure'"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Audit/PolicyChange_AuditOtherPolicyChangeEvents"
          "value" = 2
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingInteger"
          "displayName" = "5.23 (L1) Ensure 'Privilege Use Audit Sensitive Privilege Use' is set to 'Success and Failure'"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Audit/PrivilegeUse_AuditSensitivePrivilegeUse"
          "value" = 3
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingInteger"
          "displayName" = "5.24 (L1) Ensure 'System Audit IPsec Driver' is set to 'Success and Failure'"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Audit/System_AuditIPsecDriver"
          "value" = 3
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingInteger"
          "displayName" = "5.25 (L1) Ensure 'System Audit Other System Events' is set to 'Success and Failure'"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Audit/System_AuditOtherSystemEvents"
          "value" = 3 # Windows Default Setting and CIS Recommended Setting
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingInteger"
          "displayName" = "5.26 (L1) Ensure 'System Audit Security State Change' is set to include 'Success'"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Audit/System_AuditSecurityStateChange"
          "value" = 1 # Windows Default Setting and CIS Recommended Setting
    },
    @{
          "@odata.type" = "#microsoft.graph.omaSettingInteger"
          "displayName" = "5.27 (L1) Ensure 'System Audit System Integrity' is set to 'Success and Failure'"
          "description" = "Implemented"
          "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Audit/System_AuditSystemIntegrity"
          "value" = 3 # Windows Default Setting and CIS Recommended Setting
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "11.1 (L2) Ensure 'Allow Camera' is set to 'Not allowed' (Automated)"
        "description" = "Opposed. Cameras are used for Zoom, Teams, etc."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Camera/AllowCamera"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "21.1 (L1) Ensure 'Allow Behavior Monitoring' is set to 'Allowed' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Defender/AllowBehaviorMonitoring"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "21.2 (L1) Ensure 'Allow Email Scanning' is set to 'Allowed' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Defender/AllowEmailScanning"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "21.3 (L1) Ensure 'Allow Full Scan Removable Drive Scanning' is set to 'Allowed' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Defender/AllowFullScanRemovableDriveScanning"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "21.4 (L1) Ensure 'Allow Realtime Monitoring' is set to 'Allowed' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Defender/AllowRealtimeMonitoring"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "21.5 (L1) Ensure 'Allow scanning of all downloaded files and attachments' is set to 'Allowed' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Defender/AllowIOAVProtection"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "21.6 (L1) Ensure 'Allow Script Scanning' is set to 'Allowed' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Defender/AllowScriptScanning"
        "value" = 1
    },
    # 21.7 Attack Surface Reduction rules will be configured in a separate configuration
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "21.8 (L2) Ensure 'Enable File Hash Computation' is set to 'Enable' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Defender/Configuration/EnableFileHashComputation"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "21.9 (L1) Ensure 'Enable Network Protection' is set to 'Enabled (block mode)' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Defender/EnableNetworkProtection"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "21.10 (L1) Ensure 'PUA Protection' is set to 'PUA Protection on' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Defender/PUAProtection"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "22.1 (L1) Ensure 'DO Download Mode' is NOT set to 'HTTP blended with Internet Peering' (Automated)"
        "description" = "Implemented. 0 (HTTP only)"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/DeliveryOptimization/DODownloadMode"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "23.1 (L1) Ensure 'Enable Virtualization Based Security' is set to 'Enable virtualization based security' (Automated)"
        "description" = "Implemented."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/DeviceGuard/EnableVirtualizationBasedSecurity"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "23.2 (L1) Ensure 'Configure System Guard Launch' is set to 'Unmanaged Enables Secure Launch if supported by hardware' (Automated)"
        "description" = "Implemented."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/DeviceGuard/ConfigureSystemGuardLaunch"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "23.3 (L1) Ensure 'Require Platform Security Features' is set to 'Turns on VBS with Secure Boot' or higher (Automated)"
        "description" = "Implemented. Caution. Requires Intel VTX, AMDV, secure boot and compatible drivers."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/DeviceGuard/RequirePlatformSecurityFeatures"
        "value" = 3
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "23.4 (L1) Ensure 'Credential Guard' is set to 'Enabled with UEFI lock' (Automated)"
        "description" = "Implemented. Caution. Requires Intel VTX, AMDV, secure boot, and compatible drivers."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/DeviceGuard/LsaCfgFlags"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "24.* This setting must be set so that various options under CIS 24.1 through 24.4 will work."
        "description" = "Must be set to apply CIS requirements."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/DeviceLock/DevicePasswordEnabled"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "24.1 (L1) Ensure 'Alphanumeric Device Password Required' is set to 'Password, Numeric PIN, or Alphanumeric PIN required' (Automated)"
        "description" = "Implemented."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/DeviceLock/AlphanumericDevicePasswordRequired"
        "value" = 2
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "24.2 (L1) Ensure 'Device Password Expiration' is set to '365 or fewer days, but not 0' (Automated)"
        "description" = "Opposed. Never expire."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/DeviceLock/DevicePasswordExpiration"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "24.3 (L1) Ensure 'Device Password History' is set to '24 or more password(s)'' (Automated)"
        "description" = "Opposed."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/DeviceLock/DevicePasswordHistory"
        "value" = 0
    },
    # This configuration option is set by Intune, but is not used if Windows Hello for Business is being used. This results in audit failure. CIS does not have a recommendation for PIN complexity for Windows Hello. Additionally, I prefer all numerical for PINs when using WHfB.
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "24.4 (L1) Ensure 'Min Device Password Complex Characters' is set to 'Digits lowercase letters and uppercase letters are required'"
        "description" = "Implemented."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/DeviceLock/MinDevicePasswordComplexCharacters"
        "value" = 3
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "24.5 (L1) Ensure 'Min Device Password Length' is set to '14 or more character(s)'"
        "description" = "Implemented. This does not set the min length for Windows Hello. The PassportForWork setting controls Hello Pin"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/DeviceLock/MinDevicePasswordLength"
        "value" = 14
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "24.6 (L1) Ensure 'Minimum Password Age' is set to '1 or more day(s)' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/DeviceLock/MinimumPasswordAge"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "30.1 (L1) Ensure 'Allow Cortana' is set to 'Block' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Experience/AllowCortana"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "30.2 (L1) Ensure 'Allow Spotlight Collection (User)' is set to '0' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./User/Vendor/MSFT/Policy/Config/Experience/AllowSpotlightCollection"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "30.3 (L2) Ensure 'Allow Windows Spotlight (User)' is set to 'Block' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./User/Vendor/MSFT/Policy/Config/Experience/AllowWindowsSpotlight"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "30.4 (L1) Ensure 'Disable Consumer Account State Content' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Experience/DisableConsumerAccountStateContent"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "30.5 (L1) Ensure 'Do not show feedback notifications' is set to 'Feedback notifications are disabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Experience/DoNotShowFeedbackNotifications"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingBoolean"
        "displayName" = "35.1 (L1) Ensure 'Enable Domain Network Firewall' is set to 'True' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Vendor/MSFT/Firewall/MdmStore/DomainProfile/EnableFirewall"
        "value" = $true
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "35.2 (L1) Ensure 'Enable Domain Network Firewall: Default Inbound Action for Domain Profile' is set to 'Block' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Vendor/MSFT/Firewall/MdmStore/DomainProfile/DefaultInboundAction"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingBoolean"
        "displayName" = "35.3 (L1) Ensure 'Enable Domain Network Firewall: Disable Inbound Notifications' is set to 'True' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Vendor/MSFT/Firewall/MdmStore/DomainProfile/DisableInboundNotifications"
        "value" = $true
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingBoolean"
        "displayName" = "35.4 (L1) Ensure 'Enable Domain Network Firewall: Enable Log Dropped Packets' is set to 'Yes: Enable Logging Of Dropped Packets' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Vendor/MSFT/Firewall/MdmStore/DomainProfile/EnableLogDroppedPackets"
        "value" = $true
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingBoolean"
        "displayName" = "35.5 (L1) Ensure 'Enable Domain Network Firewall: Enable Log Success Connections' is set to 'Enable Logging Of Successful Connections' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Vendor/MSFT/Firewall/MdmStore/DomainProfile/EnableLogSuccessConnections"
        "value" = $true
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "35.6 (L1) Ensure 'Enable Domain Network Firewall: Log File Path' is set to '%SystemRoot%\System32\logfiles\firewall\domainfw.log' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Vendor/MSFT/Firewall/MdmStore/DomainProfile/LogFilePath"
        "value" = "%SystemRoot%\System32\logfiles\firewall\domainfw.log"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "35.7 (L1) Ensure 'Enable Domain Network Firewall: Log Max File Size' is set to '16,384 KB or greater' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Vendor/MSFT/Firewall/MdmStore/DomainProfile/LogMaxFileSize"
        "value" = "32767"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingBoolean"
        "displayName" = "35.8 (L1) Ensure 'Enable Private Network Firewall' is set to 'True' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Vendor/MSFT/Firewall/MdmStore/PrivateProfile/EnableFirewall"
        "value" = $true
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "35.9 (L1) Ensure 'Enable Private Network Firewall: Default Inbound Action for Private Profile' is set to 'Block' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Vendor/MSFT/Firewall/MdmStore/PrivateProfile/DefaultInboundAction"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingBoolean"
        "displayName" = "35.10 (L1) Ensure 'Enable Private Network Firewall: Disable Inbound Notifications' is set to 'True' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Vendor/MSFT/Firewall/MdmStore/PrivateProfile/DisableInboundNotifications"
        "value" = $true
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingBoolean"
        "displayName" = "35.11 (L1) Ensure 'Enable Private Network Firewall: Enable Log Success Connections' is set to 'Enable Logging Of Successful Connections' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Vendor/MSFT/Firewall/MdmStore/PrivateProfile/EnableLogSuccessConnections"
        "value" = $true
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingBoolean"
        "displayName" = "35.12 (L1) Ensure 'Enable Private Network Firewall: Enable Log Dropped Packets' is set to 'Yes: Enable Logging Of Dropped Packets' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Vendor/MSFT/Firewall/MdmStore/PrivateProfile/EnableLogDroppedPackets"
        "value" = $true
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "35.13 (L1) Ensure 'Enable Private Network Firewall: Log File Path' is set to '%SystemRoot%\System32\logfiles\firewall\Privatefw.log' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Vendor/MSFT/Firewall/MdmStore/PrivateProfile/LogFilePath"
        "value" = "%SystemRoot%\System32\logfiles\firewall\privatefw.log"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "35.14 (L1) Ensure 'Enable Private Network Firewall: Log Max File Size' is set to '16,384 KB or greater' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Vendor/MSFT/Firewall/MdmStore/PrivateProfile/LogMaxFileSize"
        "value" = "32767"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingBoolean"
        "displayName" = "35.15 (L1) Ensure 'Enable Public Network Firewall' is set to 'True' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Vendor/MSFT/Firewall/MdmStore/PublicProfile/EnableFirewall"
        "value" = $true
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingBoolean"
        "displayName" = "35.16 (L1) Ensure 'Enable Public Network Firewall: Allow Local Ipsec Policy Merge' is set to 'False' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Vendor/MSFT/Firewall/MdmStore/PublicProfile/AllowLocalIpsecPolicyMerge"
        "value" = $false
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingBoolean"
        "displayName" = "35.17 (L1) Ensure 'Enable Public Network Firewall: Allow Local Policy Merge' is set to 'False' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Vendor/MSFT/Firewall/MdmStore/PublicProfile/AllowLocalPolicyMerge"
        "value" = $false
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "35.18 (L1) Ensure 'Enable Public Network Firewall: Default Inbound Action for Public Profile' is set to 'Block' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Vendor/MSFT/Firewall/MdmStore/PublicProfile/DefaultInboundAction"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingBoolean"
        "displayName" = "35.19 (L1) Ensure 'Enable Public Network Firewall: Disable Inbound Notifications' is set to 'True' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Vendor/MSFT/Firewall/MdmStore/PublicProfile/DisableInboundNotifications"
        "value" = $true
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingBoolean"
        "displayName" = "35.20 (L1) Ensure 'Enable Public Network Firewall: Enable Log Dropped Packets' is set to 'Yes: Enable Logging Of Dropped Packets' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Vendor/MSFT/Firewall/MdmStore/PublicProfile/EnableLogDroppedPackets"
        "value" = $true
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingBoolean"
        "displayName" = "35.21 (L1) Ensure 'Enable Public Network Firewall: Enable Log Success Connections' is set to 'Enable Logging Of Successful Connections' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Vendor/MSFT/Firewall/MdmStore/PublicProfile/EnableLogSuccessConnections"
        "value" = $true
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "35.22 (L1) Ensure 'Enable Public Network Firewall: Log File Path' is set to '%SystemRoot%\System32\logfiles\firewall\publicfw.log' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Vendor/MSFT/Firewall/MdmStore/PublicProfile/LogFilePath"
        "value" = "%SystemRoot%\System32\logfiles\firewall\Publicfw.log"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "35.23 (L1) Ensure 'Enable Public Network Firewall: Log Max File Size' is set to '16,384 KB or greater' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Vendor/MSFT/Firewall/MdmStore/PublicProfile/LogMaxFileSize"
        "value" = "32767"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "42.1 (L1) Ensure 'Enable insecure guest logons' is set to 'Disabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LanmanWorkstation/EnableInsecureGuestLogons"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "43.1 (L2) Ensure 'Disallow KMS Client Online AVS Validation' is set to 'Allow' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Licensing/DisallowKMSClientOnlineAVSValidation"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "45.1 (L1) Ensure 'Accounts: Block Microsoft accounts' is set to 'Users can't add or log on with Microsoft accounts' (Automated)"
        "description" = "Implemented. Can still login with Company Tenant/Intune Account. Only blocks consumer Microsoft accounts."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/Accounts_BlockMicrosoftAccounts"
        "value" = 3
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "45.2 (L1) Ensure 'Accounts: Enable Guest account status' is set to 'Disabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/Accounts_EnableGuestAccountStatus"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "45.3 (L1) Ensure 'Accounts: Limit local account use of blank passwords to console logon only' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/Accounts_LimitLocalAccountUseOfBlankPasswordsToConsoleLogonOnly"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "45.4 (L1) Configure 'Accounts: Rename administrator account' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/Accounts_RenameAdministratorAccount"
        "value" = "nonsa"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "45.5 (L1) Configure 'Accounts: Rename guest account' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/Accounts_RenameGuestAccount"
        "value" = "noguest"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "45.6 (L2) Ensure 'Devices: Prevent users from installing printer drivers when connecting to shared printers' is set to 'Enable' (Automated)"
        "description" = "Implemented. This setting does not affect the ability to add a local printer."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/Devices_PreventUsersFromInstallingPrinterDriversWhenConnectingToSharedPrinters"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "45.7 (L1) Ensure 'Interactive logon: Do not display last signed-in' is set to 'Enabled' (Automated)"
        "description" = "Opposed: By showing the last user, users can tell if someone else signed in to their machine since their name will no longer show."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/InteractiveLogon_DoNotDisplayLastSignedIn"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "45.8 (L1) Ensure 'Interactive logon: Do not require CTRL+ALT+DEL' is set to 'Disabled' (Automated)"
        "description" = "Opposed: We will not require users to ctrl+alt+del."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/InteractiveLogon_DoNotRequireCTRLALTDEL"
        "value" = 1
    },
    # Moved into a separate policy
    <#@{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "45.9 (L1) Ensure 'Interactive logon: Machine inactivity limit' is set to '900 or fewer second(s), but not 0' (Automated)"
        "description" = "Implemented. 300 seconds."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/InteractiveLogon_MachineInactivityLimit"
        "value" = 300
    },#>
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "45.10 (L1) Configure 'Interactive logon: Message text for users attempting to log on' (Automated)"
        "description" = "Implemented."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/InteractiveLogon_MessageTextForUsersAttemptingToLogOn"
        "value" = "$($logon_message)"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "45.11 (L1) Configure 'Interactive logon: Message title for users attempting to log on' (Automated)"
        "description" = "Implemented."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/InteractiveLogon_MessageTitleForUsersAttemptingToLogOn"
        "value" = "$($logon_title)"
    },
    # Intune is currently unable to apply this to Windows 11 devices (errors when applying). Policy will be set in another configration.
    <#@{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "45.12 (L1) Ensure 'Interactive logon: Smart card removal behavior' is set to 'Lock Workstation' or higher (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/InteractiveLogon_SmartCardRemovalBehavior"
        "value" = 3
    },#>
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "45.13 (L1) Ensure 'Microsoft network client: Digitally sign communications (always)' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/MicrosoftNetworkClient_DigitallySignCommunicationsAlways"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "45.14 (L1) Ensure 'Microsoft network client: Digitally sign communications (if server agrees)' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/MicrosoftNetworkClient_DigitallySignCommunicationsIfServerAgrees"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "45.15 (L1) Ensure 'Microsoft network client: Send unencrypted password to third-party SMB servers' is set to 'Disabled'"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/MicrosoftNetworkClient_SendUnencryptedPasswordToThirdPartySMBServers"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "45.16 (L1) Ensure 'Microsoft network server: Digitally sign communications (always)' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/MicrosoftNetworkServer_DigitallySignCommunicationsAlways"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "45.17 (L1) Ensure 'Microsoft network server: Digitally sign communications (if client agrees)' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/MicrosoftNetworkServer_DigitallySignCommunicationsIfClientAgrees"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "45.18 (L1) Ensure 'Network access: Do not allow anonymous enumeration of SAM accounts' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/NetworkAccess_DoNotAllowAnonymousEnumerationOfSAMAccounts"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "45.19 (L1) Ensure 'Network access: Do not allow anonymous enumeration of SAM accounts and shares' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/NetworkAccess_DoNotAllowAnonymousEnumerationOfSAMAccountsAndShares"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "45.20 (L1) Ensure 'Network access: Restrict anonymous access to Named Pipes and Shares' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/NetworkAccess_RestrictAnonymousAccessToNamedPipesAndShares"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "45.21 (L1) Ensure 'Network access: Restrict clients allowed to make remote calls to SAM' is set to 'Administrators: Remote Access: Allow' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/NetworkAccess_RestrictClientsAllowedToMakeRemoteCallsToSAM"
        "value" = "O:BAG:BAD:(A;;RC;;;BA)"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "45.22 (L1) Ensure 'Network security: Allow Local System to use computer identity for NTLM' is set to 'Allow' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/NetworkSecurity_AllowLocalSystemToUseComputerIdentityForNTLM"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "45.23 (L1) Ensure 'Network Security: Allow PKU2U authentication requests' is set to 'Block' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/NetworkSecurity_AllowPKU2UAuthenticationRequests"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "45.24 (L1) Ensure 'Network security: Do not store LAN Manager hash value on next password change' is set to 'Enabled'"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/NetworkSecurity_DoNotStoreLANManagerHashValueOnNextPasswordChange"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "45.25 (L1) Ensure 'Network security: LAN Manager authentication level' is set to 'Send LM and NTLMv2 responses only. Refuse LM and NTLM' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/NetworkSecurity_LANManagerAuthenticationLevel"
        "value" = 5
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "45.26 (L1) Ensure 'Network security: Minimum session security for NTLM SSP based (including secure RPC) clients' is set to 'Require NTLM and 128-bit encryption' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/NetworkSecurity_MinimumSessionSecurityForNTLMSSPBasedClients"
        "value" = 537395200
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "45.27 (L1) Ensure 'Network security: Minimum session security for NTLM SSP based (including secure RPC) servers' is set to 'Require NTLM and 128-bit encryption' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/NetworkSecurity_MinimumSessionSecurityForNTLMSSPBasedServers"
        "value" = 537395200
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "45.28 (L1) Ensure 'Network security: Restrict NTLM: Audit Incoming NTLM Traffic' is set to 'Enable auditing for all accounts' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/NetworkSecurity_RestrictNTLM_AuditIncomingNTLMTraffic"
        "value" = 2
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "45.29 (L1) Ensure 'User Account Control: Behavior of the elevation prompt for administrators' is set to 'Prompt for consent on the secure desktop' or higher (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/UserAccountControl_BehaviorOfTheElevationPromptForAdministrators"
        "value" = 2
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "45.30 (L1) Ensure 'User Account Control: Behavior of the elevation prompt for standard users' is set to 'Automatically deny elevation requests' (Automated)"
        "description" = "Opposed. If this is denied, then elevating using a LAPS password is also impossible."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/UserAccountControl_BehaviorOfTheElevationPromptForStandardUsers"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "45.31 (L1) Ensure 'User Account Control: Detect application installations and prompt for elevation' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/UserAccountControl_DetectApplicationInstallationsAndPromptForElevation"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "45.32 (L1) Ensure 'User Account Control: Only elevate UIAccess applications that are installed in secure locations' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/UserAccountControl_OnlyElevateUIAccessApplicationsThatAreInstalledInSecureLocations"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "45.33 (L1) Ensure 'User Account Control: Use Admin Approval Mode' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/UserAccountControl_UseAdminApprovalMode"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "45.34 (L1) Ensure 'User Account Control: Switch to the secure desktop when prompting for elevation' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/UserAccountControl_SwitchToTheSecureDesktopWhenPromptingForElevation"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "45.35 (L1) Ensure 'User Account Control: Run all administrators in Admin Approval Mode' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/UserAccountControl_RunAllAdministratorsInAdminApprovalMode"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "45.36 (L1) Ensure 'User Account Control: Virtualize file and registry write failures to per-user locations' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/LocalPoliciesSecurityOptions/UserAccountControl_VirtualizeFileAndRegistryWriteFailuresToPerUserLocations"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "48.1 (L1) Ensure 'Allow apps from the Microsoft app store to auto update' is set to 'Allowed' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ApplicationManagement/AllowAppStoreAutoUpdate"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "48.2 (L1) Ensure 'Allow Game DVR' is set to 'Block' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ApplicationManagement/AllowGameDVR"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "48.3 (L2) Ensure 'Disable Store Originated Apps' is set to 'Enabled' (Automated)"
        "description" = "Opposed. We will use store apps for deployment in some cases."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ApplicationManagement/DisableStoreOriginatedApps"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "48.4 (L1) Ensure 'MSI Allow user control over installs' is set to 'Disabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ApplicationManagement/MSIAllowUserControlOverInstall"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "48.5 (L1) Ensure 'MSI Always install with elevated privileges' is set to 'Disabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ApplicationManagement/MSIAlwaysInstallWithElevatedPrivileges"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "48.6 (L1) Ensure 'MSI Always install with elevated privileges (User)' is set to 'Disabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./User/Vendor/MSFT/Policy/Config/ApplicationManagement/MSIAlwaysInstallWithElevatedPrivileges"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "48.7 (L1) Ensure 'Require Private Store Only' is set to 'Only Private store is enabled' (Automated)"
        "description" = "Opposed. All store apps will be accessible."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ApplicationManagement/RequirePrivateStoreOnly"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "58.1 (L2) Ensure 'Allow Cross Device Clipboard' is set to 'Block' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Privacy/AllowCrossDeviceClipboard"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "58.2 (L1) Ensure 'Allow Input Personalization' is set to 'Block' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Privacy/AllowInputPersonalization"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "58.3 (L2) Ensure 'Disable Advertising ID' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Privacy/DisableAdvertisingID"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "58.4 (L1) Ensure 'Let Apps Activate With Voice Above Lock' is set to 'Enabled: Force Deny'"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Privacy/LetAppsActivateWithVoiceAboveLock"
        "value" = 2
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "58.5 (L2) Ensure 'Upload User Activities' is set to 'Disabled' (Automated)"
        "description" = "Implemented. Does not disable Defender Device Timeline."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Privacy/UploadUserActivities"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "60.1 (L2) Ensure 'Allow Cloud Search' is set to 'Not allowed' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Search/AllowCloudSearch"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "60.2 (L1) Ensure 'Allow Indexing Encrypted Stores Or Items' is set to 'Block' (Automated)"
        "description" = "Opposed. When Bitlocker is enabled, indexing of encrypted files allows search to work better."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Search/AllowIndexingEncryptedStoresOrItems"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "60.3 (L1) Ensure 'Allow Search To Use Location' is set to 'Block' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Search/AllowSearchToUseLocation"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "60.4 (L2) Ensure 'Allow search highlights' is set to '0' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Search/AllowSearchHighlights"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "62.1 (L2) Ensure 'Allow Online Tips' is set to 'Block' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Settings/AllowOnlineTips"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "64.1.1 (L1) Ensure 'Notify Malicious' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/WebThreatDefense/NotifyMalicious"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "64.1.2 (L1) Ensure 'Notify Password Reuse' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/WebThreatDefense/NotifyPasswordReuse"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "64.1.3 (L1) Ensure 'Notify Unsafe App' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/WebThreatDefense/NotifyUnsafeApp"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "64.1.4 (L1) Ensure 'Service Enabled' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/WebThreatDefense/ServiceEnabled"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "67.1 (L1) Ensure 'Allow Telemetry' is set to 'Basic' (Automated)"
        "description" = "Implemented. 1. Off setting is no longer available in Windows 11."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/System/AllowTelemetry"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "67.2 (L2) Ensure 'Allow Font Providers' is set to 'Not allowed' (Automated)"
        "description" = "Opposed. We will allow fonts."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/System/AllowFontProviders"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "67.3 (L2) Ensure 'Disable One Drive File Sync' is set to 'Sync Disabled' (Automated)"
        "description" = "Opposed. OneDrive is used as user's backup and file history and has been allowed."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/System/DisableOneDriveFileSync"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "67.4 (L1) Ensure 'Enable OneSettings Auditing' is set to 'Enabled' (Automated)"
        "description" = "Implemented."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/System/EnableOneSettingsAuditing"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "67.5 (L1) Ensure 'Limit Diagnostic Log Collection' is set to 'Enabled' (Automated)"
        "description" = "Implemented."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/System/LimitDiagnosticLogCollection"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "67.6 (L1) Ensure 'Limit Dump Collection' is set to 'Enabled' (Automated)"
        "description" = "Implemented."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/System/LimitDumpCollection"
        "value" = 1
    },
    # 69.1 to 69.45 implemented using PowerShell script due to lack of capability to apply using OMAURI
    # 74.1 implemented in the Blank Policy configuration due to issue with applying using OMAURI
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "74.2 (L1) Ensure 'Access From Network' is set to 'Administrators, Remote Desktop Users' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/UserRights/AccessFromNetwork"
        "value" = "Administrators$([char]0xF000)Remote Desktop Users"
    },
    # 74.3 implemented in the Blank Policy configuration due to issue with applying using OMAURI
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "74.4 (L1) Ensure 'Allow Local Log On' is set to 'Administrators, Users' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/UserRights/AllowLocalLogOn"
        "value" = "Administrators$([char]0xF000)Users"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "74.5 (L1) Ensure 'Backup Files And Directories' is set to 'Administrators' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/UserRights/BackupFilesAndDirectories"
        "value" = "Administrators"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "74.6 (L1) Ensure 'Change System Time' is set to 'Administrators, LOCAL SERVICE' (Automated)"
        "description" = "Implemented."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/UserRights/ChangeSystemTime"
        "value" = "Administrators$([char]0xF000)LOCAL SERVICE"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "74.7 (L1) Ensure 'Create Global Objects' is set to 'Administrators, LOCAL SERVICE, NETWORK SERVICE, SERVICE' (Automated)"
        "description" = "Implemented."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/UserRights/CreateGlobalObjects"
        "value" = "Administrators$([char]0xF000)LOCAL SERVICE$([char]0xF000)NETWORK SERVICE$([char]0xF000)SERVICE"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "74.8 (L1) Ensure 'Create Page File' is set to 'Administrators' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/UserRights/CreatePageFile"
        "value" = "Administrators"
    },
    # 74.9 implemented in the Blank Policy configuration due to issue with applying using OMAURI
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "74.10 (L1) Configure 'Create Symbolic Links' (Automated)"
        "description" = "Implemented."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/UserRights/CreateSymbolicLinks"
        "value" = "Administrators"
    },
    # 74.11 implemented in the Blank Policy configuration due to issue with applying using OMAURI
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "74.12 (L1) Ensure 'Debug Programs' is set to 'Administrators' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/UserRights/DebugPrograms"
        "value" = "Administrators"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "74.13 (L1) Ensure 'Deny Access From Network' to include 'Guests, Local account' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/UserRights/DenyAccessFromNetwork"
        "value" = "Guests$([char]0xF000)Local account"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "74.14 (L1) Ensure 'Deny Local Log On' to include 'Guests' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/UserRights/DenyLocalLogOn"
        "value" = "Guests"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "74.15 (L1) Ensure 'Deny Remote Desktop Services Log On' to include 'Guests, Local account' (Automated)"
        "description" = "Opposed. Allow local account (for IT RDP to their machines). Only disallow Guests."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/UserRights/DenyRemoteDesktopServicesLogOn"
        "value" = "Guests$([char]0xF000)Local account"
    },
    # 74.16 implemented in the Blank Policy configuration due to issue with applying using OMAURI
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "74.17 (L1) Ensure 'Generate Security Audits' is set to 'LOCAL SERVICE, NETWORK SERVICE' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/UserRights/GenerateSecurityAudits"
        "value" = "LOCAL SERVICE$([char]0xF000)NETWORK SERVICE"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "74.18 (L1) Ensure 'Impersonate Client' is set to 'Administrators, LOCAL SERVICE, NETWORK SERVICE, SERVICE' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/UserRights/ImpersonateClient"
        "value" = "Administrators$([char]0xF000)LOCAL SERVICE$([char]0xF000)NETWORK SERVICE$([char]0xF000)SERVICE"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "74.19 (L1) Ensure 'Increase Scheduling Priority' is set to 'Administrators, Window Manager\Window Manager Group' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/UserRights/IncreaseSchedulingPriority"
        "value" = "Administrators$([char]0xF000)Window Manager\Window Manager Group"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "74.20 (L1) Ensure 'Load Unload Device Drivers' is set to 'Administrators' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/UserRights/LoadUnloadDeviceDrivers"
        "value" = "Administrators"
    },
    # 74.21 implemented in the Blank Policy configuration due to issue with applying using OMAURI  
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "74.22 (L1) Ensure 'Manage auditing and security log' is set to 'Administrators' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/UserRights/ManageAuditingAndSecurityLog"
        "value" = "Administrators"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "74.23 (L1) Ensure 'Manage Volume' is set to 'Administrators' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/UserRights/ManageVolume"
        "value" = "Administrators"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "74.24 (L1) Ensure 'Modify Firmware Environment' is set to 'Administrators' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/UserRights/ModifyFirmwareEnvironment"
        "value" = "Administrators"
    },
    # 74.25 implemented in the Blank Policy configuration due to issue with applying using OMAURI
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "74.26 (L1) Ensure 'Profile Single Process' is set to 'Administrators' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/UserRights/ProfileSingleProcess"
        "value" = "Administrators"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "74.27 (L1) Ensure 'Remote Shutdown' is set to 'Administrators' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/UserRights/RemoteShutdown"
        "value" = "Administrators"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "74.28 (L1) Ensure 'Restore Files And Directories' is set to 'Administrators' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/UserRights/RestoreFilesAndDirectories"
        "value" = "Administrators"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "74.29 (L1) Ensure 'Take Ownership' is set to 'Administrators' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/UserRights/TakeOwnership"
        "value" = "Administrators"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "75.1 (L1) Ensure 'Hypervisor Enforced Code Integrity' is set to 'Enabled with UEFI lock' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/VirtualizationBasedTechnology/HypervisorEnforcedCodeIntegrity"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "75.2 (L1) Ensure 'Require UEFI Memory Attributes Table' is set to 'Require UEFI Memory Attributes Table' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/VirtualizationBasedTechnology/RequireUEFIMemoryAttributesTable"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "77.1 (L1) Ensure 'Allow widgets' is set to 'Not allowed' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/NewsAndInterests/AllowNewsAndInterests"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "78.1 (L1) Ensure 'Disallow Exploit Protection Override' is set to '(Enable)' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/WindowsDefenderSecurityCenter/DisallowExploitProtectionOverride"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingBoolean"
        "displayName" = "79.1 (L1) Ensure 'Facial Features Use Enhanced Anti Spoofing' is set to 'true' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/PassportForWork/Biometrics/FacialFeaturesUseEnhancedAntiSpoofing"
        "value" = $true
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "79.2 (L1) Ensure 'Minimum PIN Length' is set to '6 more character(s)' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/PassportForWork/$($tenant_id)/Policies/PINComplexity/MinimumPINLength"
        "value" = 6
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingBoolean"
        "displayName" = "79.3 (L1) Ensure 'Require Security Device' is set to 'true' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/PassportForWork/$($tenant_id)/Policies/RequireSecurityDevice"
        "value" = $true
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "80.1 (L2) Ensure 'Allow suggested apps in Windows Ink Workspace' is set to 'Block' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/WindowsInkWorkspace/AllowSuggestedAppsInWindowsInkWorkspace"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "80.2 (L1) Ensure 'Allow Windows Ink Workspace' is set to 'Enabled: but the user can't access it above the lock screen' OR 'Disabled' (Automated)"
        "description" = "Implemented. Disabled on lockscreen."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/WindowsInkWorkspace/AllowWindowsInkWorkspace"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "83.1 (L1) Ensure 'Allow Auto Update' is set to 'Enabled' (Automated)"
        "description" = "Opposed. We will utilize a third party update software."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Update/AllowAutoUpdate"
        "value" = 5
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "83.2 (L1) Ensure 'Defer Feature Updates Period in Days' is set to 'Enabled: 180 or more days' (Automated)"
        "description" = "Implemented. 180 days"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Update/DeferFeatureUpdatesPeriodInDays"
        "value" = 180
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "83.3 (L1) Ensure 'Defer Quality Updates Period (Days)' is set to 'Enabled: 0 days' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Update/DeferQualityUpdatesPeriodInDays"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "83.4 (L1) Ensure 'Manage preview builds' is set to 'Disable Preview builds' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Update/ManagePreviewBuilds"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "83.5 (L1) Ensure 'Scheduled Install Day' is set to 'Every day' (Automated)"
        "description" = "Implemented. But will be maned by third party"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Update/ScheduledInstallDay"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "83.6 (L1) Ensure 'Block 'Pause Updates' ability' is set to 'Block' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Update/SetDisablePauseUXAccess"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "85.1 (L1) LAPS: Ensure 'Backup Directory' is set to 'Backup the password to Azure AD only' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/LAPS/Policies/BackupDirectory"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingString"
        "displayName" = "85.1x (L1) LAPS: Name of the locally managed admin account."
        "description" = "Implemented. tadmin."
        "omaUri" = "./Device/Vendor/MSFT/LAPS/Policies/AdministratorAccountName"
        "value" = "tadmin"
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "85.2 (L1) LAPS: Ensure 'Password Age Days' is set to 'Configured: 30 or fewer' (Automated)"
        "description" = "Implemented. 7 days."
        "omaUri" = "./Device/Vendor/MSFT/LAPS/Policies/PasswordAgeDays"
        "value" = 7
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "85.3 (L1) LAPS: Ensure 'Password Complexity' is set to 'Large letters + small letters + numbers + special characters' (Automated)"
        "description" = "Implemented. Improved readability setting."
        "omaUri" = "./Device/Vendor/MSFT/LAPS/Policies/PasswordComplexity"
        "value" = 5
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "85.4 (L1) LAPS: Ensure 'Password Length' is set to 'Configured: 15 or more' (Automated)"
        "description" = "Implemented. 15."
        "omaUri" = "./Device/Vendor/MSFT/LAPS/Policies/PasswordLength"
        "value" = 15
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "85.5 (L1) LAPS: Ensure 'Post-authentication actions' is set to 'Reset the password and logoff the managed account' or higher (Automated)"
        "description" = "Implemented."
        "omaUri" = "./Device/Vendor/MSFT/LAPS/Policies/PostAuthenticationActions"
        "value" = 3
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "85.6 (L1) LAPS: Ensure 'Post Authentication Reset Delay' is set to 'Configured: 8 or fewer hours, but not 0' (Automated)"
        "description" = "Implemented. 8"
        "omaUri" = "./Device/Vendor/MSFT/LAPS/Policies/PostAuthenticationResetDelay"
        "value" = 8
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "86.1.1 (L2) Ensure 'Allow a Windows app to share application data between users' is set to 'Disabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ApplicationManagement/AllowSharedUserAppData"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "86.1.2 (L1) Ensure 'Allow Windows to automatically connect to suggested open hotspots, to networks shared by contacts, and to hotspots offering paid services' is set to 'Disabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Wifi/AllowAutoConnectToWiFiSenseHotspots"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "86.1.3 (L2) Ensure 'Configure Authenticated Proxy usage for the Connected User Experience and Telemetry service' is set to 'Enabled: Disable Authenticated Proxy usage' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/System/DisableEnterpriseAuthProxy"
        "value" = 1
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "86.1.4 (BL) Ensure 'Enumeration policy for external devices incompatible with Kernel DMA Protection' is set to 'Enabled: Block All' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/DmaGuard/DeviceEnumerationPolicy"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "86.1.5 (L1) Ensure 'Prevent non-admin users from installing packaged Windows apps' is set to 'Enabled' (Automated)"
        "description" = "Opposed. Users will be allowed to obtain packages from Windows Store."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/ApplicationManagement/BlockNonAdminUserInstall"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "86.1.6 (L2) Ensure 'Turn off location' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/System/AllowLocation"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "86.1.7 (L1) Ensure 'Turn off Microsoft consumer experiences' is set to 'Enabled' (Automated)"
        "description" = "Implemented"
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Experience/AllowWindowsConsumerFeatures"
        "value" = 0
    },
    @{
        "@odata.type" = "#microsoft.graph.omaSettingInteger"
        "displayName" = "86.1.8 (L2) Ensure 'Turn off notifications network usage' is set to 'Enabled' (Automated)"
        "description" = "Opposed. Enabling this may break MDM functionality including Wipe, Unenroll, Remote Find, Mandatory App install, and more."
        "omaUri" = "./Device/Vendor/MSFT/Policy/Config/Notifications/DisallowCloudNotification"
        "value" = 0
    }
  )
}

Write-Host "Connecting to Microsoft Graph..."
try {
  Connect-MgGraph -NoWelcome -Scopes "DeviceManagementManagedDevices.Read.All, DeviceManagementManagedDevices.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementConfiguration.Read.All" -ErrorAction Stop
  Write-Host "Connected."
}
catch {
    Write-Host -ForegroundColor Red -BackgroundColor Black "ERROR: " $_.ToString()
    Write-Host -ForegroundColor Red -BackgroundColor Black $_.ScriptStackTrace
}

$Context = Get-MgContext
if ($null -eq $Context) {
    Write-Host -ForegroundColor Red -BackgroundColor Black "There was an error connecting to Intune."
    return 1
}

Write-Host "Writing Config to Intune..."

try {
    $out = New-MgDeviceManagementDeviceConfiguration -BodyParameter $params -ErrorVariable newConfigError -ErrorAction SilentlyContinue
    Write-Host -ForegroundColor Green -BackgroundColor Black "Configuration has been written to Intune. You will need to assign your configuration to groups/devices before it will apply."
    $out
  }
catch {
    Write-Host -ForegroundColor Red -BackgroundColor Black "ERROR: " $_.ToString()
    Write-Host -ForegroundColor Red -BackgroundColor Black $_.ScriptStackTrace
    return 1
}

if ($newConfigError) {
    Write-Host -ForegroundColor Red -BackgroundColor Black $newConfigError
    Write-Host -ForegroundColor Red -BackgroundColor Black "There was an error writing the configuration."
    Write-Host -ForegroundColor Magenta -BackgroundColor Black "Tips: "
    Write-Host -ForegroundColor Magenta -BackgroundColor Black "- Make sure you are authenticating with a user who has Intune permission."
    Write-Host -ForegroundColor Magenta -BackgroundColor Black "- If you are using PIM, be sure to activate the Intune Administrator role."
    Disconnect-MGGraph | Out-Null
    return 1
}

Disconnect-MGGraph | Out-Null