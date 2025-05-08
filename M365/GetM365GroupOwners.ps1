#Connect to Exchange Online
Connect-ExchangeOnline
 
#Get All Office 365 Groups
$GroupData = @()
$Groups = Get-UnifiedGroup -ResultSize Unlimited -SortBy Name
 
#Loop through each Group
$Groups | Foreach-Object {
    #Get Group Owners
    $GroupOwners = Get-UnifiedGroupLinks -LinkType Owners -Identity $_.Id | Select DisplayName, PrimarySmtpAddress
    $GroupData += New-Object -TypeName PSObject -Property @{
            GroupName = $_.Alias
            GroupEmail = $_.PrimarySmtpAddress
            OwnerName = $GroupOwners.DisplayName -join "; "
            OwnerIDs = $GroupOwners.PrimarySmtpAddress -join "; "
    }
}
#Get Groups Data
$GroupData
$GroupData | Export-Csv "C:\Path\To\Output\GroupOwners.csv" -NoTypeInformation


#Read more: https://www.sharepointdiary.com/2019/05/get-office-365-group-owners-using-powershell.html#ixzz7OGpQx9Ag