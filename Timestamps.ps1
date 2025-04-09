# Create CSV.
$CSVFileName = (Get-Date -UFormat "%m-%Y") + ".csv"
$CSVlocation = "\\PET-DC-04.cj.local\Logons$\" + $CSVFileName

# Gather Client Info. 
if (Test-Connection cj.local -Count 1 -BufferSize 1 -Quiet) {
    $upn = (whoami /upn)
    $computerName = $env:COMPUTERNAME
    $ipAddresses = (Get-NetIPAddress -AddressFamily IPv4 -PrefixOrigin Dhcp) | Where-Object { $_.IPAddress -like '192.168.*' -and $_.IPAddress -notlike '100.*' -and $_.IPAddress -notlike '192.168.0.*' -and $_.IPAddress -notlike '192.168.1.*' }
    $ipAddressString = $ipAddresses -Join ", "
    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"  
}
    
    # Create Object. 
    $output = [PSCustomObject]@{
        UPN = $upn
        ComputerName = $computerName
        IPAddresses = $ipAddressString
        Date = $date
    }
    
    # Export to CSV.
if ($ipAddresses -ne $null){
    Export-Csv -InputObject $output -Path $CSVlocation -Append -NoTypeInformation -Force -ErrorAction Ignore -WarningAction Ignore -InformationAction Ignore -Encoding UTF8
    }