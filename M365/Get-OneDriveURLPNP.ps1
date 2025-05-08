$Users = Import-csv "C:\Path\To\Your\Input\Data.csv"
Connect-PnPOnline -UseWebLogin "https://TENANT-admin.sharepoint.com"
foreach ($User in $Users)
{
    Get-PnPUserProfileProperty -Account $User.EmailAddress | Select Email,PersonalURL | Export-Csv "C:\Path\To\Your\Output\OneDrives.CSV" -NoTypeInformation -Append
}