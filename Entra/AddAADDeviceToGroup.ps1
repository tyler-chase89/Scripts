Import-Module Microsoft.Graph.Groups
$Computers = Import-Csv -Path "C:\Path\To\Your\Input\Computers.csv"

Foreach ($Computer in $Computers)
{
   $DeviceID = Get-azureaddevice -All 1 | Where {$_.DisplayName -like $Computer.Name}
   Write-Host $DeviceID.DisplayName
   Add-AzureADGroupMember -ObjectId 8503266d-7eb7-47d9-9871-c1843c85894f -RefObjectId $DeviceID.ObjectID
}