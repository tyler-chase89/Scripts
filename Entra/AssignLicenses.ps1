Connect-MgGraph -Scopes User.ReadWrite.All, Organization.Read.All
$Users = import-csv "C:\Path\To\Your\Input\Users.csv"

Foreach($User in $Users)
{
    Write-Host $User.UserprincipalName, $User.SkuID
    Update-MgUser -UserId $User.UserprincipalName -UsageLocation US
    $license = $User.SkuID
    $SkuID = (Get-MgSubscribedSku | Where {$_.SkuPartNumber -like $license}).SkuId
    Set-MgUserLicense -UserId $user.UserPrincipalName -AddLicenses @{SkuId = $SkuID} -RemoveLicenses @()
}