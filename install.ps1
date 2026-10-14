# ==========================================
# WSL + Ubuntu Installer
# ==========================================

$ErrorActionPreference = "Stop"

# ==========================================
# Configuration
# ==========================================

$LinuxUsername = "linuxnerd"
$LinuxPassword = "linuxnerd"
$UbuntuDistro = "Ubuntu"

$MinicondaPath = "/home/$LinuxUsername/miniconda3"





Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "       WSL + Ubuntu Installation" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------
# Check Administrator privileges
# ------------------------------------------

$currentUser = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)

$isAdmin = $currentUser.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $isAdmin) {

    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow

    Start-Process powershell.exe `
        -ArgumentList "-noExit -ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
        -Verb RunAs

    exit
}

Write-Host "[1/6] Administrator privileges: OK" -ForegroundColor Green


# ------------------------------------------
# Check WSL
# ------------------------------------------

Write-Host ""
Write-Host "[2/6] Checking WSL..."

$wslInstalled = $true

try {
    wsl --status | Out-Null
}
catch {
    $wslInstalled = $false
}

if ($wslInstalled) {

    Write-Host "      WSL is already installed." -ForegroundColor Green

}
else {

    Write-Host "      WSL is not installed." -ForegroundColor Yellow
    Write-Host "      Installing WSL..."

    wsl --install --no-launch

    Write-Host ""
    Write-Host "WSL installation has been started." -ForegroundColor Green
    Write-Host ""
    Write-Host "A Windows restart may be required."
    Write-Host "After restarting, run install.bat again."
    Write-Host ""

    exit
}


# ------------------------------------------
# Configure WSL 2
# ------------------------------------------

Write-Host ""
Write-Host "[3/6] Configuring WSL 2..."

wsl --set-default-version 2 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host "      ERROR: Could not configure WSL 2." -ForegroundColor Red
    exit 1
}

Write-Host "      WSL 2 configured successfully." -ForegroundColor Green


# ------------------------------------------
# Check for Ubuntu
# ------------------------------------------

Write-Host ""
Write-Host "[4/6] Checking for Ubuntu..."

$wslList = wsl --list --quiet 2>$null

# Convert output to clean strings
$distros = @(
    $wslList |
    ForEach-Object {
        $_ -replace "`0", ""
        $_.Trim()
    } |
    Where-Object {
        $_ -ne ""
    }
)

$ubuntu = $distros | Where-Object {
    $_ -like "Ubuntu*"
}

if ($ubuntu) {

    Write-Host "      Ubuntu is already installed:" -ForegroundColor Green

    foreach ($distro in $ubuntu) {
        Write-Host "      $distro" -ForegroundColor Green
    }

}
else {

    Write-Host "      Ubuntu is not installed." -ForegroundColor Yellow
    Write-Host "      Installing Ubuntu..."
    Write-Host ""

    wsl --install -d Ubuntu --no-launch

    if ($LASTEXITCODE -ne 0) {

        Write-Host ""
        Write-Host "ERROR: Ubuntu installation failed." -ForegroundColor Red
        Write-Host "WSL exit code: $LASTEXITCODE" -ForegroundColor Red
        Write-Host ""

        exit 1
    }

    Write-Host ""
    Write-Host "Ubuntu installation completed." -ForegroundColor Green
}


# ------------------------------------------
# Final status
# ------------------------------------------

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "          Installation Status" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

wsl --list --verbose

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "             Step 1 Complete" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""

Write-Host "WSL 2 and Ubuntu are ready."
Write-Host ""
Write-Host "The next step will configure the Ubuntu"
Write-Host "Linux user and prepare the environment."
Write-Host ""





# ------------------------------------------
# Configure Linux user
# ------------------------------------------

Write-Host ""
Write-Host "[5/6] Configuring Ubuntu user..."

# Check whether the user already exists
wsl -d $UbuntuDistro -u root -- `
    bash -c "getent passwd '$LinuxUsername' >/dev/null 2>&1"

$userExists = ($LASTEXITCODE -eq 0)

if ($userExists) {

    Write-Host "      User '$LinuxUsername' already exists." -ForegroundColor Green

}
else {

    Write-Host "      Creating user '$LinuxUsername'..."

    wsl -d $UbuntuDistro -u root -- `
        useradd -m -s /bin/bash $LinuxUsername

    if ($LASTEXITCODE -ne 0) {
        Write-Host "      ERROR: Failed to create Linux user." -ForegroundColor Red
        exit 1
    }

    Write-Host "      User created." -ForegroundColor Green

    # Set password
    Write-Host "      Configuring password..."

    $escapedPassword = $LinuxPassword.Replace("'", "'\''")

    wsl -d $UbuntuDistro -u root -- `
        bash -c "echo '$LinuxUsername`:$escapedPassword' | chpasswd"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "      ERROR: Failed to set Linux password." -ForegroundColor Red
        exit 1
    }

    # Add user to sudo group
    Write-Host "      Configuring sudo privileges..."

    wsl -d $UbuntuDistro -u root -- `
        usermod -aG sudo $LinuxUsername

    if ($LASTEXITCODE -ne 0) {
        Write-Host "      ERROR: Failed to configure sudo." -ForegroundColor Red
        exit 1
    }
}

# ==========================================
# Configure WSL default user if necessary
# ==========================================

Write-Host "      Checking default WSL user..."

$currentDefaultUser = wsl -d $UbuntuDistro -u root -- `
    bash -c "grep -E '^[[:space:]]*default[[:space:]]*=' /etc/wsl.conf 2>/dev/null | tail -n 1 | cut -d '=' -f 2 | tr -d '[:space:]'"

if ($LASTEXITCODE -ne 0) {
    Write-Host "      ERROR: Failed to check the default WSL user." -ForegroundColor Red
    exit 1
}

$currentDefaultUser = ($currentDefaultUser | Out-String).Trim()

if ($currentDefaultUser -eq $LinuxUsername) {

    Write-Host "      '$LinuxUsername' is already the default WSL user." -ForegroundColor Green

}
else {

    Write-Host "      Current default user: '$currentDefaultUser'"
    Write-Host "      Setting default user to '$LinuxUsername'..."


    $wslConfig = @"
[user]
default=$LinuxUsername
"@

    # Write configuration file using root
    $encodedConfig = [Convert]::ToBase64String(
        [System.Text.Encoding]::UTF8.GetBytes($wslConfig)
    )

    wsl -d $UbuntuDistro -u root -- `
        bash -c "echo '$encodedConfig' | base64 -d > /etc/wsl.conf"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "      ERROR: Failed to configure /etc/wsl.conf." -ForegroundColor Red
        exit 1
    }

    Write-Host "      Linux user configured successfully." -ForegroundColor Green

}


Write-Host ""
Write-Host "Restarting Ubuntu to apply configuration..."

wsl --terminate $UbuntuDistro

Start-Sleep -Seconds 2




Write-Host ""
Write-Host "Verifying Linux user..."

$whoami = wsl -d $UbuntuDistro -- bash -c "whoami"

if ($whoami.Trim() -ne $LinuxUsername) {

    Write-Host "ERROR: Default Linux user is not configured correctly." -ForegroundColor Red
    Write-Host "Expected: $LinuxUsername"
    Write-Host "Found: $whoami"

    exit 1
}

Write-Host "      Default user: $whoami" -ForegroundColor Green


# ------------------------------------------
# verify user config
# ------------------------------------------


Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "          Installation Status" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

wsl --list --verbose

Write-Host ""
Write-Host "Linux user: $LinuxUsername"
Write-Host "Ubuntu:     $UbuntuDistro"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "             Step 2 Complete" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""

Write-Host "WSL 2 and Ubuntu are configured."
Write-Host "The default Linux user is: $LinuxUsername"
Write-Host ""




# ------------------------------------------
# Install Miniconda
# ------------------------------------------

Write-Host ""
Write-Host "[6/6] Checking Miniconda..."

$MinicondaPath = "/home/$LinuxUsername/miniconda3"

wsl -d $UbuntuDistro -u $LinuxUsername -- `
    bash -c "test -x '$MinicondaPath/bin/conda'"

$condaInstalled = ($LASTEXITCODE -eq 0)

if ($condaInstalled) {

    Write-Host "      Miniconda is already installed." -ForegroundColor Green

}
else {

    Write-Host "      Miniconda is not installed." -ForegroundColor Yellow
    Write-Host "      Installing Miniconda..."

    wsl -d $UbuntuDistro -u $LinuxUsername -- `
        bash -c "cd /tmp && curl -fsSLO https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "      ERROR: Failed to download Miniconda." -ForegroundColor Red
        exit 1
    }

    wsl -d $UbuntuDistro -u $LinuxUsername -- `
        bash -c "bash /tmp/Miniconda3-latest-Linux-x86_64.sh -b -p '$MinicondaPath'"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "      ERROR: Miniconda installation failed." -ForegroundColor Red
        exit 1
    }

    wsl -d $UbuntuDistro -u $LinuxUsername -- `
        bash -c "rm -f /tmp/Miniconda3-latest-Linux-x86_64.sh"

    Write-Host "      Miniconda installed successfully." -ForegroundColor Green
}


# ------------------------------------------
# verify Miniconda installation
# ------------------------------------------


Write-Host ""
Write-Host "      Verifying Conda..."

$condaVersion = wsl -d $UbuntuDistro -u $LinuxUsername -- `
    bash -c "'$MinicondaPath/bin/conda' --version"

if ($LASTEXITCODE -ne 0) {

    Write-Host "      ERROR: Conda verification failed." -ForegroundColor Red
    exit 1
}

Write-Host "      $condaVersion" -ForegroundColor Green

Write-Host ""
Write-Host "      Checking Miniconda location..."

$condaLocation = wsl -d $UbuntuDistro -u $LinuxUsername -- `
    bash -c "readlink -f '$MinicondaPath'"

Write-Host "      $condaLocation"




# ------------------------------------------
# Initialize Conda for Bash
# ------------------------------------------

if ($condaInstalled) {
    Write-Host ""
    Write-Host "Initializing Conda for Bash..."

    wsl -d $UbuntuDistro -u $LinuxUsername -- `
        bash -c "$MinicondaPath/bin/conda init bash"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to initialize Conda for Bash." -ForegroundColor Red
        exit 1
    }

    Write-Host "Conda initialized successfully."
}

# ------------------------------------------
# Begin Conda env creation and software installation
# ------------------------------------------

Write-Host ""
Write-Host "Launching software installer..." -ForegroundColor Cyan
Write-Host ""

& "$PSScriptRoot\installSoftware.ps1"

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Software installation failed. Contact bravosalgado@oakland.edu or ggraessle@oakland.edu for assistance" -ForegroundColor Red
    exit 1
}
