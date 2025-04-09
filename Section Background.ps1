# Import PnP Module
Import-Module PnP.PowerShell

# Function - Load & Parse JSON & Build Color Map
function Build-ColorMapFromJson {
    param (
        [string]$jsonContent
    )

    $colorMap = @{}

    try {
        $jsonArray = $jsonContent | ConvertFrom-Json

        foreach ($item in $jsonArray) {
            if ($item.background -and $item.sortIdx) {
                $background = $item.background.ToUpper()
                $colorMap[$background] = $item.sortIdx
            }
        }
    } catch {
        Write-Error "Error Parsing JSON: $_" -ErrorAction Stop
    }

    return $colorMap
}

# Function - Map Hex Codes To SortIdx Using The Color Map
function Get-ColorName {
    param (
        [string]$hexCode,
        [hashtable]$colorMap
    )

    return $colorMap[$hexCode.ToUpper()]
}

# Function - Extract Hex Code & SortIdx From Web Part
function Get-HexCodeFromWebPart {
    param (
        [Parameter(Mandatory=$true)]
        [object]$webPart,
        [hashtable]$colorMap
    )

    try {
        $properties = $webPart.PropertiesJson | ConvertFrom-Json

        $backgroundColorProperty = $properties.PSObject.Properties.Match("background").Value
        $background1Property = $properties.PSObject.Properties.Match("background1").Value
        $sortIdxProperty = $properties.PSObject.Properties.Match("sortIdx").Value

        # Filter Out If Both Background And Background1 Are Present
        if ($backgroundColorProperty -and $background1Property) {
            return "", ""
        }

        if ($backgroundColorProperty) {
            $backgroundColorProperty = $backgroundColorProperty.ToUpper()
            $sortIdx = Get-ColorName -hexCode $backgroundColorProperty -colorMap $colorMap

            if ($sortIdx) {
                return $sortIdx, $backgroundColorProperty
            } else {
                return "No Match Found", $backgroundColorProperty
            }
        } elseif ($sortIdxProperty) {
            return $sortIdxProperty, ""
        } else {
            return "", ""
        }
    } catch {
        Write-Host "Error Extracting Hex Code: $_" -ForegroundColor Red
        return "", ""
    }
}

# Function - Update Web Part Properties
function Update-WebPartProperties {
    param (
        [Parameter(Mandatory=$true)]
        [string]$pageName,
        [Parameter(Mandatory=$true)]
        [string]$webPartId,
        [string]$sortIdx
    )

    try {
        # Get Existing Properties
        $page = Get-PnPPage -Identity $pageName
        $control = $page.Controls | Where-Object { $_.InstanceId -eq $webPartId }

        if ($control) {
            $propertiesJson = $control.PropertiesJson

            # Check If PropertiesJson Is Null Or Empty
            if ($null -eq $propertiesJson -or $propertiesJson -eq "") {
                return
            }

            # Convert PropertiesJson To PowerShell Object
            $properties = $propertiesJson | ConvertFrom-Json -ErrorAction Stop

            # Add Or Update 'Background1' Property
            $properties | Add-Member -NotePropertyName "background1" -NotePropertyValue $sortIdx -Force -ErrorAction Stop

            $propertiesJson = $properties | ConvertTo-Json -Compress -ErrorAction Stop

            Write-Host "Updating Web Part With ID: $webPartId On Page: $pageName" -ForegroundColor Cyan
            Set-PnPPageWebPart -Page $pageName -Identity $webPartId -PropertiesJson $propertiesJson
            Write-Host "Web Part Properties Updated Successfully." -ForegroundColor Green
        } else {
            return
        }
    } catch {
        Write-Error "Error Updating Web Part Properties: $_" -ErrorAction Stop
    }
}

# CLI Prompt For SharePoint URL
function Get-UserInput {
    param (
        [string]$Message
    )
    Write-Host $Message -ForegroundColor Yellow
    return Read-Host
}

# Function - Display The Menu
function Show-Menu {
    Clear-Host
    Write-Host "SharePoint Page Navigator" -ForegroundColor Cyan
    Write-Host "Current Page: $($global:currentIndex + 1) Of $($global:results.Count)" -ForegroundColor Yellow
    Write-Host "1: Display All Results"
    Write-Host "N: Next Page"
    Write-Host "P: Previous Page"
    Write-Host "C: Display Current Page"
    Write-Host "A: Apply Update To Current Page"
    Write-Host "R: Refresh Results"
    Write-Host "Q: Quit"
}

# Function - Load Color Map & Retrieve Pages
function Load-ColorMapAndRetrievePages {
    if (-not $global:siteUrl) {
        $global:siteUrl = Get-UserInput -Message "Enter The SharePoint Site URL:"
    }

    try {
        Connect-PnPOnline -Url $global:siteUrl -Interactive
        Write-Host "Successfully Connected To SharePoint." -ForegroundColor Green
    } catch {
        Write-Error "Error Connecting To SharePoint: $_"
        exit
    }

    try {
        $swatchesFile = Get-PnPFile -Url "SiteAssets/swatches.txt" -AsString -ErrorAction stop
        Write-Host "Swatches.txt Retrieved." -ForegroundColor Green

        $colorMap = Build-ColorMapFromJson -jsonContent $swatchesFile
        Write-Host "Color Map Built." -ForegroundColor Green
    } catch {
        Write-warning "Failed to find swatches.txt file on this site. Attempting to connect to the Hub site."
        $connectedSite = Get-PnPSite -Includes HubSiteId
        try{
            $hubSite = Get-PnPTenantSite -Identity "$($connectedSite.HubSiteId)" -ErrorAction Stop
            $hubsiteConnection = connect-pnponline -Url $hubSite.Url -Interactive -ReturnConnection
            $swatchesFile = Get-PnPFile -Url "SiteAssets/swatches.txt" -AsString -Connection $hubsiteConnection -ErrorAction stop
            $colorMap = Build-ColorMapFromJson -jsonContent $swatchesFile
            write-host "Color Map Built - From Hub Swatches File" -ForegroundColor Green

        }catch{
            Write-Error "Error getting swatches.txt file" -ErrorAction Stop
        }
    }

    if ($colorMap.Count -eq 0) {
        write-warning "No Color Map Found. Exiting Script."
        exit
    }

    try {
        $pages = Get-PnPListItem -List "Site Pages" -Includes ContentType -ErrorAction Stop | where{$_.ContentType.Name -eq "Site Page"}
        Write-Host "Pages Processing." -ForegroundColor Green
    } catch {
        Write-Error "Error Retrieving Pages: $_"
        exit
    }

    $global:results = @()
    $global:pages = $pages

    function Process-Page {
        param (
            [Parameter(Mandatory=$true)]
            [object]$page
        )

        $pageName = $page.FieldValues["FileLeafRef"]

        try {
            $page = Get-PnPPage -Identity $pageName 
            $controls = $page.Controls

            foreach ($control in $controls) {
                if ($control.Title -eq "Section Background Webpart") {
                    $sortIdx, $webPartHexCode = Get-HexCodeFromWebPart -WebPart $control -ColorMap $colorMap

                    if ($webPartHexCode -ne "" -or $sortIdx -ne "") {
                        $result = [PSCustomObject]@{
                            PageName   = $pageName
                            HexCode    = $webPartHexCode
                            SortIdx    = $sortIdx
                            WebPartId  = $control.InstanceId
                        }
                        $global:results += $result
                    }
                }
            }
        } catch {
            Write-Error "Error Processing Page: $pageName" -ErrorAction Stop
            # Log Error If Needed Or Handle Accordingly
        }
    }

    foreach ($page in $global:pages) {
        Process-Page -page $page
    }

    if ($global:results.Count -gt 0) {
        Write-Host "`nResults Loaded. You Can Now Navigate Through The Pages." -ForegroundColor Green
    } else {
        Write-Host "No Results Found." -ForegroundColor Yellow
    }
}

# Function - Display All Results
function Display-AllResults {
    Clear-Host
    Write-Host "`nAll Results:" -ForegroundColor Cyan
    $global:results | Format-Table -Property PageName, HexCode, SortIdx
    Read-Host "Press Enter To Return To The Menu"
}

# Function - Display Current Page
function Display-CurrentPage {
    if ($global:results.Count -eq 0) {
        Write-Host "No Results Available. Please Load The Color Map And Pages First." -ForegroundColor Yellow
        return
    }

    if ($global:currentIndex -lt 0 -or $global:currentIndex -ge $global:results.Count) {
        Write-Host "Current Page Index Is Out Of Range." -ForegroundColor Red
        return
    }

    $currentPage = $global:results[$global:currentIndex]
    Clear-Host
    Write-Host "`nDisplaying Page $($global:currentIndex + 1) Of $($global:results.Count)" -ForegroundColor Cyan
    $currentPage | Format-Table -Property PageName, HexCode, SortIdx

    Write-Host "N: Next Page | P: Previous Page | R: Return To Menu | A: Apply Update | Q: Quit" -ForegroundColor Yellow
    $navigation = Read-Host "Select An Option"
    switch ($navigation) {
        'N' { Display-NextPage }
        'P' { Display-PreviousPage }
        'R' {
            Show-Menu
        }
        'A' {
            Update-WebPartProperties -pageName $currentPage.PageName -webPartId $currentPage.WebPartId -sortIdx $currentPage.SortIdx
        }
        'Q' {
            Write-Host "Exiting Script." -ForegroundColor Green
            exit
        }
        default {
            Write-Host "`nNot A Valid Selection" -ForegroundColor Red -NoNewline
            Start-Sleep -Seconds 1
            Display-CurrentPage
        }
    }
}

# Function - Display Next Page
function Display-NextPage {
    if ($global:results.Count -eq 0) {
        Write-Host "No Results Available. Please Load The Color Map And Pages First." -ForegroundColor Yellow
        return
    }

    $global:currentIndex = ($global:currentIndex + 1) % $global:results.Count
    Display-CurrentPage
}

# Function - Display Previous Page
function Display-PreviousPage {
    if ($global:results.Count -eq 0) {
        Write-Host "No Results Available. Please Load The Color Map And Pages First." -ForegroundColor Yellow
        return
    }

    $global:currentIndex = ($global:currentIndex - 1 + $global:results.Count) % $global:results.Count
    Display-CurrentPage
}

# Function - Refresh Results
function Refresh-Results {
    Write-Host "Refreshing Results..." -ForegroundColor Cyan

    # Reload The Color Map And Pages
    Load-ColorMapAndRetrievePages

    # Display The Updated Results
    if ($global:results.Count -gt 0) {
        Write-Host "`nResults Have Been Refreshed." -ForegroundColor Green
    } else {
        Write-Host "No Results Found After Refresh." -ForegroundColor Yellow
    }

    # Pause To Let The User Read The Message
    Read-Host "Press Enter To Return To The Menu"
}

# Initialize Global Variables
$global:results = @()
$global:currentIndex = 0
$global:siteUrl = $null

# Main Script
while ($true) {
    if (-not $global:siteUrl) {
        $global:siteUrl = Get-UserInput -Message "Enter The SharePoint Site URL:"
    }

    Load-ColorMapAndRetrievePages

    if ($global:results.Count -gt 0) {
        while ($true) {
            Show-Menu
            $selection = Read-Host "Please Make A Selection"

            switch ($selection) {
                '1' { Display-AllResults }
                'N' { Display-NextPage }
                'P' { Display-PreviousPage }
                'C' { Display-CurrentPage }
                'A' {
                    $currentPage = $global:results[$global:currentIndex]
                    Update-WebPartProperties -pageName $currentPage.PageName -webPartId $currentPage.WebPartId -sortIdx $currentPage.SortIdx
                }
                'R' { Refresh-Results }
                'Q' {
                    Write-Host "Exiting Script." -ForegroundColor Green
                    exit
                }
                default {
                    Write-Host "`nNot A Valid Selection" -ForegroundColor Red -NoNewline
                    Start-Sleep -Seconds 1
                }
            }
        }
    } else {
        Write-Host "No Results To Display. Exiting Script." -ForegroundColor Yellow
        exit
    }
}
