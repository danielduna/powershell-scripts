<#
.NAME
    SharePoint Retention Label Report

.SYNOPSIS
    This script performs a read-only audit of contents within Document Libraries containing specified retention labels.

.DESCRIPTION
    This script aims to provide a CSV containing all pieces of content across desired sites that contain a specified retention label.
    The information can then be used to change, add or, remove content with the specified label and the details of the content are output
    to be able to report on.

    Required Modules:
     - PnP.PowerShell

    Required Privilages:
     - SharePoint Administrator

    Input CSV Parameters 
       Required Parameters
          - Domain
               The domain of the relevant tenant. 
          - SiteUrl
               The URLs of the specific sites to audit.

.NOTES

    Author		  : Tristan Balman <Tristan.Balman@siliconreef.co.uk>
    Version       : 1.0.0
    Creation Date : 17/10/2024

    © Copyright 2024 Silicon Reef Ltd

    Revisions:
    1.0.0 | 23/10/2023 - Tristan Balman  - Initial Release version

#>

# Mandatory parameter(s)
param (
    [Parameter(Mandatory = $true)]
    [string] $domain,
    
    [Parameter(Mandatory = $true)]
    [string] $csvInputPath  # Path to the CSV file containing site URLs
)

# Variables used within the script
$adminSiteURL = "https://$domain-admin.sharePoint.com"
$retentionLabel = "Mark for Deletion"
$dateTime = (Get-Date).ToString("dd-MM-yyyy-hh-ss")
$fileName = "labelsReport " + $dateTime + ".csv"
$outputPath = "C:\IT Tools\Silicon Reef" + "\" + $fileName

# Initialize the global report variable to store content details (CHANGED: Global variable to ensure data is accumulated across sites)
$global:report = @()  # <<< CHANGE: Initializing global report variable for accumulation.

# ClientID provided by the App Registration to allow PnP Connection
$global:ClientID = Read-Host "Please enter the Client ID"

Connect-PnPOnline -Url $adminSiteURL -Interactive -ClientId $global:ClientID -ErrorAction Stop

# ReportSiteContents function checks each site for contents containing the specified retention label
function ReportSiteContents($siteUrl) {
    $siteReport = @()  # <<< CHANGE: Local report variable for each site.
    
    # Attempts connection to looped sites
    Connect-PnPOnline -Url $siteUrl -Interactive -ClientId $global:ClientID -ErrorAction Stop
    # Setting connection as a variable
    $siteConnection = Get-PnPConnection

    # Try/Catch to handle success/failure of site connections within the loop
    try {
        # Getting a list of locations to check for content within current site connection
        $DocLibraries = Get-PnPList -Includes Hidden, Title -Connection $siteConnection

        # Loop through sites whilst adding details to the output report
        $siteReport += $DocLibraries | ForEach-Object {  # <<< CHANGE: Accumulate data in local report ($siteReport) per site.
            Write-Host "Processing Library:" $_.Title -ForegroundColor Yellow
            # Setting current library in loop as a temporary variable
            $library = $_

            # Retrieve list items with necessary fields
            Get-PnPListItem -List $library.Title -Fields "ID", "_ComplianceTag", "_DisplayName", "FileLeafRef", "FileRef", "FSObjType" -PageSize 1000 -Connection $siteConnection | Where-Object { $_["FSObjType"] -eq 0 } | ForEach-Object {  
                # <<< CHANGE: Added FSObjType filter to process files only.
                
                # Output available fields for debugging purposes (ADDED FOR DEBUGGING)
                Write-Host "Available fields: $($_.FieldValues.Keys)" -ForegroundColor Cyan
                
                # Try to retrieve the file size using metadata if the direct field is unavailable (ADDED FILE SIZE RETRIEVAL LOGIC)
                $fileSize = $_["File_x0020_Size"]
                if (-not $fileSize) {
                    # ADDED: Fallback mechanism if File_x0020_Size is not available directly
                    $file = Get-PnPFile -Url $_["FileRef"] -AsListItem -ErrorAction SilentlyContinue
                    if ($file) {
                        $fileSize = $file["File_x0020_Size"]
                    }
                }

                # Add the content details to the report (CHANGED: Add to local site report)
                [PSCustomObject]@{
                    SiteUrl           = $siteUrl
                    Title             = $_.FieldValues["FileLeafRef"]
                    RelativePath      = $_.FieldValues["FileRef"]
                    RetentionLabel    = $_.FieldValues["_ComplianceTag"]
                    FileSize          = $fileSize  # <<< CHANGE: Added file size field
                    LastModified      = $_["Last_x0020_Modified"]
                }
            }
        }
    } catch {
        Write-Output "Exception: $($_.Exception.Message)" -ForegroundColor Red
    }

    return $siteReport  # <<< CHANGE: Return the local report for this site.
}

# Read the CSV file containing the site URLs
$siteUrls = Import-Csv -Path $csvInputPath

# Site connection loop and append to global report (CHANGED: Loop structure to append data from each site)
foreach ($site in $siteUrls) {
    $siteUrl = $site.Url
    
    Write-Host "Processing Site: $siteUrl" -ForegroundColor Magenta
    $siteReport = ReportSiteContents -siteUrl $siteUrl  # <<< CHANGE: Call the function for each site and collect the local report
    
    if ($siteReport -and $siteReport.Count -gt 0) {
        # <<< CHANGE: Append local report to global report
        $global:report += $siteReport  
    }
}

# Export details of audit and create output report (CHANGED: Export based on global report after processing all sites)
if ($global:report -and $global:report.Count -gt 0) {
    $global:report | Export-Csv -Path $outputPath -NoTypeInformation  # <<< CHANGE: Export the complete report.
    Write-Host "Process completed. Output CSV located at $outputPath"
} else {
    Write-Output "No data found" -ForegroundColor Orange
}
