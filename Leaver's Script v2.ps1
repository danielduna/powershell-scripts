#Load Credentials From Secure.xml
$credentials = Import-Credentials -Path "C:\IT\Credentials\Secure.xml"

#Setting Domain & OU Variables.
$domain = "cj.local"
$ou = "Leavers"

#Grabbing Members In OU Group.
$members = Get-ADGroupMember -Identity "$ou" -Server "$domain" -Credential $credentials

#Checking OU For Any Members.
if ($members.Count -eq 0) {
    Write-Host "There are no members in the '$ou' group in the '$domain' domain. Script cancelled."
    return
}

#If Members Exist Continue, If Not Cancel Script.
Write-Host "There are $($members.Count) members in the '$ou' group in the '$domain' domain. Continuing with the script..."

# Create Empty Array To Store Leavers
$leavers = @()

# Looping Through Each User In Group.
foreach ($member in $members) {
    # Get the user object from AD
    $user = Get-ADUser -Identity $member.SamAccountName -Server $domain -Credential $credentials

    # Checking If User Exists.
    if ($user) {
        # Define Users Logon Script.
        $bat = $user.SamAccountName  + '.Bat'

        #Setting Location Of Logon Script.
        set-location \\cj.local\sysvol\cj.local\scripts

        #Delete Scipts.
        Remove-Item $bat

        #Disable User.
        Disable-ADAccount -Identity $user.SamAccountName -Server $domain -Credential $credentials

        #Hiding User From GAL In AttributeEditor.
        Set-ADUser -Identity $user.SamAccountName -Server $domain -HiddenFromAddressListsEnabled $true -Credential $credentials

        #Remove All Groups Except, SAM/APP.
        $allowedGroups = Get-ADGroup -Filter {Name -like "SAM*" -or Name -like "APP*"} -Server $domain -Credential $credentials
        $groupsToRemove = $user.MemberOf | Where-Object { $_ -notmatch "^CN=SAM|^CN=APP" } | Get-ADGroup -Server $domain -Credential $credentials
        foreach ($group in $groupsToRemove) {
            if ($allowedGroups -notcontains $group) {
                Remove-ADGroupMember -Identity $group -Members $user -Server $domain -Credential $credentials
            }
        }
        # Disabling All Meetings By User.
        Remove-CalendarEvents -Identity $user.UserPrincipalName -CancelOrganizedMeetings -Confirm:$false -QueryWindowInDays 120
        Write-Host "All meetings created by $($user.UserPrincipalName) have been cancelled."

        #Add User To $leavers Array
        $leaver = [PSCustomObject]@{
            Name = $user.Name
            SamAccountName = $user.SamAccountName
            UserPrincipalName = $user.UserPrincipalName
            WhenCreated = $user.WhenCreated
            Disabled = $true
            HiddenFromAddressListsEnabled = $true
        }
        $leavers += $leaver
    } else {
        Write-Host "User $($member.SamAccountName) not found in the '$domain' domain."
    }
}

#Export Leavers To CSV
$leavers | Export-Csv -Path "C:\IT\Leavers.csv" -Append -NoTypeInformation

#Move User Into The Accounts - Old Users OU.
$oldUsersOU = "OU=Accounts - Old Users,DC=cj,DC=local"
Move-ADObject -Identity $user.DistinguishedName -TargetPath $oldUsersOU -Server $domain
