# ShareGate Incremental Migration Script

This script performs incremental migrations of SharePoint sites using the ShareGate migration tool. It processes a CSV file containing source and destination site URLs and uses parallel processing to handle multiple migrations simultaneously.

## Features

- **Parallel Processing**: Runs multiple migrations concurrently using PowerShell ThreadJobs
- **Incremental Updates**: Uses ShareGate's incremental update feature to only copy new or modified content
- **Site Collection Admin Permissions**: Automatically adds tenant-level site collection administrator permissions for all migrated sites
- **Detailed Logging**: Provides detailed logs and exports results to CSV

## Requirements

- ShareGate PowerShell module
- Microsoft.PowerShell.ThreadJob module (script will attempt to install if missing)
- CSV file with source and destination site URLs

## CSV File Format

The script expects a CSV file with at least the following columns:
- `SourceSite`: URL of the source SharePoint site
- `DestSite`: URL of the destination SharePoint site

Example:
```csv
SourceSite,DestSite
https://carlislecompanies.sharepoint.com/sites/Site1,https://amphenolcit.sharepoint.com/sites/Site1
https://carlislecompanies.sharepoint.com/sites/Site2,https://amphenolcit.sharepoint.com/sites/Site2
```

## Site Collection Administrator Permissions

The script adds site collection administrator permissions to the current user using a tenant-level approach. This is critical because:

1. Site collection admin permissions on the source site ensure full read access to all content
2. Site collection admin permissions on the destination site ensure full write access for content migration
3. Without sufficient permissions, the migration may fail or result in incomplete content transfer

The process follows this sequence:
1. Connect to source and destination tenants using `Connect-Tenant`
2. For each migration job:
   - Add site collection administrator permissions to the source site using the tenant connection
   - Add site collection administrator permissions to the destination site using the tenant connection
   - Connect to the source and destination sites
   - Perform the migration

The script uses ShareGate's tenant-level approach for adding site collection admin permissions:
```powershell
# Connect to tenants
$srcTenant = Connect-Tenant -Domain "sourcetenant" -Browser
$dstTenant = Connect-Tenant -Domain "desttenant" -Browser

# For each site in the migration
Add-SiteCollectionAdministrator -CentralAdmin $srcTenant.Site -SiteUrl $sourceUrl
Add-SiteCollectionAdministrator -CentralAdmin $dstTenant.Site -SiteUrl $destUrl
```

This tenant-level approach has several advantages:
1. Can grant site collection admin permissions even when you can't connect to the site directly
2. Works reliably across different SharePoint environments
3. Uses the tenant admin center to grant permissions, which is more powerful than site-level permission changes

If either permission assignment fails, the migration will not proceed for that site pair, and an error will be reported in the results.

After the migration is complete, you may want to consider removing these permissions using:
```powershell
Remove-SiteCollectionAdministrator -CentralAdmin $tenant.Site -SiteUrl $siteUrl
```

## Usage

1. Modify the CSV file path at the beginning of the script
2. Run the script in PowerShell
3. Authenticate to source and destination tenants when prompted
4. Monitor the progress in the console output
5. Review the results in the exported CSV file

## Output

The script produces:
- Console output showing progress of each migration
- A CSV file with migration results, including status and any error messages 