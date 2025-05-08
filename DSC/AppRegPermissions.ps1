$Perms = Get-M365DSCCompiledPermissionList -ResourceNameList (Get-M365DSCAllResources) -PermissionType 'Application' -AccessType 'Update'
Connect-MgGraph -Scopes "Application.ReadWrite.All", "DelegatedPermissionGrant.ReadWrite.All"
$graphServicePrincipal = Get-MgServicePrincipal -Filter "displayName eq 'Microsoft Graph'"


Foreach ($Perm in $Perms)
{
    $delegatedPermission = $graphServicePrincipal.Oauth2PermissionScopes | Where {$_.Value -eq $Perm.PermissionName}
    $delegatedPermission | Format-List Value,ID 
    New-MgOauth2PermissionGrant -ResourceId 'b35ff812-553f-4796-ac6d-26a392a805d7' -ClientId '<CLIENT_ID_PLACEHOLDER>' -ConsentType AllPrincipals -Scope $delegatedPermission.Id

}

