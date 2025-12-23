# ==== PowerShell Profile Configuration ====================

# ==== Check for Minimum PowerShell Version ===============

if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Warning "PowerShell version 7 of higher required for this configuration"
    Write-Host ""
    Write-Host " - This profile is located at $($PROFILE)"
    Write-Host " - PowerShell 7 can be installed via https://aka.ms/install-powershell"
    Write-Host ""
    return
}

# ==== Prepare Environment =================================

$StartupLogs = @()
$LoadedTools = @()
$MissingTools = @()

$ConfigRoot = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME '.config' }
$PwshKitRoot = Join-Path $ConfigRoot 'pwshkit' 'pwshkit.psm1'

$PSStyle.FileInfo.Directory = "" # Disable Directory Highlights (PowerShell versions > 7.3)

# ==== Setup Tools Listing =================================

$Tools = @(
    [ordered]@{  Name = 'starship'; Repo = 'https://github.com/starship/starship' },
    [ordered]@{  Name = 'bat'; Repo = 'https://github.com/sharkdp/bat' },
    [ordered]@{  Name = 'fzf'; Repo = 'https://github.com/junegunn/fzf' },
    [ordered]@{  Name = 'zoxide'; Repo = 'https://github.com/ajeetdsouza/zoxide' },
    [ordered]@{  Name = 'git' ; Repo = 'https://github.com/git/git' },
    [ordered]@{  Name = 'fastfetch'; Repo = 'https://github.com/fastfetch-cli/fastfetch' },
    [ordered]@{  Name = 'kubectl'; Repo = 'https://github.com/kubernetes/kubernetes' }

) | ForEach-Object { [PSCustomObject]$_ }

foreach ($tool in $Tools) {
    if (-not (Get-Command $tool.Name -ErrorAction SilentlyContinue)) {
        $MissingTools += $tool
    }
    else {
        $LoadedTools += $tool
    }
}

if ($MissingTools.Count -gt 0) {
    $StartupLogs += "Missing tools: $($MissingTools.Name -join ', ')"
}

# === Load Pwshkit Utils & Plugins =========================

if (Test-Path $PwshKitRoot) {
    try { Import-Module $PwshKitRoot -ErrorAction Stop }
    catch { $StartupLogs += "Failed to load pwshkit: $($_.Exception.Message)" }
}
else {
    $StartupLogs += "Pwshkit not found at: $PwshKitRoot"
}

# ==== Load Tools ==========================================

if ('starship' -in $LoadedTools.Name) {
    $ENV:STARSHIP_CONFIG = Join-Path $ConfigRoot 'starship' 'starship.toml'
    try { Invoke-Expression (&starship init powershell) }
    catch { $StartupLogs += "Failed to initialize starship" }
}

if ('fastfetch' -in $LoadedTools.Name) {
    & fastfetch
}

if ('zoxide' -in $LoadedTools.Name) {
    try { Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) }) } 
    catch { $StartupLogs += "Failed to initialize zoxide" }
}

# ==== Load Environment Variables ==========================

$env:UV_LINK_MODE = 'copy'