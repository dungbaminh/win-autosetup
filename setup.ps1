# ==============================================================================
# WINDOWS AUTOMATED SETUP V25 - OFFICIAL REPO: dungbaminh/win_autosetup
# ==============================================================================

# 1. Kiểm tra quyền Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "VUI LONG CHAY POWERSHELL VOI QUYEN ADMINISTRATOR!"
    break
}

$ConfirmPreference = 'None'
Set-ExecutionPolicy Bypass -Scope Process -Force

# Đường dẫn quản lý tiến trình
$stageFile = "C:\setup_stage.txt"
$localScript = "C:\win_setup_temp.ps1"
# ĐÃ CAP NHAT LINK THEO YEU CAU:
$remoteUrl = "https://raw.githubusercontent.com/dungbaminh/win_autosetup/main/setup.ps1"

# Tải bản sao tạm thời để duy trì sau khi Reboot
if ($MyInvocation.MyCommand.CommandType -ne "ExternalScript") {
    try {
        $scriptContent = (New-Object System.Net.WebClient).DownloadString($remoteUrl)
        $scriptContent | Out-File $localScript -Encoding UTF8
        $scriptPath = $localScript
    } catch {
        Write-Error "Khong the ket noi den GitHub. Vui long kiem tra Internet."
        break
    }
} else {
    $scriptPath = $MyInvocation.MyCommand.Path
}

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

# --- STAGE 1: KÍCH HOẠT WINDOWS (MAS) ---
if ($currentStage -eq "1") {
    Write-Host "`n[STAGE 1] DANG KICH HOAT WINDOWS..." -ForegroundColor Cyan
    irm https://get.massgrave.dev | iex /hwid
    Set-Autostart
    "2" | Out-File $stageFile
    Start-Sleep -Seconds 5
    Restart-Computer -Force
    break
}

# --- STAGE 2: CẬP NHẬT WINDOWS ---
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

# --- STAGE 3: DRIVER (VENDOR ID) ---
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

# --- STAGE 4: OFFICE 2024, APPS & TWEAKS ---
if ($currentStage -eq "4") {
    Write-Host "`n[STAGE 4] TOI UU HE THONG & CAI DAT PHAN MEM..." -ForegroundColor Cyan
    
    # 1. Classic Context Menu (Win 11 -> Win 10 style)
    $registryPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
    if (!(Test-Path $registryPath)) { New-Item -Path $registryPath -Force | Out-Null }
    Set-ItemProperty -Path $registryPath -Name "(Default)" -Value ""

    # 2. Office 2024 Slim & Active (W, E, P, O)
    irm https://get.massgrave.dev | iex /o-ltsc2024 /apps:word,excel,powerpoint,onedrive /s
    irm https://get.massgrave.dev | iex /ohook

    # 3. Cài đặt Apps (Chrome, Unikey, WinRAR, 7zip, Zalo)
    $apps = @("Google.Chrome", "PhamKimLong.UniKey", "RARLab.WinRAR", "7zip.7zip", "Zalo.Zalo")
    foreach ($a in $apps) { winget install --id $a --silent --non-interactive --accept-package-agreements --accept-source-agreements }

    # 4. Tối ưu Visual & Paging File
    $totalRam = [Math]::Round((Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum / 1GB)
    $minP = if ($totalRam -lt 16) { $totalRam * 1536 } else { 4096 }
    $maxP = if ($totalRam -lt 16) { $totalRam * 3072 } else { 8192 }
    (Get-CimInstance Win32_ComputerSystem) | Set-CimInstance -Property @{AutomaticManagedPagefile = $False}
    New-CimInstance -ClassName Win32_PageFileSetting -Property @{Name="C:\pagefile.sys"; InitialSize=[uint32]$minP; MaximumSize=[uint32]$maxP} -ErrorAction SilentlyContinue

    # 5. Visual C++ & Chris Titus Tweaks
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/abbodi1406/vcredist/master/vcredist_silent.ps1'))
    irm https://christitus.com/win | iex

    # Dọn dẹp cuối cùng
    Remove-Autostart
    Write-Host "`n=== HOAN THANH! REBOOT LAN CUOI DE AP DUNG MOI THAY DOI. ===`n" -ForegroundColor Green
    Restart-Computer -Force
}
