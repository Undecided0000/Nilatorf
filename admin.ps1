$settingFile = Join-Path $PSScriptRoot "setting.json"

function Show-Menu {
    Clear-Host
    Write-Host "========================================="
    Write-Host " Nilatorf STN Access Admin Tool"
    Write-Host "========================================="
    Write-Host ""
    Write-Host "Current Settings:"
    if (Test-Path $settingFile) {
        Get-Content $settingFile | Write-Host
    } else {
        Write-Host "setting.json not found. Creating a new one."
        "{`n}`n" | Set-Content $settingFile -Encoding ASCII
    }
    Write-Host ""
    Write-Host "========================================="
    Write-Host "[1] Change PL1 status"
    Write-Host "[2] Change PL2 status"
    Write-Host "[3] Change PL3 status"
    Write-Host "[4] Change PL4 status"
    Write-Host "[5] Change PL5 status"
    Write-Host ""
    Write-Host "[9] Save and Push to GitHub"
    Write-Host "[0] Exit"
    Write-Host "========================================="
    $option = Read-Host "Select menu (0-9)"
    return $option
}

while ($true) {
    $option = Show-Menu

    if ($option -eq '0') {
        break
    }
    elseif ($option -eq '9') {
        Write-Host "`nPushing changes to GitHub..."
        Set-Location $PSScriptRoot
        git add "setting.json"
        git commit -m "Update access settings from admin tool"
        git push
        Write-Host "`nPush completed."
        Read-Host "Press Enter to return"
    }
    elseif ($option -match '^[1-5]$') {
        $plId = "PL$option"
        Write-Host "`nSelect new status for $plId :"
        Write-Host "[1] ok (Allow access)"
        Write-Host "[2] ng (Show Error / Freeze)"
        Write-Host "[3] t  (Redirect to Booth)"
        $statusOpt = Read-Host "Select (1-3)"

        $newStatus = ""
        if ($statusOpt -eq '1') { $newStatus = "ok" }
        elseif ($statusOpt -eq '2') { $newStatus = "ng" }
        elseif ($statusOpt -eq '3') { $newStatus = "t" }

        if ($newStatus -ne "") {
            $json = $null
            if (Test-Path $settingFile) {
                $rawJson = Get-Content $settingFile -Raw
                if (![string]::IsNullOrWhiteSpace($rawJson)) {
                    $json = $rawJson | ConvertFrom-Json
                }
            }
            if ($null -eq $json) { $json = New-Object PSObject }
            
            if ($json.PSObject.Properties.Name -contains $plId) {
                $json.$plId = $newStatus
            } else {
                $json | Add-Member -MemberType NoteProperty -Name $plId -Value $newStatus
            }
            
            $json | ConvertTo-Json -Depth 10 | Set-Content $settingFile -Encoding ASCII
            Write-Host "`nStatus for $plId changed to $newStatus ."
        } else {
            Write-Host "Invalid option."
        }
        Read-Host "Press Enter to return"
    } else {
        Write-Host "Invalid option."
        Read-Host "Press Enter to return"
    }
}
