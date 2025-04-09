# Run .BAT.
Start-Process -FilePath "C:\IT\install.bat" -Wait -WindowStyle Hidden

# Install FortiClient.
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i C:\IT\FortiClientVPNSetup_7.0.10.0538.msi /passive /norestart INSTALLLEVEL=3" -Wait -WindowStyle Hidden

# Apply Registry Keys.
reg import "C:\IT\add_IPsec_tunnel.reg" /reg:64

# Message Display After Installation.
Add-Type -AssemblyName PresentationFramework
[System.Windows.MessageBox]::Show("Your VPN has been upgraded. Please re-start your machine while in the office to ensure software is fully configured.", "VPN Upgrade", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
