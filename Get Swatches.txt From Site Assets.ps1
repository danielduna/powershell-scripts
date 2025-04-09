# Import PnP PowerShell Module
Import-Module PnP.PowerShell

# Function for Command Line Prompt
function Get-UserInput {
    param (
        [string]$Message
    )
    Write-Host $Message -ForegroundColor Yellow
    return Read-Host
}

# Command Line Prompt for SharePoint URL
$siteUrl = Get-UserInput -Message "Enter the SharePoint site URL:"

# Define Local Path
$localPath = "C:\IT Tools\swatches.txt"

# Connect To SPS
Connect-PnPOnline -Url $siteUrl -Interactive

# Get Swatches.txt From Site Assets
try {
    # Fetch Content - Swatches.txt From Site Assets
    $swatchesFileContent = Get-PnPFile -Url "SiteAssets/swatches.txt" -AsString

    # Save To Local File
    Set-Content -Path $localPath -Value $swatchesFileContent

    # Confirm File Has Been Saved
    Write-Host "Swatches.txt has been saved to $localPath" -ForegroundColor Green

} catch {
    # Error handling
    Write-Host "Error retrieving or saving swatches.txt: $_" -ForegroundColor Red
}

# Disconnect From SPS
Disconnect-PnPOnline
