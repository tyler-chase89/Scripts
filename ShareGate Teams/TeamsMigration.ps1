# Import the required modules
Import-Module sharegate
$Teams = import-csv C:\ShareGate\Teamssharegate.csv

# Connect to the source and destination tenants
$SourceTenant = Connect-Tenant -Domain -DisableSSO -Browser
$destinationTenant = Connect-Tenant -Domain  -Browser

$TeamNames = $teams.SrcDisplayName -join ',' -split ','

# Bulk migrate all teams at once
$TeamObjects = Get-Team -Name $TeamNames -Tenant $SourceTenant -AllowMultiple
Copy-Team -Team $TeamObjects -DestinationTenant $destinationTenant