$Users = Get-mailbox -filter "Name -notlike '*clinic.*'" -ResultSize Unlimited | Where {$_.LitigationHoldEnabled -EQ $True}

Foreach ($user in $users)
{
    Write-host $User.UserprincipalName
    Set-mailbox -identity $user.Userprincipalname -LitigationHoldEnabled $false
}