# ShareGate Parallel Migration Script

This documentation explains how to use the modified `IncrementalMigration.ps1` script for running multiple ShareGate migrations in parallel.

## Overview

The script uses PowerShell's Microsoft.PowerShell.ThreadJob module to kick off multiple ShareGate migrations simultaneously instead of sequentially. This can significantly reduce the total time required for large migration projects by utilizing system resources more efficiently.

## Prerequisites

1. ShareGate PowerShell module installed
2. PowerShell 5.1 or higher
3. Sufficient system resources (CPU, memory, network bandwidth) to handle multiple concurrent migrations
4. The Microsoft.PowerShell.ThreadJob module (script will attempt to install automatically if missing)

## Module Installation Notes

The script will attempt to handle the Microsoft.PowerShell.ThreadJob module installation automatically, but you may encounter some issues:

1. If you receive an error about commands already being available, run the following command manually in an elevated PowerShell session:
   ```powershell
   Install-Module -Name Microsoft.PowerShell.ThreadJob -Force -Scope CurrentUser -AllowClobber
   ```

2. If you receive a warning that the module is currently in use, close all PowerShell sessions, reopen an elevated PowerShell session, and run the above command.

## How It Works

The script performs the following steps:

1. Loads necessary modules (ShareGate and Microsoft.PowerShell.ThreadJob)
2. Reads the migration source and destination data from a CSV file
3. Sets up common copy settings for all migrations
4. Establishes source and destination site connections
5. Creates a scriptblock that defines the migration job logic
6. Starts multiple migration jobs in parallel (with a configurable maximum)
7. Waits for all jobs to complete
8. Collects and aggregates results
9. Outputs a summary and saves detailed results to a CSV file

## Configuration Options

- **CSV File Path**: Set the path to your CSV file containing migration source and destination information.
- **Maximum Concurrent Jobs**: Adjust the `$maxConcurrentJobs` variable to control how many migrations run simultaneously.
- **Copy Settings**: Modify the copy settings parameters to adjust migration behavior (e.g., conflict resolution).

## CSV File Format

Your CSV file should include at minimum:
- `SourceSite`: URL of the source SharePoint site
- `DestSite`: URL of the destination SharePoint site

Example:
```csv
SourceSite,DestSite
https://source.sharepoint.com/sites/site1,https://destination.sharepoint.com/sites/site1
https://source.sharepoint.com/sites/site2,https://destination.sharepoint.com/sites/site2
```

## Performance Considerations

- **System Resources**: Running multiple migrations in parallel increases the load on your system. Adjust the `$maxConcurrentJobs` value based on your system's capabilities.
- **Network Bandwidth**: Ensure your network has sufficient bandwidth to handle concurrent migrations.
- **Authentication**: The script uses browser authentication, which may require user interaction for each job.
- **Progress Monitoring**: Each job's progress is reported independently in the PowerShell console.

## Error Handling

The script includes error handling for each migration job:
- Successful migrations are recorded with a "Success" status
- Failed migrations capture the error message for troubleshooting
- All results are exported to a time-stamped CSV file

## Troubleshooting

If you encounter issues:

1. **Job Failures**: Check the exported CSV file for specific error messages
2. **Resource Limitations**: Reduce the `$maxConcurrentJobs` value if your system is overloaded
3. **Authentication Issues**: Ensure credentials are valid and browser authentication is working
4. **Module Conflicts**: Make sure you have compatible versions of the ShareGate and Microsoft.PowerShell.ThreadJob modules
5. **Module Installation Issues**: If the script fails to install the ThreadJob module, follow the manual installation instructions in the "Module Installation Notes" section

## Example Usage

1. Update the CSV file path in the script
2. Adjust any configuration parameters as needed
3. Run the script in PowerShell
4. Monitor the console for progress updates
5. Review the summary and exported results CSV when complete 