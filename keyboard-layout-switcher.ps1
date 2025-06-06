# キーボードレイアウト切り替えPowerShellスクリプト
# 自動で管理者権限に昇格します

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("japanese", "english")]
    [string]$Layout,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("restart", "shutdown", "manual")]
    [string]$Action
)

# 管理者権限チェックと自動昇格
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Administrator privileges required. Re-running with administrator privileges..."
    
    # 現在のスクリプトパスを取得
    $scriptPath = $MyInvocation.MyCommand.Path
    
    # パラメータを保持して管理者権限で再実行
    $arguments = ""
    if ($Layout) {
        $arguments = "-Layout $Layout"
    }
    
    try {
        # Windows Terminalが利用可能かチェック
        $wtPath = Get-Command "wt.exe" -ErrorAction SilentlyContinue
        
        if ($wtPath) {
            # Windows Terminalで管理者権限実行
            $wtCommand = "powershell.exe -ExecutionPolicy Bypass -File `"$scriptPath`" $arguments"
            Start-Process "wt.exe" -ArgumentList "--title `"⌨️ Keyboard Layout Switcher (Admin)`" $wtCommand" -Verb RunAs
        } else {
            # 従来のPowerShellで管理者権限実行
            Start-Process PowerShell -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`" $arguments" -Verb RunAs
        }
        exit 0
    } catch {
        Write-Host ""
        Write-Host "Failed to run with administrator privileges." -ForegroundColor Red
        Write-Host "Please run manually from PowerShell with administrator privileges." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Press Enter to exit..." -ForegroundColor Gray
        $null = Read-Host
        exit 1
    }
}

# ヘッダー表示
Clear-Host
Write-Host ""
Write-Host "⌨️  " -NoNewline -ForegroundColor Cyan
Write-Host "Keyboard Layout Switcher " -NoNewline -ForegroundColor White
Write-Host "v1.0.0" -ForegroundColor Gray
Write-Host ""

# 現在のキーボードレイアウトを取得
Write-Host "Detecting current keyboard layout..." -ForegroundColor Gray

$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters"
try {
    $currentId = Get-ItemProperty -Path $registryPath -Name "OverrideKeyboardIdentifier" -ErrorAction SilentlyContinue | 
                 Select-Object -ExpandProperty "OverrideKeyboardIdentifier"
} catch {
    $currentId = $null
}

# 現在のレイアウトを判定
switch ($currentId) {
    "PCAT_106KEY" { 
        $currentLayout = "japanese"
        $currentDescription = "Japanese keyboard layout (JIS 106/109 keys)"
    }
    "PCAT_101KEY" { 
        $currentLayout = "english"
        $currentDescription = "US keyboard layout (ANSI 101/102 keys)"
    }
    default { 
        $currentLayout = "unknown"
        $currentDescription = "Not set or unknown"
    }
}

# 確認完了後、画面をクリアして最終表示
Clear-Host
Write-Host ""
Write-Host "⌨️  " -NoNewline -ForegroundColor Cyan
Write-Host "Keyboard Layout Switcher " -NoNewline -ForegroundColor White
Write-Host "v1.0.0" -ForegroundColor Gray
Write-Host ""

# 現在の設定を表示
Write-Host "Current: " -NoNewline -ForegroundColor White
Write-Host "$currentDescription" -ForegroundColor Cyan

# デバッグ: パラメータ確認
if ($Layout) {
    Write-Host "Target: " -NoNewline -ForegroundColor White
    Write-Host "$Layout layout" -ForegroundColor Yellow
}

Write-Host ""

# レイアウト選択（パラメータが指定されていない場合のみ）
if (-not $Layout) {
    Write-Host "Select layout:" -ForegroundColor White
    Write-Host "  [j] Japanese (JIS 106/109 keys)" -ForegroundColor Gray
    Write-Host "  [u] US (ANSI 101/102 keys)" -ForegroundColor Gray
    Write-Host "  [q] Quit" -ForegroundColor Gray
    Write-Host ""
    
    do {
        $choice = Read-Host "Choice"
        
        switch ($choice.ToLower()) {
            "j" { 
                $Layout = "japanese"
                break
            }
            "u" { 
                $Layout = "english"
                break
            }
            "q" { 
                Write-Host ""
                Write-Host "Goodbye!" -ForegroundColor White
                exit 0
            }
            default {
                Write-Host "Invalid option. Please choose j, u, or q." -ForegroundColor Red
            }
        }
    } while (-not $Layout)
}

Write-Host ""

# 同じレイアウトの場合はスキップ
if ($currentLayout -eq $Layout) {
    $layoutName = if ($Layout -eq "japanese") { "Japanese" } else { "US" }
    Write-Host ""
    Write-Host "Already using $layoutName layout - no changes needed" -ForegroundColor Green
    Write-Host ""
    Write-Host "Press Enter to exit..." -ForegroundColor Gray
    $null = Read-Host
    exit 0
}

# キーボードレイアウトを適用
Write-Host ""
try {
    switch ($Layout) {
        "japanese" {
            Write-Host "Switching to Japanese keyboard layout..." -ForegroundColor White
            Set-ItemProperty -Path $registryPath -Name "LayerDriver JPN" -Value "kbd106.dll" -Type String
            Set-ItemProperty -Path $registryPath -Name "OverrideKeyboardIdentifier" -Value "PCAT_106KEY" -Type String
            Set-ItemProperty -Path $registryPath -Name "OverrideKeyboardSubtype" -Value 2 -Type DWord
            Write-Host "Successfully configured Japanese layout" -ForegroundColor Green
        }
        "english" {
            Write-Host "Switching to US keyboard layout..." -ForegroundColor White
            Set-ItemProperty -Path $registryPath -Name "LayerDriver JPN" -Value "kbd101.dll" -Type String
            Set-ItemProperty -Path $registryPath -Name "OverrideKeyboardIdentifier" -Value "PCAT_101KEY" -Type String
            Set-ItemProperty -Path $registryPath -Name "OverrideKeyboardSubtype" -Value 0 -Type DWord
            Write-Host "Successfully configured US layout" -ForegroundColor Green
        }
    }
} catch {
    Write-Host ""
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Press Enter to exit..." -ForegroundColor Gray
    $null = Read-Host
    exit 1
}

# 再起動・シャットダウン選択
Write-Host ""
Write-Host "Restart required to apply changes" -ForegroundColor White
Write-Host ""

# アクションパラメータが指定されている場合は自動実行
if ($Action) {
    switch ($Action.ToLower()) {
        "restart" {
            Write-Host "Restarting in 3 seconds..." -ForegroundColor White
            for ($i = 3; $i -gt 0; $i--) {
                Write-Host "  $i..." -ForegroundColor Gray
                Start-Sleep -Seconds 1
            }
            Restart-Computer -Force
            exit 0
        }
        "shutdown" {
            Write-Host "Shutting down in 3 seconds..." -ForegroundColor White
            for ($i = 3; $i -gt 0; $i--) {
                Write-Host "  $i..." -ForegroundColor Gray
                Start-Sleep -Seconds 1
            }
            Stop-Computer -Force
            exit 0
        }
        "manual" {
            Write-Host "Configuration saved successfully!" -ForegroundColor Green
            Write-Host "Remember to restart your PC to apply the changes" -ForegroundColor Yellow
            exit 0
        }
    }
} else {
    # 対話モード: ユーザーに選択させる
    Write-Host "  [r] Restart now" -ForegroundColor Gray
    Write-Host "  [s] Shutdown now" -ForegroundColor Gray
    Write-Host "  [n] Later manually" -ForegroundColor Gray
    Write-Host ""

    do {
        $choice = Read-Host "Choice"
        
        switch ($choice.ToLower()) {
            "r" {
                Write-Host ""
                Write-Host "Restarting in 3 seconds..." -ForegroundColor White
                for ($i = 3; $i -gt 0; $i--) {
                    Write-Host "  $i..." -ForegroundColor Gray
                    Start-Sleep -Seconds 1
                }
                Restart-Computer -Force
                exit 0
            }
            "s" {
                Write-Host ""
                Write-Host "Shutting down in 3 seconds..." -ForegroundColor White
                for ($i = 3; $i -gt 0; $i--) {
                    Write-Host "  $i..." -ForegroundColor Gray
                    Start-Sleep -Seconds 1
                }
                Stop-Computer -Force
                exit 0
            }
            "n" {
                Write-Host ""
                Write-Host "Configuration saved successfully!" -ForegroundColor Green
                Write-Host "Remember to restart your PC to apply the changes" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "Press Enter to exit..." -ForegroundColor Gray
                $null = Read-Host
                exit 0
            }
            default {
                Write-Host "Invalid option. Please choose r, s, or n." -ForegroundColor Red
            }
        }
    } while ($choice.ToLower() -notin @("r", "s", "n"))
}