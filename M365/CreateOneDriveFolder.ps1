$OneDriveURLs = Import-Csv "C:\Path\To\Your\Input\OneDriveData.csv"
$Credential = get-credential
Foreach ($URL in $OneDriveURLs)
{
    Write-Host $URL.ODRIVEURL
    Connect-PnPOnline -Url $Url.ONEDRIVEURL -UseWebLogin #-Credentials $Credential
    Add-PnPFolder -name "Home Directory" -Folder Documents
}