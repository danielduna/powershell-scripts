# Import the Active Directory module
Import-Module ActiveDirectory

# Import the Exchange Online module
Import-Module ExchangeOnlineManagement

# Get all users in the "Leavers" OU
$users = Get-ADUser -SearchBase "OU=Leavers,OU=Carter Jonas Offices,DC=cj,DC=local" -Filter *

# Disable each user
foreach ($user in $users) {
    Set-ADUser $user -Enabled $false
}

# Set the location of the logon scripts
$location = "\\cj.local\sysvol\cj.local\scripts"

# Get all users in the "Leavers" OU
$users = Get-ADUser -SearchBase "OU=Leavers,OU=Carter Jonas Offices,DC=cj,DC=local" -Filter *

# Loop through each user and delete their logon script
foreach ($user in $users) {
    $script = $user.SamAccountName + ".bat"
    $scriptPath = Join-Path $location $script

    # Check if the script exists and delete it if it does
    if (Test-Path $scriptPath) {
        Remove-Item $scriptPath
        Write-Host "Deleted logon script $script for user $($user.SamAccountName)"
    }
    else {
        Write-Host "Logon script $script for user $($user.SamAccountName) not found"
    }
    # Get all users in the "Leavers" OU
$users = Get-ADUser -SearchBase "OU=Leavers,OU=Carter Jonas Offices,DC=cj,DC=local" -Filter *

# Loop through each user and remove their group memberships
foreach ($user in $users) {
    $groups = Get-ADPrincipalGroupMembership -Identity $user.SamAccountName
    foreach ($group in $groups) {
        if (($group.Name -notlike 'SAM*') -and ($group.Name -notlike 'APP*') -and ($group.Name -ne 'Domain Users')) {
            Remove-ADPrincipalGroupMembership -Identity $user.SamAccountName -MemberOf $group.Name
            Write-Host "Removed user $($user.SamAccountName) from group $($group.Name)"
        }
    }
}