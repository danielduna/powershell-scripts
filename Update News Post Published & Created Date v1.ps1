# Import Required Modules. 
Import-Module PnP.PowerShell
Import-Module Az.Storage 

# Set Error Action Preference Globally.
$ErrorActionPreference = "Stop"

# Define Blob Storage Details.
$storageAccountName = "filesanddocs"
$containerName = "psoutputs"
$blobName = "logs/ScriptOutput_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Authenticate Using Managed Identity For Azure Resources.
Connect-AzAccount -Identity

# Define Storage Context Globally.
$storageAccount = Get-AzStorageAccount -ResourceGroupName "Dev-RG" -Name $storageAccountName
$context = $storageAccount.Context

# Function - Start Logging.
function Start-Logging {
    $logFilePath = "$env:TEMP\ScriptOutput.txt"
    Start-Transcript -Path $logFilePath
    return $logFilePath
}

# Function - Stop Logging & Upload Log.
function Stop-LoggingAndUpload {
    $logFilePath = "$env:TEMP\ScriptOutput.txt"
    Stop-Transcript
    Upload-LogToBlob $logFilePath
}

# Function - Upload Log To Blob Storage.
function Upload-LogToBlob {
    param (
        [string]$logFilePath
    )

    try {
        # Upload Log File To Blob Storage.
        Set-AzStorageBlobContent -File $logFilePath -Container $containerName -Blob $blobName -Context $context
        Write-Host "Log Uploaded To Blob Storage Successfully." -ForegroundColor Green
    } catch {
        Write-Error "Error Uploading Log To Blob Storage: $_"
    }
}

# Function - Read URLs From CSV.
function Get-SiteUrlsFromCsv {
    param (
        [string]$csvUrl
    )

    try {
        # Download CSV From The URL.
        $tempCsvPath = "$env:TEMP\Sites.csv"
        Invoke-WebRequest -Uri $csvUrl -OutFile $tempCsvPath

        # Import CSV.
        $siteUrls = Import-Csv -Path $tempCsvPath
        if ($siteUrls.Count -eq 0) {
            Write-Host "No URLs In CSV." -ForegroundColor Yellow
            exit
        }

        # Check For "SiteURL" Header.
        if (-Not $siteUrls.PSObject.Properties.Match("SiteURL")) {
            Write-Error "Expected 'SiteURL' Header Not Found In CSV."
            exit
        }

        return $siteUrls
    } catch {
        Write-Error "Error Reading CSV: $_"
        exit
    }
}

# Function - Connect to SharePoint Online Using Managed Identity.
function Connect-ToSharePoint {
    param (
        [string]$siteUrl
    )

    try {
        # Connect To SPO Using Managed Identity.
        Connect-PnPOnline -Url $siteUrl -ManagedIdentity
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
        $pages = Get-PnPListItem -List "Site Pages"

        if ($pages.Count -eq 0) {
            Write-Host "No Site Pages Found." -ForegroundColor Yellow
            return
        }

        $newsPosts = $pages | Where-Object { $_["PromotedState"] -eq 2 }

        if ($newsPosts.Count -eq 0) {
            Write-Host "No News Posts Found." -ForegroundColor Yellow
            return
        }

        foreach ($page in $newsPosts) {
            if (-not $page["FileLeafRef"]) {
                Write-Error "FileLeafRef Not Found For Item ID $($page.Id). Skipping Publishing."
                continue
            }

            # Checking $page.File Availability.
            if ($page.File -eq $null) {
                Write-Warning "No File Property For Item ID $($page.Id). Skipping Publishing."
                continue
            }

            $originalPublishedDate = $page["FirstPublishedDate"]
            $originalCreatedDate = $page["Created"]

            # Increment Dates
            $newPublishedDate = $originalPublishedDate.AddDays($daysToIncrement)
            $newCreatedDate = $originalCreatedDate.AddDays($daysToIncrement)

            try {
                # Update Created & FirstPublishedDate Fields
                Set-PnPListItem -List "Site Pages" -Identity $page.Id -Values @{
                    "FirstPublishedDate" = $newPublishedDate
                    "Created" = $newCreatedDate
                }
                Write-Host "Updated News Post: $($page['FileLeafRef'])" -ForegroundColor Green
                Start-Sleep -Seconds 2

                # Publish Page.
                $page.File.Publish("Published")
                Invoke-PnPQuery
                Write-Host "Successfully Published Page: $($page['FileLeafRef'])" -ForegroundColor Green

            } catch {
                Write-Error "Failed To Update OR Publish Page: $($page['FileLeafRef']) - $_"
            }
        }

        Write-Host "All News Post Dates Updated & Published Successfully!" -ForegroundColor Green
    } catch {
        Write-Error "Error Updating OR Publishing News Posts: $_"
    }
}


# Function - Main Script Logic.
function Main {
    # Define CSV URL (Public URL).
    $csvUrl = "https://filesanddocs.blob.core.windows.net/csvs/Sites.csv"

    # Start Logging.
    $logFilePath = Start-Logging

    # Get Site URLs From CSV In Blob Storage.
    $siteUrls = Get-SiteUrlsFromCsv -csvUrl $csvUrl

    # Define Days To Increment.
    $daysToIncrement = 14

    # Process Each Site URL.
    foreach ($site in $siteUrls) {
        $siteUrl = $site.SiteURL

        # Log URL Being Processed.
        Write-Host "Processing Site: $siteUrl" -ForegroundColor Yellow

        # Attempt Connection To SP.
        Connect-ToSharePoint -siteUrl $siteUrl

        # Update & Publish News Posts.
        Update-AndPublishNewsPosts -daysToIncrement $daysToIncrement
    }

    # Stop Logging & Upload To Blob Storage.
    Stop-LoggingAndUpload
}

# Execute Main Function.
Main
