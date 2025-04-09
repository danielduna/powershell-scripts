# Import the Exchange module
Import-Module ExchangeOnlineManagement

# Define the function to show a pop-up window
function Show-InputBox([string]$Message, [string]$WindowTitle, [string]$DefaultText)
{
    [void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
    return [Microsoft.VisualBasic.Interaction]::InputBox($Message, $WindowTitle, $DefaultText)
}

# Show a pop-up window to enter the email address
$email = Show-InputBox -Message 'Enter the email address' -WindowTitle 'Email Address' -DefaultText ''

$confirmation = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to run the script for email address '$email'?", "Confirmation", [System.Windows.Forms.MessageBoxButtons]::YesNo)

if ($confirmation -eq 'Yes') {
# Run the script for the entered email address
Write-Host "Running script for email address '$email'"
} else {
# Cancel the script if the user clicked 'No'
Write-Host 'Script cancelled'
}

# Delete all meetings for the specified email address
Remove-CalendarEvents -Identity $email -CancelOrganizedMeetings -Confirm:$false -QueryWindowInDays 120

# Connect to Exchange Online
Connect-ExchangeOnline 

# Connect to Active Directory
Import-Module ActiveDirectory
$user = Get-ADUser -Filter {EmailAddress -eq $email}

# Disable the user
Disable-ADAccount -Identity $user.SamAccountName

# Move the user to the 'Accounts - Old Users' OU group
$oldUsersOU = "OU=Accounts - Old Users,DC=cj,DC=local"
Move-ADObject -Identity $user.DistinguishedName -TargetPath $oldUsersOU

$groups = Get-ADPrincipalGroupMembership -Identity $user.SamAccountName
foreach ($group in $groups) {
    if (($group.Name -notlike 'SAM*') -and ($group.Name -notlike 'APP*') -and ($group.Name -ne 'Domain Users')) {
        Remove-ADPrincipalGroupMembership -Identity $user.SamAccountName -MemberOf $group.Name
    }
}

# Define Users Logon Script
$bat = $user.SamAccountName  + '.Bat'

# Set location of logon scripts
set-location \\cj.local\sysvol\cj.local\scripts

# Delete logon script
Remove-Item $bat
