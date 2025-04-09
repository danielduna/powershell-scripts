# Load PnP PowerShell Module
Import-Module PnP.PowerShell

# Define URLs
$sourceSiteUrl = "https://spbsd.sharepoint.com/sites/Sandbox"
$destinationSiteUrl = "https://spbsd.sharepoint.com/sites/MSFT"

# Define Document Libraries. 
$sourceLibraryName = "Documents"
$destinationLibraryName = "Documents"

# Connect To Source SPS.
Connect-PnPOnline -Url $sourceSiteUrl -ClientID 56abd785-ac07-41a9-b935-8788eb839aaf -Interactive

# Get All Files From Source Library. 
$sourceFiles = Get-PnPListItem -List $sourceLibraryName -Fields "FileLeafRef" | Select-Object -ExpandProperty FileLeafRef

# DC From Source SPS. 
Disconnect-PnPOnline

# Connect To Destination SPS.
Connect-PnPOnline -Url $destinationSiteUrl -ClientID 56abd785-ac07-41a9-b935-8788eb839aaf -Interactive

# Get All Files From Destination Library.
$destinationFiles = Get-PnPListItem -List $destinationLibraryName -Fields "FileLeafRef" | Select-Object -ExpandProperty FileLeafRef

# DC From Destination SPS. 
Disconnect-PnPOnline

# Compare Files.
$missingFiles = $sourceFiles | Where-Object { $_ -notin $destinationFiles }

# Output Results. 
if ($missingFiles.Count -gt 0) {
    Write-Host "The Following Files Have Not Been Migrated To The Destination Site:"
    $missingFiles
} else {
    Write-Host "All Files From The Source Site Have Been Migrated To The Destination Site."
}
