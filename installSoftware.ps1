# ==========================================
# Software Installation Launcher
# ==========================================

# ------------------------------------------
# Configuration
# ------------------------------------------

param(
    [string]$UbuntuDistro = "Ubuntu"
)

$LinuxUsername = "linuxnerd"

$ErrorActionPreference = "Stop"

# ----------------!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!-----------------------------------
# Name of the software installation folder; update this line to switch what is being installed
# ----------------!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!-----------------------------------

$SoftwareName = "PaddlePaddle"

# ==========================================
# Locate Software Installer
# ==========================================

$SoftwareDirectory = Join-Path `
    $PSScriptRoot `
    "software\$SoftwareName"

$SoftwareScriptWindows = Join-Path `
    $SoftwareDirectory `
    "installSoftware.sh"


if (-not (Test-Path $SoftwareDirectory)) {

    Write-Host ""
    Write-Host "ERROR: Software directory was not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "Expected location:"
    Write-Host "$SoftwareDirectory"
    Write-Host ""

    exit 1
}


if (-not (Test-Path $SoftwareScriptWindows)) {

    Write-Host ""
    Write-Host "ERROR: installSoftware.sh was not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "Expected location:"
    Write-Host "$SoftwareScriptWindows"
    Write-Host ""

    exit 1
}


# ==========================================
# Convert Windows Path to WSL Path
# ==========================================

$SoftwareScriptLinux = wsl -d $UbuntuDistro -- `
    wslpath -a "$SoftwareScriptWindows"


if ($LASTEXITCODE -ne 0) {

    Write-Host ""
    Write-Host "ERROR: Could not determine WSL path." -ForegroundColor Red

    exit 1
}

$SoftwareScriptLinux = ($SoftwareScriptLinux | Out-String).Trim()

# ==========================================
# Display Information
# ==========================================

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "      Launching Software Installer" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "Software: $SoftwareName"
Write-Host "Installer: $SoftwareScriptWindows"
Write-Host ""


# ==========================================
# Run Bash Installer
# ==========================================

wsl -d $UbuntuDistro -u $LinuxUsername -- `
    bash "$SoftwareScriptLinux"


if ($LASTEXITCODE -ne 0) {

    Write-Host ""
    Write-Host "ERROR: Software installation failed." -ForegroundColor Red

    exit 1
}


# ==========================================
# Complete
# ==========================================

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "    Software Installation Successful" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
