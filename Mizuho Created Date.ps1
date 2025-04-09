Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
 
# Creating The Calendar.
$form = New-Object System.Windows.Forms.Form
$form.Text = "Select A Date"
$form.Size = New-Object System.Drawing.Size(250, 250)
$form.StartPosition = "CenterScreen"
 
# Create MonthCalendar Control.
$calendar = New-Object System.Windows.Forms.MonthCalendar
$calendar.MaxSelectionCount = 1
$calendar.Dock = "Fill"
$form.Controls.Add($calendar)
 
# Create OK Button.
$okButton = New-Object System.Windows.Forms.Button
$okButton.Text = "OK"
$okButton.Dock = "Bottom"
$okButton.Add_Click({
    $form.Tag = $calendar.SelectionStart
    $form.Close()
})
$form.Controls.Add($okButton)
 
# Display Form.
$form.ShowDialog() | Out-Null
$selectedDate = $form.Tag
 
# Checking Date Selected.
if (-not $selectedDate) {
    Write-Host "No Date Selected - Exiting."
    exit
}
 
# Set Fixed Time - 08:00:00 UTC.
$finalDateTime = [datetime]::Parse("$($selectedDate.ToString("yyyy-MM-dd")) 08:00:00").ToUniversalTime()
 
# Prompt SharePoint URL & Page ID.
$siteUrl = Read-Host "Enter The SharePoint Site URL"
$pageId = Read-Host "Enter The ID Of The Site Page"
 
# Connect & Update.
Connect-PnPOnline -Url $siteUrl -UseWebLogin
 
$currentDate = (Get-PnPListItem -List 'SitePages' -Id $pageId | Select -ExpandProperty FieldValues).Get_Item("Created")
Write-Host "Current Created Date: $currentDate"
 
Set-PnPListItem -List 'SitePages' -Identity $pageId -Values @{"Created" = $finalDateTime}
 
Write-Host "Created Date Updated To $finalDateTime Successfully."

# Retrieve List Item.
$pageItem = Get-PnPListItem -List "Site Pages" -Id $pageId

# Get The File Object.
$file = $pageItem.File

# Null Check.
if ($file -ne $null) {
    $file.Publish("Published")
    Invoke-PnPQuery
    Write-Host "Page Published Successfully."
} else {
    Write-Error "Could NOT Retrieve File Object For The Page. Publish Failed."
}
