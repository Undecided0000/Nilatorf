$settingFile = Join-Path $PSScriptRoot "setting.json"

function Show-Menu {
    Clear-Host
    Write-Host "========================================="
    Write-Host " Nilatorf STN Access Admin Tool"
    Write-Host "========================================="
    Write-Host ""
    Write-Host "[Current Settings]"
    if (Test-Path $settingFile) {
        Get-Content $settingFile | Write-Host
    } else {
        Write-Host "setting.json not found. Creating a new one."
        "{`n}`n" | Set-Content $settingFile -Encoding ASCII
    }
    Write-Host ""
    Write-Host "========================================="
    Write-Host "[1] Change PL status (e.g., 1,2,5 or 12,13)"
    Write-Host "[2] Change ALL PLs status"
    Write-Host "[9] Pull, Save and Push to GitHub"
    Write-Host "[0] Exit"
    Write-Host "========================================="
    $option = Read-Host "Select menu (0-2, 9)"
    return $option
}

while ($true) {
    $option = Show-Menu

    if ($option -eq '0') {
        break
    }
    elseif ($option -eq '9') {
        Write-Host "`nPulling latest changes from GitHub..."
        Set-Location $PSScriptRoot
        git pull --rebase
        Write-Host "`nPushing changes to GitHub..."
        git add "setting.json"
        git commit -m "Update access settings from admin tool"
        git push
        Write-Host "`nSync completed."
        Read-Host "Press Enter to return"
    }
    elseif ($option -eq '1' -or $option -eq '2') {
        $targetPls = @()
        
        $json = $null
        if (Test-Path $settingFile) {
            $rawJson = Get-Content $settingFile -Raw
            if (![string]::IsNullOrWhiteSpace($rawJson)) {
                $json = $rawJson | ConvertFrom-Json
            }
        }
        if ($null -eq $json) { $json = New-Object PSObject }
        
        if ($option -eq '2') {
            # All PLs
            $targetPls = $json.PSObject.Properties.Name
            if ($targetPls.Count -eq 0) {
                Write-Host "`nNo PLs found in setting.json."
                Read-Host "Press Enter to return"
                continue
            }
            Write-Host "`nTarget: ALL PLs ($($targetPls -join ', '))"
        } else {
            # Specific PLs
            Write-Host "`nEnter PL numbers to change (comma-separated, e.g., 1,2,12):"
            $inputPls = Read-Host "PL numbers"
            
            if ([string]::IsNullOrWhiteSpace($inputPls)) {
                continue
            }
            
            $plNumbers = $inputPls -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }
            if ($plNumbers.Count -eq 0) {
                Write-Host "`nInvalid input. Please enter numbers."
                Read-Host "Press Enter to return"
                continue
            }
            
            foreach ($num in $plNumbers) {
                $targetPls += "PL$num"
            }
            Write-Host "`nTarget: $($targetPls -join ', ')"
        }

        Write-Host "`nSelect new status:"
        Write-Host "[1] ok (Allow access)"
        Write-Host "[2] ng (Show Error / Freeze)"
        Write-Host "[3] t  (Redirect to Booth)"
        $statusOpt = Read-Host "Select (1-3)"

        $newStatus = ""
        if ($statusOpt -eq '1') { $newStatus = "ok" }
        elseif ($statusOpt -eq '2') { $newStatus = "ng" }
        elseif ($statusOpt -eq '3') { $newStatus = "t" }

        if ($newStatus -ne "") {
            foreach ($pl in $targetPls) {
                if ($json.PSObject.Properties.Name -contains $pl) {
                    $json.$pl = $newStatus
                } else {
                    $json | Add-Member -MemberType NoteProperty -Name $pl -Value $newStatus
                }
            }
            
            $json | ConvertTo-Json -Depth 10 | Set-Content $settingFile -Encoding ASCII
            Write-Host "`nStatus successfully updated."
        } else {
            Write-Host "`nInvalid option."
        }
        Read-Host "Press Enter to return"
    } else {
        Write-Host "`nInvalid option."
        Read-Host "Press Enter to return"
    }
}
