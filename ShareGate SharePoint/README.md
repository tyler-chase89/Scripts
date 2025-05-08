# ShareGate Parallel Migration Tool

This repository contains a PowerShell script for running multiple ShareGate migrations in parallel using PowerShell's ThreadJob module.

## Files

- **IncrementalMigration.ps1**: The main script that runs ShareGate migrations in parallel
- **STAPSGATE01.csv**: Your migration source/destination mapping file
- **STAPSGATE01_example.csv**: Example CSV file showing the required format
- **docs/ShareGateParallelMigration.md**: Detailed documentation on using the script

## Key Features

- Runs multiple ShareGate migrations concurrently instead of sequentially
- Configurable maximum number of concurrent jobs
- Error handling and detailed results reporting
- Progress monitoring and summary reporting
- Automatic installation of required PowerShell modules

## Quick Start

1. Update the CSV file with your source and destination SharePoint sites
2. Adjust the `$maxConcurrentJobs` value in the script if needed (default is 5)
3. Run the script in PowerShell
4. Review the results in the console and exported CSV file

## Benefits of Parallel Migration

- Significantly reduced total migration time
- Better resource utilization
- Comprehensive error handling and reporting
- Easily scalable by adjusting the number of concurrent jobs

For detailed usage instructions, see the [documentation](docs/ShareGateParallelMigration.md).

## Requirements

- ShareGate PowerShell module installed
- PowerShell 5.1 or higher
- Sufficient system resources to handle multiple concurrent migrations 