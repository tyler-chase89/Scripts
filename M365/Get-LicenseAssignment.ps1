$Users = Import-Csv "C:\Path\To\Your\Input\Users.csv"

Foreach ($User in $Users)
{

#the license SKU we are interested in. use Get-MsolAccountSku to see a list of all identifiers in your organization
$skuId = Get-msolaccountSku #"uchastings365:EMSPREMIUM"

Foreach($Sku in $skuId)
{
#find all users that have the SKU license assigned
Get-MsolUser -UserPrincipalName $User.old | where {$_.isLicensed -eq $true -and $_.Licenses.AccountSKUID -eq $Sku.AccountSkuId} | select `
    ObjectId,DisplayName, `
    @{Name="SkuId";Expression={$Sku.AccountSkuId}}, `
    @{Name="AssignedDirectly";Expression={(UserHasLicenseAssignedDirectly $_ $sku.AccountSkuId)}}, `
    @{Name="AssignedFromGroup";Expression={(UserHasLicenseAssignedFromGroup $_ $sku.AccountSkuId)}} | Export-Csv "C:\Path\To\Your\Output\LicenseAssignments.csv" -NoTypeInformation -Append
}
}