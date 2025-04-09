# Input System Managed Identity Object ID.
$miObjectID = "aa838e56-c121-42d3-8c3d-011471166887"

# App ID - SharePoint Online API; Same In All Tenants. 
$appId = "00000003-0000-0ff1-ce00-000000000000"

# Add API permissions Required By Script. Separate Multiple Permission String Literals With Comma.
$permissionsToAdd = "Sites.FullControl.All"#, "Possible.Other.Permission"

Connect-AzureAD

$app = Get-AzureADServicePrincipal -Filter "AppId eq '$appId'"

foreach ($permission in $permissionsToAdd)
{
   $role = $app.AppRoles | where Value -Like $permission | Select-Object -First 1
   New-AzureADServiceAppRoleAssignment -Id $role.Id -ObjectId $miObjectID -PrincipalId $miObjectID -ResourceId $app.ObjectId
}
