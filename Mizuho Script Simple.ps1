# Prompt for SharePoint site URL
$siteUrl = Read-Host "Enter The SharePoint Site URL"

# Prompt for Page ID
$pageId = Read-Host "Enter The ID Of The Site Page"

# Generate Date List
$startDate = Get-Date -Year (Get-Date).Year -Month 1 -Day 1
$today = Get-Date
$dates = @()

while ($startDate -le $today) {
    $dates += $startDate.ToString("yyyy-MM-dd")
    $startDate = $startDate.AddDays(1)
}

# Display "Dropdown"
Write-Host "Select A Date To Set (Time will always be 08:00 UTC):"
for ($i = 0; $i -lt $dates.Count; $i++) {
    Write-Host "$($i + 1). $($dates[$i])"
}

$dateChoice = Read-Host "Enter The Number Of Your Choice"
if (-not ($dateChoice -as [int]) -or $dateChoice -lt 1 -or $dateChoice -gt $dates.Count) {
    Write-Host "Invalid Choice. Exiting."
    exit
}

# Get Selected Date & Set Time To 08:00
$chosenDate = $dates[$dateChoice - 1]
$finalDateTime = [DateTime]::Parse("$chosenDate 08:00:00").ToUniversalTime()

# Connect To SharePoint
Connect-PnPOnline -Url $siteUrl -UseWebLogin

# Show Current Published Date
$currentDate = (Get-PnPListItem -List 'SitePages' -Id $pageId | Select -ExpandProperty FieldValues).Get_Item("FirstPublishedDate")
Write-Host "Current Published Date: $currentDate"

# Update The Page's Published Date
Set-PnPListItem -List 'SitePages' -Identity $pageId -Values @{"FirstPublishedDate" = $finalDateTime}

Write-Host "FirstPublishedDate Updated To $finalDateTime Successfully."
