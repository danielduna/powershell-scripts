$sites = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest().Sites | Sort-Object Name
foreach ($site in $sites) {
    foreach ($subnet in $site.Subnets) {
        $subnetAddress = $subnet.ToString().Split('/')[0]
        $subnetAddress = $subnetAddress.Split('.')[0..2] -join '.'
        write-host "$site,$subnetAddress"
    }
}