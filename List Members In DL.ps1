# Script Only Works In Domain Controllers. 

$groupName = "Profit Code - WA362-11601954781"

# Retrieve Members.
$groupMembers = Get-ADGroupMember -Identity $groupName

# Display Members.
foreach ($member in $groupMembers) {
    if ($member.objectClass -eq "user") {
        Write-Host "User: $($member.name) [$($member.samAccountName)]"
    } elseif ($member.objectClass -eq "group") {
        Write-Host "Group: $($member.name) [$($member.samAccountName)]"
    }
}