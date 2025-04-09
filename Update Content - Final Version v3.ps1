# Import PnP Module.
Import-Module PnP.PowerShell

# Set Error Action Preference Globally.
$ErrorActionPreference = "Stop"

# Log File Path.
$logFilePath = "C:\IT Tools\Silicon Reef\LogFile_$(Get-Date -Format 'yyyyddMM').log"

# Start Transcript For Logging.
Start-Transcript -Path $logFilePath -Append

# Function - Read Site URLs From CSV.
function Get-SiteUrlsFromCsv {
    param (
        [string]$csvFilePath
    )

    try {
        # Checking For File Existence. 
        if (-Not (Test-Path $csvFilePath)) {
            Write-Error "File Not Found: $csvFilePath"
            Stop-Transcript
            exit
        }

        # Import CSV.
        $siteUrls = Import-Csv -Path $csvFilePath
        if ($siteUrls.Count -eq 0) {
            Write-Host "No URLs In CSV." -ForegroundColor Yellow
            Stop-Transcript
            exit
        }

        # Check For "SiteURL" Header. 
        if (-Not $siteUrls[0].PSObject.Properties.Match("SiteURL")) {
            Write-Error "Expected 'SiteURL' Header Not Found In CSV."
            Stop-Transcript
            exit
        }

        return $siteUrls
    } catch {
        Write-Error "Error Reading CSV: $_"
        Stop-Transcript
        exit
    }
}

# Function - Connect SPO.
function Connect-ToSharePoint {
    param (
        [string]$siteUrl
    )

    try {
        Connect-PnPOnline -Url $siteUrl -ClientId dec9deb1-6460-4ff4-92b8-010b868f4513 -Interactive
        Write-Host "Successfully Connected To SPS: $siteUrl" -ForegroundColor Green
    } catch {
        Write-Error "Error Connecting To: $_"
    }
}

# Function - Increment News Post Dates & Publish Pages.
function Update-AndPublishNewsPosts {
    param (
        [int]$daysToIncrement
    )

    try {
        # Retrieve All Items From 'Site Pages' Library.
        $pages = Get-PnPListItem -List "Site Pages"

        if ($pages.Count -eq 0) {
            Write-Host "No site pages found." -ForegroundColor Yellow
            return
        }

        Write-Host "Retrieved $($pages.Count) pages from 'Site Pages'." -ForegroundColor Green

        # Filter News Posts (PromotedState "2" = News Post).
        $newsPosts = $pages | Where-Object { $_["PromotedState"] -eq 2 }

        if ($newsPosts.Count -eq 0) {
            Write-Host "No news posts found." -ForegroundColor Yellow
            return
        }

        Write-Host "Found $($newsPosts.Count) news posts to update." -ForegroundColor Green

        foreach ($page in $newsPosts) {
            # Validate 'FirstPublishedDate' Exists.
            if ($page["FirstPublishedDate"] -eq $null) {
                Write-Warning "FirstPublishedDate field is missing for page $($page['FileLeafRef'])."

                # Update Missing FirstPublishedDate.
                $lastModified = $page["Modified"]
                Set-PnPListItem -List "Site Pages" -Identity $page.Id -Values @{"FirstPublishedDate" = $lastModified}

                Write-Host "Added FirstPublishedDate For Page: $($page['FileLeafRef']) to $lastModified" -ForegroundColor Green
                continue
            }

            $originalDate = $page["FirstPublishedDate"]
            $newDate = $originalDate.AddDays($daysToIncrement)

            try {
                # Update FirstPublishedDate Field.
                Set-PnPListItem -List "Site Pages" -Identity $page.Id -Values @{"FirstPublishedDate" = $newDate}

                Write-Host "Updated News Post: $($page['FileLeafRef'])" -ForegroundColor Green
                Write-Host "Old Published Date: $originalDate" -ForegroundColor Cyan
                Write-Host "New Published Date: $newDate" -ForegroundColor Cyan

                # Try Publishing Page.
                try {
                    $page.File.Publish("Published")
                    Write-Host "Successfully Published Page: $($page['FileLeafRef'])" -ForegroundColor Green
                } catch {
                    Write-Error "Failed To Publish Page: $($page['FileLeafRef']) - $_"
                }

            } catch {
                Write-Error "Failed Updating News Post: $($page['FileLeafRef']) - $_"
            }
        }

        Write-Host "All News Post Dates Updated & Published Successfully!" -ForegroundColor Green
    } catch {
        Write-Error "Error Updating OR Publishing News Post: $_"
    }
}

# Function - Main Script Logic.
function Main {
    # Define Path To CSV File.
    $csvFilePath = "C:\IT Tools\Silicon Reef\News Post Sites.csv"

    # Get Site URLs From CSV.
    $siteUrls = Get-SiteUrlsFromCsv -csvFilePath $csvFilePath

    # Define Days To Increment.
    $daysToIncrement = 14

    # Process Each Site URL.
    foreach ($site in $siteUrls) {
        $siteUrl = $site.SiteURL

        # Log URL Being Processed.
        Write-Host "Processing site: $siteUrl" -ForegroundColor Yellow

        # Attempt Connection To SP.
        Connect-ToSharePoint -siteUrl $siteUrl

        # Update & Publish News Posts.
        Update-AndPublishNewsPosts -daysToIncrement $daysToIncrement
    }
}

# Execute Main Function.
Main

# Stop Transcript For Logging.
Stop-Transcript
