# Check FortiClient Version.
$softwareName = "FortiClient VPN"
$requiredVersion = "7.0.10.0538"

# Define Allowed IP Address Range. 
$allowedIPRange ="192.168.*"

# Get Device IP. 
$currentIPAddress = (Resolve-DnsName $env:COMPUTERNAME -ErrorAction SilentlyContinue).IPAddress

Write-Host "Current IP Address: $currentIPAddress"

# Condition For Installation.
if ($currentIPAddress -like $allowedIPRange -and $currentIPAddress -notlike '100.*' -and $currentIPAddress -notlike '192.168.0.*' -and $currentIPAddress -notlike '192.168.1.*') {
    # ... rest of the script ...
} else {
    Write-Host "Script will not run because the device's IP address ($currentIPAddress) is not within the allowed IP range."
}

# Query WMI For Information About Software.
$software = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq $softwareName }

# Check FortiClient Is installed & Version Is Less Than Required. 
if ($software -and [version]$software.Version -lt [version]$requiredVersion) {
    Write-Host "FortiClient Version: $($software.Version)"

    # Install FortiClient Silently.
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"\\pet-sccm-01\SMS Packages\APPLICATIONS\FORTICLIENT_7.0.10.0538\FortiClientVPNSetup_7.0.10.0538.msi`" /qn /norestart INSTALLLEVEL=3" -Wait

    # Apply Registry Keys.
    reg import "`"\\pet-sccm-01\SMS Packages\APPLICATIONS\FORTICLIENT_7.0.10.0538\add_IPsec_tunnel.reg`"" /reg:64

    # Display Message After Installation.
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show("Your VPN has been upgraded. Please re-start your machine while in the office to ensure the software is fully configured.", "VPN Upgrade", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
} else {
    Write-Host "FortiClient is either not installed or already at version $requiredVersion. No further action needed."
}
 