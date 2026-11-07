Clear-Host
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "  Finnish Custom Multilingual Extension Installer  " -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

# 1. Check, Install, or Update AutoHotkey v2 via User Scope
Write-Host "`n[+] Checking for AutoHotkey v2..." -ForegroundColor Cyan

$ahkCheck = winget list --id AutoHotkey.AutoHotkey 2>$null
if ($ahkCheck -match "AutoHotkey\.AutoHotkey") {
    Write-Host "    AutoHotkey found. Ensuring it is up to date..." -ForegroundColor Green
    winget upgrade --id AutoHotkey.AutoHotkey --scope user --silent --accept-source-agreements --accept-package-agreements > $null
} else {
    Write-Host "    AutoHotkey v2 not detected. Installing via WinGet (User Scope)..." -ForegroundColor Yellow
    winget install --id AutoHotkey.AutoHotkey --scope user --silent --accept-source-agreements --accept-package-agreements
}

# Dynamically refresh path variables and locate the executable binary path
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
$AhkExe = Join-Path $env:LOCALAPPDATA "Programs\AutoHotkey\v2\AutoHotkey64.exe"
if (-not (Test-Path $AhkExe)) { $AhkExe = "AutoHotkey64.exe" } # Fallback to path if custom structured

# 2. Download the AHK script to the user's Documents folder
$URL = "https://github.com"
$DestinationFolder = Join-Path $env:USERPROFILE "Documents\Finnish-Multilingual-Extension"
if (-not (Test-Path $DestinationFolder)) { New-Item -ItemType Directory -Path $DestinationFolder | Out-Null }
$DestinationFile = Join-Path $DestinationFolder "Finnish-Multilingual-Extension_Custom.ahk"

Write-Host "`n[+] Downloading layout script..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $URL -OutFile $DestinationFile
Write-Host "    Saved to: $DestinationFile" -ForegroundColor Green

# 3. Handle Windows Startup preference (User space, no admin needed)
$StartupFolder = [System.IO.Path]::Combine($env:APPDATA, "Microsoft\Windows\Start Menu\Programs\Startup")
$ShortcutPath = Join-Path $StartupFolder "Finnish-Multilingual-Extension_Custom.lnk"

Write-Host "`n[?] Do you want this extension to start automatically when Windows boots up?" -ForegroundColor Yellow
$Choice = Read-Host "[Y]es / [N]o"

if ($Choice -eq "Y" -or $Choice -eq "y") {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $AhkExe
    $Shortcut.Arguments = "`"$DestinationFile`""
    $Shortcut.WorkingDirectory = $DestinationFolder
    $Shortcut.Save()
    Write-Host "    Added to Windows Startup successfully!" -ForegroundColor Green
} else {
    if (Test-Path $ShortcutPath) { Remove-Item $ShortcutPath -Force }
    
    Write-Host "`n[INFO] Auto-startup skipped." -ForegroundColor Magenta
    Write-Host "You can set it up manually later if you change your mind:" -ForegroundColor White
    Write-Host "1. Press Win + R, type 'shell:startup' and hit Enter."
    Write-Host "2. Create a shortcut in that folder pointing directly to:"
    Write-Host "   $DestinationFile" -ForegroundColor Gray
}

# 4. Launch the AutoHotkey script right now safely
Write-Host "`n[+] Activating layout extension..." -ForegroundColor Cyan
Start-Process -FilePath $AhkExe -ArgumentList "`"$DestinationFile`""

# 5. Final Friendly User Guide
Write-Host "`n==========================================================================" -ForegroundColor Green
Write-Host "Success! The Finnish Custom Multilingual Extension is now running." -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host "• To start it in the future, just double-click the .ahk file in Documents." -ForegroundColor White
Write-Host "• To close it, go to your system tray (bottom-right icons), right-click" -ForegroundColor White
Write-Host "  the green AutoHotkey 'H' icon, and click 'Exit'." -ForegroundColor White
Write-Host "==========================================================================" -ForegroundColor Green
