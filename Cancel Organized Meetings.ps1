# Import Exchange Module.
Import-Module ExchangeOnlineManagement

# Connect To Exchange Online.
Connect-ExchangeOnline

# Function For Splash Screen.
function Show-InputBox([string]$Message, [string]$WindowTitle, [string]$DefaultText)
{
    [void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
    return [Microsoft.VisualBasic.Interaction]::InputBox($Message, $WindowTitle, $DefaultText)
}

# Enter Email Address.
$email = Show-InputBox -Message 'Enter CJ Email Address' -WindowTitle 'Email Address' -DefaultText ''

#Delete All Meeting For Specified User. 
Remove-CalendarEvents -Identity $email -CancelOrganizedMeetings -Confirm:$false -QueryWindowInDays 120
