# Import PnP Module.
Import-Module PnP.PowerShell

# Set Error Action Preference Globally.
$ErrorActionPreference = "Stop"

# Log File Path.
$logFilePath = "C:\Path\To\LogFile.log"

# Start Transcript For Logging.
Start-Transcript -Path $logFilePath -Append

# Function - Prompt SP URL.
function Get-UserInput {
    param (
        [string]$Message
    )
    Write-Host $Message -ForegroundColor Yellow
    return Read-Host
}

# Function - Connect SPO.
function Connect-ToSharePoint {
    param (
        [string]$siteUrl
    )

    try {
        Connect-PnPOnline -Url $siteUrl -ClientId dec9deb1-6460-4ff4-92b8-010b868f4513 -Interactive
        Write-Host "Successfully connected to SharePoint." -ForegroundColor Green
    } catch {
        Write-Error "Error connecting to SharePoint: $_"
        Stop-Transcript
        exit
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
                    Write-Host "Successfully published page: $($page['FileLeafRef'])" -ForegroundColor Green
                } catch {
                    Write-Error "Failed to publish page: $($page['FileLeafRef']) - $_"
                }

            } catch {
                Write-Error "Failed Updating News Post: $($page['FileLeafRef']) - $_"
            }
        }

        Write-Host "All News Post Dates Updated and Published Successfully!" -ForegroundColor Green
    } catch {
        Write-Error "Error Updating or Publishing News Post: $_"
    }
}

# Function - Main Script Logic.
function Main {
    # Get SP URL From User.
    $siteUrl = Get-UserInput -Message "Enter the SharePoint Site URL:"

    # Attempt Connection To SP.
    Connect-ToSharePoint -siteUrl $siteUrl

    # Define Days To Increment.
    $daysToIncrement = 11

    # Update & Publish News Posts.
    Update-AndPublishNewsPosts -daysToIncrement $daysToIncrement
}

# Execute Main function
Main

# Stop Transcript for Logging
Stop-Transcript
