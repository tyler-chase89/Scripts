$Users = Import-csv 'C:\Path\To\Your\Csv\Data.csv'

Foreach ($User in $Users)
{
    Write-Host $User.old
    Set-Mailbox -Identity $User.old -ForwardingSmtpAddress $User.new
}