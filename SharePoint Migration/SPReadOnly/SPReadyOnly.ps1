# SharePoint Site Read-Only Script
# This script imports a CSV file containing SharePoint site URLs and sets each site to read-only mode.
# Useful for post-migration scenarios when you need to lock down source sites.

# Import required modules
Import-Module PnP.PowerShell

# Function to set a SharePoint site to read-only
function Set-SiteToReadOnly {
    param (
        [Parameter(Mandatory=$true)]
        [string]$SiteUrl,
        
        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential]$Credentials
    )
    
    try {
        Write-Host "Processing site: $SiteUrl" -ForegroundColor Yellow
        
        # Connect to SharePoint site
        if ($Credentials) {
            Connect-PnPOnline -Url $SiteUrl -Credentials $Credentials
        } else {
            Connect-PnPOnline -Url $SiteUrl -Interactive
        }
        
        # Set site to read-only by locking the site
        Set-PnPSite -LockState ReadOnly
        
        Write-Host "Site set to read-only successfully: $SiteUrl" -ForegroundColor Green
        
        # Disconnect from the site
        Disconnect-PnPOnline
    }
    catch {
        Write-Host "Error setting site to read-only: $SiteUrl" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

# Main script execution
try {
    # Prompt for CSV file path
    $csvPath = Read-Host "Enter the path to the CSV file containing SharePoint site URLs"
    
    # Check if file exists
    if (-not (Test-Path $csvPath)) {
        Write-Host "CSV file not found at path: $csvPath" -ForegroundColor Red
        exit
    }
    
    # Ask if user wants to use saved credentials
    $useCredentials = Read-Host "Do you want to use saved credentials? (Y/N)"
    $credentials = $null
    
    if ($useCredentials -eq "Y" -or $useCredentials -eq "y") {
        $username = Read-Host "Enter your username"
        $securePassword = Read-Host "Enter your password" -AsSecureString
        $credentials = New-Object System.Management.Automation.PSCredential ($username, $securePassword)
    }
    
    # Import CSV file
    $sites = Import-Csv -Path $csvPath
    
    # Check if CSV has the required column
    $firstRow = $sites | Select-Object -First 1
    if (-not ($firstRow.PSObject.Properties.Name -contains "SiteUrl")) {
        Write-Host "CSV file must contain a column named 'SiteUrl'" -ForegroundColor Red
        exit
    }
    
    # Process each site
    $totalSites = $sites.Count
    $currentSite = 0
    
    foreach ($site in $sites) {
        $currentSite++
        Write-Host "Processing site $currentSite of $totalSites" -ForegroundColor Cyan
        
        if ($credentials) {
            Set-SiteToReadOnly -SiteUrl $site.SiteUrl -Credentials $credentials
        } else {
            Set-SiteToReadOnly -SiteUrl $site.SiteUrl
        }
    }
    
    Write-Host "All sites have been processed." -ForegroundColor Green
}
catch {
    Write-Host "An error occurred during script execution:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
