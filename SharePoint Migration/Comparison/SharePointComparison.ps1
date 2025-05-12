# SharePoint Comparison Tool
# This script compares two SharePoint sites for analysis purposes

# Parameters
param(
    [Parameter(Mandatory=$true)]
    [string]$FirstSiteUrl,
    
    [Parameter(Mandatory=$true)]
    [string]$SecondSiteUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$ReportPath = ".\SharePointComparisonReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv",
    
    [Parameter(Mandatory=$false)]
    [System.Management.Automation.PSCredential]$Credentials,
    
    [Parameter(Mandatory=$false)]
    [switch]$ProcessSubsites = $true,
    
    [Parameter(Mandatory=$false)]
    [int]$MaxDepth = 3
)

# Function to connect to SharePoint Online
function Connect-SharePointSite {
    param (
        [string]$SiteUrl,
        [System.Management.Automation.PSCredential]$Credentials
    )
    
    try {
        Write-Host "Connecting to SharePoint site: $SiteUrl" -ForegroundColor Cyan
        
        if ($Credentials) {
            Connect-PnPOnline -Url $SiteUrl -Credentials $Credentials
        } else {
            Connect-PnPOnline -Url $SiteUrl -UseWebLogin
        }
        
        return $true
    } catch {
        Write-Host "Error connecting to $SiteUrl : $_" -ForegroundColor Red
        return $false
    }
}

# Function to get all SharePoint objects
function Get-SharePointObjects {
    param (
        [string]$SiteUrl,
        [int]$CurrentDepth = 0,
        [int]$MaxDepth = 3,
        [bool]$ProcessSubsites = $true,
        [string]$ParentPath = ""
    )
    
    $results = @{
        "Lists" = @()
        "Libraries" = @()
        "ContentTypes" = @()
        "Fields" = @()
        "Workflows" = @()
        "NavigationNodes" = @()
        "WebParts" = @()
        "Pages" = @()
        "Features" = @()
        "Groups" = @()
        "Users" = @()
        "Subsites" = @()
        "SubsiteData" = @{}
    }
    
    # Get current site title for path
    $currentSite = Get-PnPWeb
    $currentSiteTitle = $currentSite.Title
    
    # Build site path for reporting
    if ([string]::IsNullOrEmpty($ParentPath)) {
        $sitePath = $currentSiteTitle
    } else {
        $sitePath = "$ParentPath > $currentSiteTitle"
    }
    
    Write-Host "Retrieving objects from $SiteUrl (Path: $sitePath)..." -ForegroundColor Yellow
    
    # Get Lists and Libraries
    $lists = Get-PnPList
    
    foreach ($list in $lists) {
        # Use a more robust approach to get actual item count
        $itemCount = 0
        try {
            # Try to get item count directly from the list property
            $itemCount = $list.ItemCount
        } catch {
            Write-Host "Unable to get item count for list $($list.Title). Using 0." -ForegroundColor Yellow
        }
        
        $listInfo = [PSCustomObject]@{
            Title = $list.Title
            InternalName = $list.InternalName
            Id = $list.Id
            ItemCount = $list.ItemCount
            ActualItemCount = $itemCount
            Created = $list.Created
            LastModified = $list.LastItemModifiedDate
            BaseTemplate = $list.BaseTemplate
            DefaultViewUrl = $list.DefaultViewUrl
            IsHidden = $list.Hidden
            SitePath = $sitePath
        }
        
        if ($list.BaseTemplate -eq 101) {
            $results.Libraries += $listInfo
        } else {
            $results.Lists += $listInfo
        }
    }
    
    # Get Content Types
    $results.ContentTypes = Get-PnPContentType | Select-Object Name, Id, Group, Description | ForEach-Object {
        $_ | Add-Member -MemberType NoteProperty -Name "SitePath" -Value $sitePath -PassThru
    }
    
    # Get Fields (Site Columns)
    $results.Fields = Get-PnPField | Where-Object { -not $_.Hidden } | Select-Object Title, InternalName, Id, TypeAsString, Group | ForEach-Object {
        $_ | Add-Member -MemberType NoteProperty -Name "SitePath" -Value $sitePath -PassThru
    }
    
    # Get Workflows (if available)
    try {
        $results.Workflows = Get-PnPWorkflowDefinition | Select-Object Name, Id, Description | ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name "SitePath" -Value $sitePath -PassThru
        }
    } catch {
        Write-Host "Workflows not available or accessible in $sitePath" -ForegroundColor Yellow
    }
    
    # Get Navigation
    $results.NavigationNodes = Get-PnPNavigationNode -Location QuickLaunch | Select-Object Title, Url, Id | ForEach-Object {
        $_ | Add-Member -MemberType NoteProperty -Name "SitePath" -Value $sitePath -PassThru
    }
    
    # Get Pages
    try {
        $results.Pages = Get-PnPListItem -List "Site Pages" | Select-Object @{Name="Title"; Expression={$_["Title"]}}, @{Name="FileName"; Expression={$_["FileLeafRef"]}}, Id | ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name "SitePath" -Value $sitePath -PassThru
        }
    } catch {
        Write-Host "Site Pages library not accessible in $sitePath" -ForegroundColor Yellow
    }
    
    # Get Features
    $results.Features = Get-PnPFeature -Scope Site | Select-Object DisplayName, Id, Scope | ForEach-Object {
        $_ | Add-Member -MemberType NoteProperty -Name "SitePath" -Value $sitePath -PassThru
    }
    
    # Get Groups and Users
    $results.Groups = Get-PnPGroup | Select-Object Title, Id, LoginName | ForEach-Object {
        $_ | Add-Member -MemberType NoteProperty -Name "SitePath" -Value $sitePath -PassThru
    }
    
    $results.Users = Get-PnPUser | Select-Object Title, Id, LoginName, Email | ForEach-Object {
        $_ | Add-Member -MemberType NoteProperty -Name "SitePath" -Value $sitePath -PassThru
    }
    
    # Get Subsites
    $subsites = Get-PnPSubWeb -Recurse:$false | Select-Object Title, Url, Id, WebTemplate
    
    # Add site path to subsite objects
    $results.Subsites = $subsites | ForEach-Object {
        $_ | Add-Member -MemberType NoteProperty -Name "SitePath" -Value $sitePath -PassThru
    }
    
    # Process subsites recursively if needed
    if ($ProcessSubsites -and $CurrentDepth -lt $MaxDepth -and $subsites.Count -gt 0) {
        Write-Host "Found $($subsites.Count) subsites in $sitePath" -ForegroundColor Yellow
        
        foreach ($subsite in $subsites) {
            # Save current connection details
            $parentSiteUrl = $SiteUrl
            
            # Connect to subsite
            Write-Host "Processing subsite: $($subsite.Title) ($($subsite.Url))" -ForegroundColor Cyan
            $subsiteConnected = Connect-SharePointSite -SiteUrl $subsite.Url -Credentials $Credentials
            
            if ($subsiteConnected) {
                # Get subsite data
                $subsiteData = Get-SharePointObjects -SiteUrl $subsite.Url -CurrentDepth ($CurrentDepth + 1) -MaxDepth $MaxDepth -ProcessSubsites $ProcessSubsites -ParentPath $sitePath
                
                # Store subsite data
                $results.SubsiteData[$subsite.Url] = $subsiteData
                
                # Disconnect from subsite
                Disconnect-PnPOnline
                
                # Reconnect to original site using URL instead of context
                Write-Host "Reconnecting to parent site: $parentSiteUrl" -ForegroundColor Cyan
                Connect-SharePointSite -SiteUrl $parentSiteUrl -Credentials $Credentials
                Write-Host "Returned to $sitePath" -ForegroundColor Cyan
            } else {
                Write-Host "Could not connect to subsite $($subsite.Url). Skipping." -ForegroundColor Red
            }
        }
    }
    
    return $results
}

# Function to compare objects
function Compare-SharePointObjects {
    param (
        $FirstSiteObjects,
        $SecondSiteObjects,
        [string]$ParentPath = ""
    )
    
    $comparisonResults = @()
    
    # Compare Lists
    Write-Host "Comparing Lists..." -ForegroundColor Yellow
    foreach ($firstList in $FirstSiteObjects.Lists) {
        $secondList = $SecondSiteObjects.Lists | Where-Object { $_.Title -eq $firstList.Title }
        
        $comparisonResults += [PSCustomObject]@{
            ObjectType = "List"
            Name = $firstList.Title
            ExistsInFirstSite = $true
            ExistsInSecondSite = ($secondList -ne $null)
            FirstSiteItemCount = $firstList.ItemCount
            SecondSiteItemCount = if ($secondList) { $secondList.ItemCount } else { 0 }
            Status = if ($secondList) { 
                if ($firstList.ItemCount -eq $secondList.ItemCount) { "Matched" } else { "Item Count Mismatch" }
            } else { "Missing in Second Site" }
            SitePath = $firstList.SitePath
        }
    }
    
    # Check for lists in second site that don't exist in first site
    foreach ($secondList in $SecondSiteObjects.Lists) {
        $firstList = $FirstSiteObjects.Lists | Where-Object { $_.Title -eq $secondList.Title }
        if (-not $firstList) {
            $comparisonResults += [PSCustomObject]@{
                ObjectType = "List"
                Name = $secondList.Title
                ExistsInFirstSite = $false
                ExistsInSecondSite = $true
                FirstSiteItemCount = 0
                SecondSiteItemCount = $secondList.ItemCount
                Status = "Extra in Second Site"
                SitePath = $secondList.SitePath
            }
        }
    }
    
    # Compare Libraries
    Write-Host "Comparing Document Libraries..." -ForegroundColor Yellow
    foreach ($firstLib in $FirstSiteObjects.Libraries) {
        $secondLib = $SecondSiteObjects.Libraries | Where-Object { $_.Title -eq $firstLib.Title }
        
        $comparisonResults += [PSCustomObject]@{
            ObjectType = "Library"
            Name = $firstLib.Title
            ExistsInFirstSite = $true
            ExistsInSecondSite = ($secondLib -ne $null)
            FirstSiteItemCount = $firstLib.ItemCount
            SecondSiteItemCount = if ($secondLib) { $secondLib.ItemCount } else { 0 }
            Status = if ($secondLib) { 
                if ($firstLib.ItemCount -eq $secondLib.ItemCount) { "Matched" } else { "Item Count Mismatch" }
            } else { "Missing in Second Site" }
            SitePath = $firstLib.SitePath
        }
    }
    
    # Check for libraries in second site that don't exist in first site
    foreach ($secondLib in $SecondSiteObjects.Libraries) {
        $firstLib = $FirstSiteObjects.Libraries | Where-Object { $_.Title -eq $secondLib.Title }
        if (-not $firstLib) {
            $comparisonResults += [PSCustomObject]@{
                ObjectType = "Library"
                Name = $secondLib.Title
                ExistsInFirstSite = $false
                ExistsInSecondSite = $true
                FirstSiteItemCount = 0
                SecondSiteItemCount = $secondLib.ItemCount
                Status = "Extra in Second Site"
                SitePath = $secondLib.SitePath
            }
        }
    }
    
    # Compare Content Types
    Write-Host "Comparing Content Types..." -ForegroundColor Yellow
    foreach ($firstCT in $FirstSiteObjects.ContentTypes) {
        $secondCT = $SecondSiteObjects.ContentTypes | Where-Object { $_.Name -eq $firstCT.Name }
        
        $comparisonResults += [PSCustomObject]@{
            ObjectType = "ContentType"
            Name = $firstCT.Name
            ExistsInFirstSite = $true
            ExistsInSecondSite = ($secondCT -ne $null)
            FirstSiteItemCount = "N/A"
            SecondSiteItemCount = "N/A"
            Status = if ($secondCT) { "Matched" } else { "Missing in Second Site" }
            SitePath = $firstCT.SitePath
        }
    }
    
    # Compare Fields
    Write-Host "Comparing Site Columns..." -ForegroundColor Yellow
    foreach ($firstField in $FirstSiteObjects.Fields) {
        $secondField = $SecondSiteObjects.Fields | Where-Object { $_.InternalName -eq $firstField.InternalName }
        
        $comparisonResults += [PSCustomObject]@{
            ObjectType = "Field"
            Name = $firstField.Title
            ExistsInFirstSite = $true
            ExistsInSecondSite = ($secondField -ne $null)
            FirstSiteItemCount = "N/A"
            SecondSiteItemCount = "N/A"
            Status = if ($secondField) { 
                if ($secondField.TypeAsString -eq $firstField.TypeAsString) { "Matched" } else { "Type Mismatch" }
            } else { "Missing in Second Site" }
            SitePath = $firstField.SitePath
        }
    }
    
    # Compare Workflows
    Write-Host "Comparing Workflows..." -ForegroundColor Yellow
    foreach ($firstWF in $FirstSiteObjects.Workflows) {
        $secondWF = $SecondSiteObjects.Workflows | Where-Object { $_.Name -eq $firstWF.Name }
        
        $comparisonResults += [PSCustomObject]@{
            ObjectType = "Workflow"
            Name = $firstWF.Name
            ExistsInFirstSite = $true
            ExistsInSecondSite = ($secondWF -ne $null)
            FirstSiteItemCount = "N/A"
            SecondSiteItemCount = "N/A"
            Status = if ($secondWF) { "Matched" } else { "Missing in Second Site" }
            SitePath = $firstWF.SitePath
        }
    }
    
    # Compare Navigation
    Write-Host "Comparing Navigation..." -ForegroundColor Yellow
    foreach ($firstNav in $FirstSiteObjects.NavigationNodes) {
        $secondNav = $SecondSiteObjects.NavigationNodes | Where-Object { $_.Title -eq $firstNav.Title }
        
        $comparisonResults += [PSCustomObject]@{
            ObjectType = "Navigation"
            Name = $firstNav.Title
            ExistsInFirstSite = $true
            ExistsInSecondSite = ($secondNav -ne $null)
            FirstSiteItemCount = "N/A"
            SecondSiteItemCount = "N/A"
            Status = if ($secondNav) { 
                if ($secondNav.Url -eq $firstNav.Url) { "Matched" } else { "URL Mismatch" }
            } else { "Missing in Second Site" }
            SitePath = $firstNav.SitePath
        }
    }
    
    # Compare Pages
    Write-Host "Comparing Pages..." -ForegroundColor Yellow
    foreach ($firstPage in $FirstSiteObjects.Pages) {
        $secondPage = $SecondSiteObjects.Pages | Where-Object { $_.FileName -eq $firstPage.FileName }
        
        $comparisonResults += [PSCustomObject]@{
            ObjectType = "Page"
            Name = $firstPage.FileName
            ExistsInFirstSite = $true
            ExistsInSecondSite = ($secondPage -ne $null)
            FirstSiteItemCount = "N/A"
            SecondSiteItemCount = "N/A"
            Status = if ($secondPage) { "Matched" } else { "Missing in Second Site" }
            SitePath = $firstPage.SitePath
        }
    }
    
    # Compare Features
    Write-Host "Comparing Features..." -ForegroundColor Yellow
    foreach ($firstFeature in $FirstSiteObjects.Features) {
        $secondFeature = $SecondSiteObjects.Features | Where-Object { $_.Id -eq $firstFeature.Id }
        
        $comparisonResults += [PSCustomObject]@{
            ObjectType = "Feature"
            Name = $firstFeature.DisplayName
            ExistsInFirstSite = $true
            ExistsInSecondSite = ($secondFeature -ne $null)
            FirstSiteItemCount = "N/A"
            SecondSiteItemCount = "N/A"
            Status = if ($secondFeature) { "Matched" } else { "Missing in Second Site" }
            SitePath = $firstFeature.SitePath
        }
    }
    
    # Compare Groups
    Write-Host "Comparing SharePoint Groups..." -ForegroundColor Yellow
    foreach ($firstGroup in $FirstSiteObjects.Groups) {
        $secondGroup = $SecondSiteObjects.Groups | Where-Object { $_.Title -eq $firstGroup.Title }
        
        $comparisonResults += [PSCustomObject]@{
            ObjectType = "Group"
            Name = $firstGroup.Title
            ExistsInFirstSite = $true
            ExistsInSecondSite = ($secondGroup -ne $null)
            FirstSiteItemCount = "N/A"
            SecondSiteItemCount = "N/A"
            Status = if ($secondGroup) { "Matched" } else { "Missing in Second Site" }
            SitePath = $firstGroup.SitePath
        }
    }
    
    # Compare Subsites
    Write-Host "Comparing Subsites..." -ForegroundColor Yellow
    foreach ($firstSubsite in $FirstSiteObjects.Subsites) {
        $secondSubsite = $SecondSiteObjects.Subsites | Where-Object { $_.Title -eq $firstSubsite.Title }
        
        $comparisonResults += [PSCustomObject]@{
            ObjectType = "Subsite"
            Name = $firstSubsite.Title
            ExistsInFirstSite = $true
            ExistsInSecondSite = ($secondSubsite -ne $null)
            FirstSiteItemCount = "N/A"
            SecondSiteItemCount = "N/A"
            Status = if ($secondSubsite) { 
                if ($secondSubsite.WebTemplate -eq $firstSubsite.WebTemplate) { "Matched" } else { "Template Mismatch" }
            } else { "Missing in Second Site" }
            SitePath = $firstSubsite.SitePath
        }
    }
    
    # Process subsites' comparison data if available
    foreach ($firstSubsiteUrl in $FirstSiteObjects.SubsiteData.Keys) {
        $firstSubsiteTitle = ($FirstSiteObjects.Subsites | Where-Object { $_.Url -eq $firstSubsiteUrl }).Title
        $secondSubsiteUrl = $null
        
        # Find matching subsite in second site
        foreach ($secondSubsite in $SecondSiteObjects.Subsites) {
            if ($secondSubsite.Title -eq $firstSubsiteTitle) {
                $secondSubsiteUrl = $secondSubsite.Url
                break
            }
        }
        
        if ($secondSubsiteUrl -and $SecondSiteObjects.SubsiteData.ContainsKey($secondSubsiteUrl)) {
            # Both sites have the subsite - compare them
            Write-Host "Comparing subsite content for $firstSubsiteTitle..." -ForegroundColor Yellow
            $subsiteResults = Compare-SharePointObjects -FirstSiteObjects $FirstSiteObjects.SubsiteData[$firstSubsiteUrl] -SecondSiteObjects $SecondSiteObjects.SubsiteData[$secondSubsiteUrl]
            $comparisonResults += $subsiteResults
        }
    }
    
    return $comparisonResults
}

# Main script execution
$ErrorActionPreference = "Stop"

Write-Host "SharePoint Comparison Tool" -ForegroundColor Green
Write-Host "------------------------" -ForegroundColor Green

if ($ProcessSubsites) {
    Write-Host "Subsite processing enabled with max depth: $MaxDepth" -ForegroundColor Cyan
} else {
    Write-Host "Subsite processing disabled" -ForegroundColor Yellow
}

# Connect to first site
$firstSiteConnected = Connect-SharePointSite -SiteUrl $FirstSiteUrl -Credentials $Credentials
if (-not $firstSiteConnected) {
    Write-Host "Failed to connect to first site. Exiting script." -ForegroundColor Red
    exit
}

# Get objects from first site
$firstSiteObjects = Get-SharePointObjects -SiteUrl $FirstSiteUrl -MaxDepth $MaxDepth -ProcessSubsites $ProcessSubsites
Write-Host "Retrieved $(($firstSiteObjects.Lists).Count) lists and $(($firstSiteObjects.Libraries).Count) libraries from first site" -ForegroundColor Green

# Disconnect from first site to prevent context issues
Disconnect-PnPOnline

# Connect to second site
$secondSiteConnected = Connect-SharePointSite -SiteUrl $SecondSiteUrl -Credentials $Credentials
if (-not $secondSiteConnected) {
    Write-Host "Failed to connect to second site. Exiting script." -ForegroundColor Red
    exit
}

# Get objects from second site
$secondSiteObjects = Get-SharePointObjects -SiteUrl $SecondSiteUrl -MaxDepth $MaxDepth -ProcessSubsites $ProcessSubsites
Write-Host "Retrieved $(($secondSiteObjects.Lists).Count) lists and $(($secondSiteObjects.Libraries).Count) libraries from second site" -ForegroundColor Green

# Disconnect from second site
Disconnect-PnPOnline

# Compare objects
$comparisonResults = Compare-SharePointObjects -FirstSiteObjects $firstSiteObjects -SecondSiteObjects $secondSiteObjects

# Output results
Write-Host "Comparison Results:" -ForegroundColor Green
Write-Host "-------------------" -ForegroundColor Green
Write-Host "Total objects compared: $($comparisonResults.Count)" -ForegroundColor Cyan
Write-Host "Matched: $(($comparisonResults | Where-Object { $_.Status -eq "Matched" }).Count)" -ForegroundColor Green
Write-Host "Mismatched: $(($comparisonResults | Where-Object { $_.Status -ne "Matched" }).Count)" -ForegroundColor Yellow
Write-Host "Missing in Second Site: $(($comparisonResults | Where-Object { $_.Status -eq "Missing in Second Site" }).Count)" -ForegroundColor Red
Write-Host "Extra in Second Site: $(($comparisonResults | Where-Object { $_.Status -eq "Extra in Second Site" }).Count)" -ForegroundColor Magenta

# Export to CSV
$comparisonResults | Export-Csv -Path $ReportPath -NoTypeInformation
Write-Host "Report exported to: $ReportPath" -ForegroundColor Green

Write-Host "Comparison completed successfully!" -ForegroundColor Green
