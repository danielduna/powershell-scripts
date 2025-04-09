# Define Variables.

$sharedMailbox = "anglianwater@carterjonas.co.uk"
$outputFilePath = "C:\IT"

# Retrieve Message Data. 
$mailData = Get-MessageTrace -SenderAddress $sharedMailbox | Select-Object Date, Time, RecipientStatus, MessageSubject, TotalBytes, Directionality

# Export Data To CSV. 
$mailData | Export-Csv -Path $outputFilePath -NoTypeInformation