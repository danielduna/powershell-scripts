Get-Team | Where {$_.DisplayName -eq "Health & Wellbeing Network"} | Select -ExpandProperty GroupID

#Get Users From CSV.
$TeamUsers = Import-Csv -Path "C:\IT\TG.csv"

#Specify Group ID.
$GroupID = "5246d451-f463-4ecd-a87b-5f805c5f70c3"
 
#Iterate Through Each User & Add To TG.
$TeamUsers | ForEach-Object {
       Add-TeamUser -GroupID $GroupID -User $_.Email -Role $_.Role
       Write-host "Added User:"$_.Email -f Green
}

