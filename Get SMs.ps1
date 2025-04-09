# Connect to Exchange Online - Assuming Exchange Module Is Installed. 
Connect-ExchangeOnline

# Function for Input Box
function Show-InputBox([string]$Message, [string]$WindowTitle, [string]$DefaultText) {
    [void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
    return [Microsoft.VisualBasic.Interaction]::InputBox($Message, $WindowTitle, $DefaultText)
}

# Function To Validate Email Address
function IsValidEmail($email) {
    if ($email -match '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$') {
        return $true
    }
    return $false
}

# Loop until a valid email address is entered
do {
    # Enter Email Address
    $userEmailAddress = Show-InputBox -Message 'Enter CJ Email Address' -WindowTitle 'Email Address' -DefaultText ''
    
    if (-not (IsValidEmail $userEmailAddress)) {
        [System.Windows.Forms.MessageBox]::Show('Invalid CJ Email Address. Please Enter A Valid Address.', 'Invalid Email', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
} until (IsValidEmail $userEmailAddress)

# List All Shared Mailboxes User Has Access To
Get-Mailbox -RecipientTypeDetails SharedMailbox | Get-MailboxPermission | Where-Object { $_.User -like $userEmailAddress } | ForEach-Object {
    Write-Host "Shared Mailbox: $($_.Identity) - Access Rights: $($_.AccessRights)"
}