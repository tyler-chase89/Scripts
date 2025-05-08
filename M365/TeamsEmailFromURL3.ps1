# Install the Microsoft.Graph module if not already installed
# Install-Module Microsoft.Graph -Scope CurrentUser
# Import the Microsoft.Graph module
$MaximumFunctionCount = 10000
Import-Module Microsoft.Graph

# Function to get the Teams email address based on SharePoint URL
function Get-TeamsEmailFromSharePointURL {
    param (
        [string]$CsvFilePath,
        [string]$OutputCsvPath
    )
    
    # Connect to Microsoft Graph (uncomment if needed)
    Connect-MgGraph -Scopes "Group.Read.All", "Sites.Read.All"
    
    # Import the SharePoint URLs from the CSV file
    $sharePointURLs = Import-Csv -Path $CsvFilePath
    
    # Create an array to store the results
    $results = @()
    
    # Clear or create the output file
    "SharePointURL,Status,DIsplayName,TeamsEmail" | Out-File -FilePath $OutputCsvPath -Force
    
    foreach ($url in $sharePointURLs) {
        $SharePointURL = $url.SharePointURL
        
        try {
            # Get the site collection
            $site = Get-SPOsite -Identity $SharePointURL -ErrorAction Stop
            
            # Get the group ID from the site
            $groupId = $site.GroupId
            
            if ($null -eq $groupId) {
                # Site found but no group associated
                $resultObj = [PSCustomObject]@{
                    SharePointURL = $SharePointURL
                    Status = "Site found but no group ID associated"
                    TeamsEmail = ""
                    DisplayName = $Team.DisplayName
                }
            } 
            else {
                # Get the Teams team associated with the group
                $team = Get-MgGroup -GroupID $groupId -ErrorAction Stop
                
                if ($null -eq $team) {
                    # Group found but no team
                    $resultObj = [PSCustomObject]@{
                        SharePointURL = $SharePointURL
                        Status = "Group found but no team associated"
                        TeamsEmail = ""
                        DisplayName = $Team.DisplayName
                    }
                } 
                else {
                    # Success - got the team email
                    $resultObj = [PSCustomObject]@{
                        SharePointURL = $SharePointURL
                        Status = "Success"
                        TeamsEmail = $team.Mail
                        DisplayName = $Team.DisplayName
                    }
                }
            }
        }
        catch {
            # Error getting site, group, or team
            $resultObj = [PSCustomObject]@{
                SharePointURL = $SharePointURL
                Status = "Error: $($_.Exception.Message)"
                TeamsEmail = ""
                DisplayName = $Team.DisplayName
            }
        }
        
        # Add to results array
        $results += $resultObj
        
        # Write to console to show progress
        Write-Host "$($SharePointURL),$($resultObj.Status),$($resultObj.DisplayName),$($resultObj.TeamsEmail)"
        
        # Export each record as we go (with -Append) to ensure we don't lose data
        $resultObj | Export-Csv -Path $OutputCsvPath -Append -NoTypeInformation
    }
    
    # Return the full results
    return $results
}

# Specify file paths
$csvFilePath = "C:\Path\To\Your\TeamsSharePointURLs.csv"
$outputCsvPath = "C:\Path\To\Your\Output\TeamsWithNames.csv"

# Run the function
$allResults = Get-TeamsEmailFromSharePointURL -CsvFilePath $csvFilePath -OutputCsvPath $outputCsvPath

# Display summary
Write-Host "`nProcessing complete. Found $(($allResults | Where-Object {$_.Status -eq 'Success'}).Count) Teams emails out of $($allResults.Count) URLs."
Write-Host "Results exported to: $outputCsvPath"