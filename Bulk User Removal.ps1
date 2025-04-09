# Import CSV.
$Users = Import-Csv "C:\IT\UPN.csv"

# OU.
$Group = "CJ Valuation Group" 

foreach ($User in $Users) {
    # Retrieve UPN.
    $UPN = $User.UserPrincipalName

    # Retrieve UPN Related SamAccountName.
    $ADUser = Get-ADUser -Filter "UserPrincipalName -eq '$UPN'" | Select-Object SamAccountName
    
    # User From CSV Not In AD.
    if ($ADUser -eq $null) {
        Write-Host "$UPN does not exist in AD" -ForegroundColor Red
    }
    else {
        # Retrieve AD User Group Membership. 
        $ExistingGroups = Get-ADPrincipalGroupMembership $ADUser.SamAccountName | Select-Object Name

        # User Member Of Group.
        if ($ExistingGroups.Name -eq $Group) {

            # Remove User From Group.
            Remove-ADGroupMember -Identity $Group -Members $ADUser.SamAccountName -Confirm:$false -WhatIf
            Write-Host "Removed $UPN from $Group" -ForeGroundColor Green
        }
        else {
            # User Not Member Of Group.
            Write-Host "$UPN does not exist in $Group" -ForeGroundColor Yellow
        }
    }
}
Stop-Transcript