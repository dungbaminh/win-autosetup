# ==============================================================================
# WINDOWS AUTOMATED SETUP V28 - DARK MODE & BLOATWARE REMOVER
# ==============================================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "VUI LONG CHAY POWERSHELL VOI QUYEN ADMINISTRATOR!"
    break
}

$ConfirmPreference = 'None'
Set-ExecutionPolicy Bypass -Scope Process -Force

$stageFile = "C:\setup_stage.txt"
$localScript = "C:\win_setup_temp.ps1"
$remoteUrl = "https://raw.githubusercontent.com/dungbaminh/win_autosetup/main/setup.ps1"

if ($MyInvocation.MyCommand.CommandType -ne "ExternalScript") {
    try {
        $scriptContent = (New-Object System.Net.WebClient).DownloadString($remoteUrl)
        $scriptContent | Out-File $localScript -Encoding UTF8
        $scriptPath = $localScript
    } catch {
        Write-Error "Loi ket noi GitHub. Hay chac chan Repo dang o PUBLIC!"
        break
    }
} else { $scriptPath = $MyInvocation.MyCommand.Path }

function Set-Autostart {
    $action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    Register-ScheduledTask -TaskName "WindowsAutoSetup" -Action $action -Trigger $trigger -Principal $principal -Force
}

function Remove-Autostart {
    Unregister-ScheduledTask -TaskName "WindowsAutoSetup" -Confirm:$false -ErrorAction SilentlyContinue
    if (Test-Path $stageFile) { Remove-Item $stageFile -Force }
    if (Test-Path $localScript) { Remove-Item $localScript -Force }
}

$currentStage = if (Test-Path $stageFile) { Get-Content $stageFile } else { "1" }

# --- STAGE 1: ACTIVE WINDOWS ---
if ($currentStage -eq "1") {
    Write-Host "`n[STAGE 1] DANG KICH HOAT WINDOWS..." -ForegroundColor Cyan
    irm https://get.massgrave.dev | iex /hwid
    Set-Autostart
    "2" | Out-File $stageFile
    Start-Sleep -Seconds 5
    Restart-Computer -Force
    break
}

# --- STAGE 2: WINDOWS UPDATE ---
if ($currentStage -eq "2") {
    Write-Host "`n[STAGE 2] DANG CAP NHAT WINDOWS..." -ForegroundColor Cyan
    if (-not (Get-Module -ListAvailable PSWindowsUpdate)) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
        Install-Module PSWindowsUpdate -Force -Confirm:$false -SkipPublisherCheck
    }
    "3" | Out-File $stageFile
    Get-WindowsUpdate -AcceptAll -Install -AutoReboot:$true -Quiet
    Restart-Computer -Force
    break
}

# --- STAGE 3: DRIVER ---
if ($currentStage -eq "3") {
    Write-Host "`n[STAGE 3] DANG CAI DAT DRIVER..." -ForegroundColor Cyan
    $cpuName = (Get-CimInstance Win32_Processor).Name
    $gpuObjs = Get-CimInstance Win32_VideoController
    if ($cpuName -like "*Intel*") { winget install --id Intel.ChipsetDeviceSoftware --silent --non-interactive --accept-package-agreements }
    elseif ($cpuName -like "*AMD*") { winget install --id AMD.ChipsetDrivers --silent --non-interactive --accept-package-agreements }
    foreach ($gpu in $gpuObjs) {
        $vID = $gpu.PNPDeviceID
        if ($vID -match "VEN_10DE") { winget install --id Nvidia.GeForceDriver.GameReady --silent --non-interactive --accept-package-agreements }
        elseif ($vID -match "VEN_1002") { winget install --id AMD.Software.Adrenalin --silent --non-interactive --accept-package-agreements }
        elseif ($vID -match "VEN_8086") { winget install --id Intel.GraphicDriver --silent --non-interactive --accept-package-agreements }
    }
    "4" | Out-File $stageFile
    Restart-Computer -Force
    break
}

# --- STAGE 4: OFFICE, APPS, TWEAKS & DARK MODE ---
if ($currentStage -eq "4") {
    Write-Host "`n[STAGE 4] TOI UU CUOI CUNG & KICH HOAT DARK MODE..." -ForegroundColor Cyan
    
    # 1. Kích hoạt Dark Mode (System & Apps)
    Write-Host "Dang thiet lap giao dien mau den (Dark Theme)..." -ForegroundColor Yellow
    $PersonalizePath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    Set-ItemProperty -Path $PersonalizePath -Name "AppsUseLightTheme" -Value 0
    Set-ItemProperty -Path $PersonalizePath -Name "SystemUsesLightTheme" -Value 0

    # 2. Gỡ bỏ App rác (Bloatware) - Giữ lại News, Weather, FeedbackHub
    $bloatware = @("*Disney*", "*Spotify*", "*TikTok*", "*Netflix*", "*ZuneVideo*", "*ZuneMusic*", "*Skype*", "*OfficeHub*", "*Bing*", "*Maps*")
    foreach ($app in $bloatware) { Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue }

    # 3. Classic Context Menu
    $registryPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
    if (!(Test-Path $registryPath)) { New-Item -Path $registryPath -Force | Out-Null }
    Set-ItemProperty -Path $registryPath -Name "(Default)" -Value ""

    # 4. Office 2024 Slim & Active
    irm https://get.massgrave.dev | iex /o-ltsc2024 /apps:word,excel,powerpoint,onedrive /s
    irm https://get.massgrave.dev | iex /ohook

    # 5. Cài đặt Apps
    $apps = @("Google.Chrome", "PhamKimLong.UniKey", "RARLab.WinRAR", "7zip.7zip", "Zalo.Zalo")
    foreach ($a in $apps) { winget install --id $a --silent --non-interactive --accept-package-agreements --accept-source-agreements }

    # 6. Tối ưu Paging File
    $totalRam = [Math]::Round((Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum / 1GB)
    $minP = if ($totalRam -lt 16) { $totalRam * 1536 } else { 4096 }
    $maxP = if ($totalRam -lt 16) { $totalRam * 3072 } else { 8192 }
    (Get-CimInstance Win32_ComputerSystem) | Set-CimInstance -Property @{AutomaticManagedPagefile = $False}
    New-CimInstance -ClassName Win32_PageFileSetting -Property @{Name="C:\pagefile.sys"; InitialSize=[uint32]$minP; MaximumSize=[uint32]$maxP} -ErrorAction SilentlyContinue

    # 7. Visual C++ & Chris Titus Tweaks
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/abbodi1406/vcredist/master/vcredist_silent.ps1'))
    irm https://christitus.com/win | iex

    # Restart Explorer để áp dụng Theme & Menu
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue

    Remove-Autostart
    Write-Host "`n=== TAT CA DA HOAN THANH! DARK MODE DA DUOC KICH HOAT. ===`n" -ForegroundColor Green
    Start-Sleep -Seconds 5
    Restart-Computer -Force
}
