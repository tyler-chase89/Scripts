Import-Module Sharegate

# Check if Microsoft.PowerShell.ThreadJob module is installed, if not install it
try {
    # Try to import the module first - it might already be available but under its full name
    Import-Module Microsoft.PowerShell.ThreadJob -ErrorAction Stop
    Write-Host "Microsoft.PowerShell.ThreadJob module successfully imported."
} 
catch {
    if (-not (Get-Module -ListAvailable -Name Microsoft.PowerShell.ThreadJob)) {
        Write-Host "Installing Microsoft.PowerShell.ThreadJob module..."
        try {
            Install-Module -Name Microsoft.PowerShell.ThreadJob -Force -Scope CurrentUser -AllowClobber
        }
        catch {
            Write-Warning "Could not install the module automatically. Please run this command manually in an elevated PowerShell session:"
            Write-Warning "Install-Module -Name Microsoft.PowerShell.ThreadJob -Force -Scope CurrentUser -AllowClobber"
            Write-Warning "Then restart this script."
            exit
        }
    }
    # Try importing again after installation
    Import-Module Microsoft.PowerShell.ThreadJob
}

# Define CSV file path
$csvFile = "C:\ShareGate\STAPSGATE01.csv"

# Import CSV data into a table
$table = Import-Csv $csvFile -Delimiter ","

# Define common copy settings
$copysettings = New-CopySettings -OnContentItemExists IncrementalUpdate

# Connect to source and destination tenants
Write-Host "Connecting to source tenant..."
$srcTenant = Connect-Tenant -Domain "<SOURCE_TENANT_PLACEHOLDER>" -Browser

Write-Host "Connecting to destination tenant..."
$dstTenant = Connect-Tenant -Domain "<DESTINATION_TENANT_PLACEHOLDER>" -Browser

# Connect to source and destination sites for use in threading
Write-Host "Connecting to main source site..."
$srcsiteConnection = Connect-Site -Url "https://<SOURCE_TENANT_PLACEHOLDER>.sharepoint.com/sites/CIT" -Browser

Write-Host "Connecting to main destination site..."
$dstsiteConnection = Connect-Site -Url "https://<DESTINATION_TENANT_PLACEHOLDER>.sharepoint.com/sites/CIT" -Browser

# Maximum number of concurrent jobs
$maxConcurrentJobs = 10

# Define the script block for the migration job
$migrationScriptBlock = {
    param(
        $sourceUrl,
        $destUrl,
        $copySettings,
        $srcsiteConnection,
        $dstsiteConnection,
        $srcTenant,
        $dstTenant
    )

    # Import ShareGate module in the job context
    Import-Module Sharegate
    
    # Grant site collection administrator permissions and connect to sites
    try {
        # Add site collection administrator to source site
        Write-Host "Adding site collection administrator permissions to source site: $sourceUrl..."
        Add-SiteCollectionAdministrator -CentralAdmin $srcTenant.Site -SiteUrl $sourceUrl
        Write-Host "Successfully added site collection administrator permissions to source site"
        
        # Add site collection administrator to destination site
        Write-Host "Adding site collection administrator permissions to destination site: $destUrl..."
        Add-SiteCollectionAdministrator -CentralAdmin $dstTenant.Site -SiteUrl $destUrl
        Write-Host "Successfully added site collection administrator permissions to destination site"
        
        # Connect to sites using the credentials we've already authenticated with
        Write-Host "Connecting to source site: $sourceUrl..."
        $srcSite = Connect-Site -Url $sourceUrl -UseCredentialsFrom $srcsiteConnection
        
        Write-Host "Connecting to destination site: $destUrl..."
        $dstSite = Connect-Site -Url $destUrl -UseCredentialsFrom $dstsiteConnection
    }
    catch {
        Write-Warning "Failed during site connection or granting permissions: $($_.Exception.Message)"
        # If we can't connect or add permissions, return failure
        return @{
            SourceSite = $sourceUrl
            DestSite = $destUrl
            Status = "Failed"
            Error = "Connection or permission error: $($_.Exception.Message)"
        }
    }
    
    # Copy site from source to destination
    try {
        Copy-Site -Site $srcSite -DestinationSite $dstSite -Merge -Subsites -CopySettings $copySettings
        return @{
            SourceSite = $sourceUrl
            DestSite = $destUrl
            Status = "Success"
            Error = $null
        }
    }
    catch {
        return @{
            SourceSite = $sourceUrl
            DestSite = $destUrl
            Status = "Failed"
            Error = $_.Exception.Message
        }
    }
}

# Array to store jobs
$jobs = @()

# Start jobs for each migration
Write-Host "Starting migration jobs..."
foreach ($row in $table) {
    # Check if we've reached max concurrent jobs
    while ((Get-Job -State Running).Count -ge $maxConcurrentJobs) {
        Write-Host "Maximum number of concurrent jobs reached. Waiting for a job to complete..."
        Start-Sleep -Seconds 10
    }
    
    # Start a new job for this migration
    $jobName = "Migration_$($row.SourceSite)_to_$($row.DestSite)"
    $job = Start-ThreadJob -Name $jobName -ScriptBlock $migrationScriptBlock -ArgumentList @(
        $row.SourceSite, 
        $row.DestSite, 
        $copysettings,
        $srcsiteConnection,
        $dstsiteConnection,
        $srcTenant,
        $dstTenant
    )
    
    $jobs += $job
    Write-Host "Started job for migrating $($row.SourceSite) to $($row.DestSite). Job ID: $($job.Id)"
}

# Wait for all jobs to complete
Write-Host "All migration jobs have been started. Waiting for jobs to complete..."
$jobs | Wait-Job

# Get results from all jobs
$results = @()
foreach ($job in $jobs) {
    $result = Receive-Job -Job $job
    $results += $result
    Remove-Job -Job $job
}

# Output summary
Write-Host "`nMigration Summary:"
Write-Host "================================"
Write-Host "Total migrations: $($results.Count)"
Write-Host "Successful: $($results | Where-Object { $_.Status -eq 'Success' } | Measure-Object).Count"
Write-Host "Failed: $($results | Where-Object { $_.Status -eq 'Failed' } | Measure-Object).Count"

# Export results to CSV (optional)
$results | Export-Csv -Path "C:\ShareGate\MigrationResults_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv" -NoTypeInformation

Write-Host "`nMigration complete. Results exported to CSV."