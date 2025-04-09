# Connect To Exchange
Connect-ExchangeOnline

# Replace "SM - Steele Bodget" With SM's Display Name
Set-Mailbox -Identity "SM - Steele Bodget" -MessageCopyForSendOnBehalfEnabled $true -MessageCopyForSentAsEnabled $true