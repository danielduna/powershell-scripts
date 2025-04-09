# Key Paths
$bagsPath = "HKCU:\Software\Microsoft\Windows\Shell\Bags"
$bagMRUPath = "HKCU:\Software\Microsoft\Windows\Shell\BagMRU"
$runMRUPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU"
$typedPathsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths"

# Function To Delete Registry Key
function Delete-RegistryKey {
    param (
        [string]$keyPath
    )
    if (Test-Path $keyPath) {
        Remove-Item -Path $keyPath -Recurse -Force
        Write-Output "Deleted $keyPath"
    } else {
        Write-Output "$keyPath does not exist"
    }
}

# Delete Key Paths
Delete-RegistryKey -keyPath $bagsPath
Delete-RegistryKey -keyPath $bagMRUPath
Delete-RegistryKey -keyPath $runMRUPath
Delete-RegistryKey -keyPath $typedPathsPath

# Clear AppData
Remove-Item -Path "$env:APPDATA\Microsoft\Windows\Recent\*" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations\*" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:APPDATA\Microsoft\Windows\Recent\CustomDestinations\*" -Force -ErrorAction SilentlyContinue

# Confirmation Message 
Write-Output "Registry keys have been successfully deleted."
