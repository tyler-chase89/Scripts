# Specify the output CSV file path
$csvFilePath = "C:\ShareGate\NetworkDriveListings.csv"

# Initialize an empty array to store the results
$driveListings = @()

# Get all mapped network drives (excluding C:\)
$networkDrives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -notlike "C:\" -and $_.DisplayRoot -like "\\*" }

# Iterate through each network drive
foreach ($drive in $networkDrives) {
    # Get only the top-level directories from the root of each network drive
    $directories = Get-ChildItem -Path $drive.Root -Directory -ErrorAction SilentlyContinue

    foreach ($directory in $directories) {
        # Add the drive path and directory name to the list
        $driveListings += [PSCustomObject]@{
            NetworkDrivePath = $drive.DisplayRoot
            FullFolderName   = $directory.FullName
            Level            = 1
        }
        
        # Get subdirectories (one level of recursion)
        $subdirectories = Get-ChildItem -Path $directory.FullName -Directory -ErrorAction SilentlyContinue
        
        foreach ($subdirectory in $subdirectories) {
            # Add the subdirectory to the list
            $driveListings += [PSCustomObject]@{
                NetworkDrivePath = $drive.DisplayRoot
                FullFolderName   = $subdirectory.FullName
                Level            = 2
            }
        }
    }
}

# Export the data to a CSV file
$driveListings | Export-Csv -Path $csvFilePath -NoTypeInformation -Encoding UTF8

Write-Host "Export completed! The directory listings (with one level of recursion) have been saved to $csvFilePath"
